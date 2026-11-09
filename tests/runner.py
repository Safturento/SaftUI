"""SaftUI's test runner. tests/run starts it with a Python that has lupa.

Each *_test.lua file runs in its own fresh Lua 5.1 state (lupa.lua51), so files
can't leak state into each other. In each state, tests/lib/harness.lua defines
the test API, builds the stubbed WoW world and the core shell, loads the file
and runs its cases (see .agents/testing.md). This file finds the test files,
prints the results and sets the exit status:

  0  every file loaded, ran at least one check, and had no failures
  1  anything else
  2  bad arguments (a path that doesn't exist, a folder with no tests)
"""

import argparse
import os
import sys

from lupa import lua51

TESTS_DIR = os.path.dirname(os.path.abspath(__file__))
REPO_ROOT = os.path.dirname(TESTS_DIR)
HARNESS = os.path.join(TESTS_DIR, 'lib', 'harness.lua')
TEST_SUFFIX = '_test.lua'


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


def main():
    parser = argparse.ArgumentParser(prog='tests/run', description="Runs SaftUI's Lua tests on Lua 5.1.")
    parser.add_argument('paths', nargs='*', help='test files, or folders to search for *_test.lua (default: tests/)')
    parser.add_argument('-v', '--verbose', action='store_true', help='list every case and show what tests printed')
    args = parser.parse_args()

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
    return 1 if failed_files else 0


if __name__ == '__main__':
    sys.exit(main())
