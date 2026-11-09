"""SaftUI's test runner. tests/run starts it with a Python that has lupa.

Each *_test.lua file runs in its own fresh Lua 5.1 state (lupa.lua51), so files
can't leak state into each other. In each state, tests/lib/harness.lua defines
the test API, builds the stubbed WoW world and the core shell, loads the file
and runs its cases (see .agents/testing.md). This file finds the test files,
prints the results and sets the exit status:

  0  every file loaded, ran at least one check, and had no failures
  1  test failures: a file failed to load, ran no checks, or had a failing check
  2  bad arguments (a path that doesn't exist, a folder with no tests)
  70 the runner itself crashed (a Python exception; the traceback is on stderr)

Exit 0 means all passed and every other status is a failure. 1 and 70 are kept
apart so `tests/run --self-check` can tell a caught failure from a runner crash
(Python's own exit status for an uncaught exception is also 1).
"""

import argparse
import os
import sys

from lupa import lua51

TESTS_DIR = os.path.dirname(os.path.abspath(__file__))
REPO_ROOT = os.path.dirname(TESTS_DIR)
HARNESS = os.path.join(TESTS_DIR, 'lib', 'harness.lua')
TEST_SUFFIX = '_test.lua'
EXIT_FAILED = 1
EXIT_CRASHED = 70


class UsageError(Exception):
    pass


def find_test_files(folder):
    """Every *_test.lua under folder, sorted. Hidden folders (tests/.venv) are skipped."""
    found = []
    for dirpath, dirnames, filenames in os.walk(folder):
        dirnames[:] = sorted(d for d in dirnames if not d.startswith('.'))
        found.extend(os.path.join(dirpath, name) for name in sorted(filenames) if name.endswith(TEST_SUFFIX))
    return found


def collect(args):
    """The test files to run: every one under tests/, or the files and folders given."""
    files = []
    for arg in args or [TESTS_DIR]:
        path = os.path.abspath(arg)
        if os.path.isdir(path):
            found = find_test_files(path)
            if not found:
                raise UsageError(f'no *{TEST_SUFFIX} files in {arg}')
            files.extend(found)
        elif os.path.isfile(path):
            files.append(path)
        else:
            raise UsageError(f'no such file or folder: {arg}')
    return list(dict.fromkeys(files))  # a file named twice runs once


def shown_path(path):
    """A path as the report shows it: from the repo root when it's in the repo."""
    relative = os.path.relpath(path, REPO_ROOT)
    return path if relative.startswith('..') else relative


def lua_list(table):
    """A Lua array as a Python list (lupa tables are 1-based)."""
    return [table[i] for i in range(1, len(table) + 1)] if table is not None else []


def run_file(path):
    """Runs one test file in a fresh Lua state and returns the harness's result table."""
    lua = lua51.LuaRuntime(unpack_returned_tuples=True, register_eval=False, register_builtins=False)
    lua.globals().REPO_ROOT = REPO_ROOT
    lua.globals().TESTS_DIR = TESTS_DIR
    with open(HARNESS, encoding='utf-8') as f:
        source = f.read()
    compile_chunk = lua.eval('function(source, name) return assert(loadstring(source, name)) end')
    harness_run = compile_chunk(source, '@tests/lib/harness.lua')()
    return harness_run(path, shown_path(path))


def print_lines(lines, indent):
    for text in lines:
        for line in str(text).splitlines() or ['']:
            print(indent + line)


def count(n, noun):
    return f'{n} {noun}' if n == 1 else f'{n} {noun}s'


def report(path, verbose):
    """Runs a file, prints its result, and returns (passed, checks, failures).

    A failing file shows its problems, its failing cases and what they printed.
    verbose shows every case and all output.
    """
    try:
        result = run_file(path)
    except Exception as error:  # a bug in the harness itself, not in the test
        print(f'FAIL  {shown_path(path)}')
        print_lines([f'harness error: {error}'], '      ')
        return False, 0, 1

    cases = lua_list(result.cases)
    passed = bool(result.ok)
    summary = f'{count(len(cases), "case")}, {count(result.checks, "check")}'
    if result.failures:
        summary += f', {result.failures} failed'
    print(f'{"ok  " if passed else "FAIL"}  {result.path}  ({summary})')

    print_lines(lua_list(result.problems), '      ')
    output = lua_list(result.output)
    if output and (not passed or verbose):
        print_lines(['output while loading:'] + output, '      ')
    for case in cases:
        if case.ok and not verbose:
            continue
        print(f'      {"ok  " if case.ok else "FAIL"}  {case.name}  ({count(case.checks, "check")})')
        print_lines(lua_list(case.problems), '            ')
        output = lua_list(case.output)
        if output:
            print_lines(['output:'] + output, '            ')
    return passed, result.checks, result.failures


FIXTURES = os.path.join(TESTS_DIR, 'lib', 'runner_fixtures')
# fixture file -> (exit status the runner must give it, text its output must contain)
FIXTURE_EXPECTED = {
    'passing.lua': (0, 'ok    tests/lib/runner_fixtures/passing.lua'),
    'syntax_error.lua': (EXIT_FAILED, 'error while loading the file:'),
    'no_cases.lua': (EXIT_FAILED, 'the file registers no test() cases'),
    'no_checks.lua': (EXIT_FAILED, 'no checks ran in this case'),
    'failing_check.lua': (EXIT_FAILED, 'one is not two: expected 2, got 1'),
    'case_error.lua': (EXIT_FAILED, 'error: tests/lib/runner_fixtures/case_error.lua:4: boom'),
    'endless_loop.lua': (EXIT_FAILED, 'so the harness stopped it'),
}
# The runner is made to crash on passing.lua with the hidden --crash-for-self-check flag.
CRASH_FIXTURE = ('passing.lua', EXIT_CRASHED, 'runner crash (self-check)')
TRACEBACK = 'Traceback (most recent call last)'


def classify(done):
    """'crash' when the runner itself broke (a Python traceback, or an exit status
    that isn't the runner's own 0 or 1), else 'pass' or 'fail'."""
    if TRACEBACK in done.stderr or TRACEBACK in done.stdout:
        return 'crash'
    if done.returncode == 0:
        return 'pass'
    return 'fail' if done.returncode == EXIT_FAILED else 'crash'


def self_check():
    """Runs each tests/lib/runner_fixtures file through this runner, in a
    separate process, and checks its exit status AND its output: the passing one
    exits 0, every broken one exits EXIT_FAILED with its own failure text and no
    Python traceback, and a deliberately crashed runner must be told apart from
    a caught failure (it has to come out as 'crash'). So a runner that stops
    noticing a failure mode, or one that crashes, is caught. Returns 0 when all
    behave."""
    import subprocess
    bad = 0

    def run(path, *flags):
        return subprocess.run([sys.executable, os.path.abspath(__file__), *flags, path],
                              capture_output=True, text=True)

    for name, (expected, text) in FIXTURE_EXPECTED.items():
        done = run(os.path.join(FIXTURES, name))
        kind = classify(done)
        want = 'pass' if expected == 0 else 'fail'
        problems = []
        if kind != want:
            problems.append(f'classified {kind}, expected {want}')
        if done.returncode != expected:
            problems.append(f'exit {done.returncode}, expected {expected}')
        if text not in done.stdout:
            problems.append(f'output lacks {text!r}')
        if done.stderr.strip():
            problems.append('wrote to stderr')
        print(f'{"FAIL" if problems else "ok  "}  {name}: exit {done.returncode} ({kind})'
              + (f' - {"; ".join(problems)}' if problems else ''))
        if problems:
            bad += 1
            print_lines((done.stdout + done.stderr).splitlines(), '      ')

    name, expected, text = CRASH_FIXTURE
    done = run(os.path.join(FIXTURES, name), '--crash-for-self-check')
    kind = classify(done)
    good = kind == 'crash' and done.returncode == expected and text in done.stderr
    print(f'{"ok  " if good else "FAIL"}  {name} with --crash-for-self-check: exit {done.returncode} ({kind}), '
          f'expected a crash (exit {expected})')
    if not good:
        bad += 1
        print_lines((done.stdout + done.stderr).splitlines(), '      ')

    # every fixture on disk must be listed, so a new one can't go unchecked
    on_disk = {n for n in os.listdir(FIXTURES) if n.endswith('.lua')}
    for name in sorted(on_disk - set(FIXTURE_EXPECTED)):
        print(f'FAIL  {name}: a fixture the self-check does not list')
        bad += 1
    print(f'runner self-check: {"all fixtures behave" if not bad else f"{bad} problem(s)"}')
    return 1 if bad else 0


def main():
    parser = argparse.ArgumentParser(prog='tests/run', description="Runs SaftUI's Lua tests on Lua 5.1.")
    parser.add_argument('paths', nargs='*', help='test files, or folders to search for *_test.lua (default: tests/)')
    parser.add_argument('-v', '--verbose', action='store_true', help='list every case and show what tests printed')
    parser.add_argument('--self-check', action='store_true',
                        help="check the runner itself: each file in tests/lib/runner_fixtures must give the exit status it should")
    parser.add_argument('--crash-for-self-check', action='store_true', help=argparse.SUPPRESS)
    args = parser.parse_args()
    if args.crash_for_self_check:  # only the self-check uses this: a runner crash on demand
        raise RuntimeError('runner crash (self-check)')
    if args.self_check:
        return self_check()

    try:
        files = collect(args.paths)
    except UsageError as error:
        print(f'tests/run: {error}', file=sys.stderr)
        return 2

    failed_files = total_checks = total_failures = 0
    for path in files:
        passed, checks, failures = report(path, args.verbose)
        failed_files += not passed
        total_checks += checks
        total_failures += failures

    print()
    print(f'{count(len(files), "file")}: {len(files) - failed_files} passed, {failed_files} failed '
          f'({count(total_checks, "check")}, {total_failures} failed)')
    return EXIT_FAILED if failed_files else 0


def entry():
    """Runs main(), turning an uncaught Python exception into EXIT_CRASHED
    (Python's own status for it is 1, the same as a test failure)."""
    try:
        return main()
    except Exception:
        import traceback
        traceback.print_exc()
        return EXIT_CRASHED


if __name__ == '__main__':
    sys.exit(entry())
