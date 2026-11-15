"""SaftUI's test runner. tests/run starts it with a Python that has lupa.

Each *_test.lua file runs in its own fresh Lua 5.1 state (lupa.lua51), so files
can't leak state into each other. In each state, tests/lib/harness.lua defines
the test API, builds the stubbed WoW world and the core shell, loads the file
and runs its cases (see .agents/testing.md). This file finds the test files,
prints the results and sets the exit status:

  0  every file loaded, ran at least one check, and had no failures
  1  test failures: a file failed to load, ran no checks, or had a failing check
  2  bad arguments (a path that doesn't exist, a folder with no tests)
  70 the runner itself crashed (a Python exception; the traceback is on stderr),
     or a worker process died while running a file

Exit 0 means all passed and every other status is a failure. 1 and 70 are kept
apart so `tests/run --self-check` can tell a caught failure from a runner crash
(Python's own exit status for an uncaught exception is also 1).

Files run in parallel (-jN, default the CPU count): each file in its own worker
process, so still its own Lua state, and the report is printed in file order
whatever order the files finish in, with the same text as a serial run. -j1 runs
them one after another in this process, with no worker processes.

A file with scaled_test cases runs once more after its normal run, with only
those cases, in a world at one other UI scale (0.75, 1.25 or 1.55; see
rotation_scale). --scales=all runs them at all three; SAFTUI_TEST_SCALE=<scale>
puts every file's scaled run at that scale.
"""

import argparse
import contextlib
import io
import multiprocessing
import multiprocessing.connection
import os
import sys
import time


lua51 = LuaError = None  # imported in entry(), so a missing lupa is reported as a crash
CRASH_IN_RUN_FILE = False  # set by --crash-for-self-check=run_file
EXIT_BADLY_FOR = None  # set by --crash-for-self-check=worker_exit: a worker running this file exits 3 after sending its result
KILL_WORKER_FOR = None  # set by --crash-for-self-check=worker_death: a worker running this file dies

SCALES = (0.75, 1.25, 1.55)  # the scales a scaled run can be at, in rotation order
SCALES_ALL = False  # set by --scales=all: every file's scaled cases run at all of SCALES
FORCED_SCALE = None  # set by SAFTUI_TEST_SCALE: every file's scaled run is at this scale
SCALE_VARIABLE = 'SAFTUI_TEST_SCALE'

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


def scale_text(scale):
    return f'{scale:g}'


def rotation_scale(path):
    """The scale a file's scaled run is at: 0.75, 1.25 or 1.55 by the sum of the
    bytes of its repo-relative path, so files spread over the three."""
    return SCALES[sum(shown_path(path).replace(os.sep, '/').encode('utf-8')) % len(SCALES)]


def scales_for(path):
    """The scales a file's scaled cases run at, after its normal run."""
    if SCALES_ALL:
        return list(SCALES)
    return [FORCED_SCALE or rotation_scale(path)]


def run_file(path, scale=None):
    """Runs one test file in a fresh Lua state and returns the harness's result
    table. With a scale (one of SCALES) only its scaled cases run, in a world at
    that scale."""
    if CRASH_IN_RUN_FILE:
        raise RuntimeError('runner crash in run_file (self-check)')
    lua = lua51.LuaRuntime(unpack_returned_tuples=True, register_eval=False, register_builtins=False)
    lua.globals().REPO_ROOT = REPO_ROOT
    lua.globals().TESTS_DIR = TESTS_DIR
    if scale is not None:
        lua.globals().TEST_SCALE = scale
    with open(HARNESS, encoding='utf-8') as f:
        source = f.read()
    compile_chunk = lua.eval('function(source, name) return assert(loadstring(source, name)) end')
    harness_run = compile_chunk(source, '@tests/lib/harness.lua')()
    return harness_run(path, shown_path(path), scale)


def print_lines(lines, indent):
    for text in lines:
        for line in str(text).splitlines() or ['']:
            print(indent + line)


def count(n, noun):
    return f'{n} {noun}' if n == 1 else f'{n} {noun}s'


def report(path, verbose):
    """Runs a file, prints its result, and returns (passed, checks, failures).

    The file runs at k = 1, then, when it has scaled_test cases, once more with
    only those cases at each scale scales_for gives; their cases are shown as
    '<name> [at 0.75]' and count in the file's totals. A failing file shows its
    problems, its failing cases and what they printed. verbose shows every case
    and all output.
    """
    try:
        result = run_file(path)
        scaled_runs = []
        if result.scaled:
            for scale in scales_for(path):
                scaled_runs.append((scale, run_file(path, scale)))
    except LuaError as error:  # the Lua harness failed on this file. Python exceptions are runner bugs and propagate to entry()
        print(f'FAIL  {shown_path(path)}')
        print_lines([f'harness error: {error}'], '      ')
        return False, 0, 1

    runs = [(None, result)] + scaled_runs
    cases = []  # (name as shown, case)
    for scale, run in runs:
        tag = '' if scale is None else f' [at {scale_text(scale)}]'
        cases.extend((case.name + tag, case) for case in lua_list(run.cases))
    checks = sum(run.checks for _, run in runs)
    failures = sum(run.failures for _, run in runs)
    passed = all(bool(run.ok) for _, run in runs)
    summary = f'{count(len(cases), "case")}, {count(checks, "check")}'
    if failures:
        summary += f', {failures} failed'
    print(f'{"ok  " if passed else "FAIL"}  {result.path}  ({summary})')

    for scale, run in runs:
        tag = '' if scale is None else f'[at {scale_text(scale)}] '
        print_lines([tag + str(text) for text in lua_list(run.problems)], '      ')
        output = lua_list(run.output)
        if output and (not run.ok or verbose):
            print_lines([f'{tag}output while loading:'] + output, '      ')
    for name, case in cases:
        if case.ok and not verbose:
            continue
        print(f'      {"ok  " if case.ok else "FAIL"}  {name}  ({count(case.checks, "check")})')
        print_lines(lua_list(case.problems), '            ')
        output = lua_list(case.output)
        if output:
            print_lines(['output:'] + output, '            ')
    return passed, checks, failures


def render(path, verbose):
    """report() with its output returned as text: (text, passed, checks, failures, seconds)."""
    buffer = io.StringIO()
    started = time.perf_counter()
    with contextlib.redirect_stdout(buffer):
        passed, checks, failures = report(path, verbose)
    return buffer.getvalue(), passed, checks, failures, time.perf_counter() - started


def worker(path, verbose, conn):
    """Runs in a worker process: runs one file and sends its rendered report back.
    A Python exception is sent as a traceback, so the parent can call it a crash."""
    try:
        if KILL_WORKER_FOR == path:
            os._exit(9)
        conn.send(('done', render(path, verbose)))
        if EXIT_BADLY_FOR == path:
            conn.close()
            os._exit(3)
    except Exception:
        import traceback
        conn.send(('crash', traceback.format_exc()))
    finally:
        conn.close()


class WorkerCrash(Exception):
    pass


def run_parallel(files, verbose, jobs):
    """Yields render()'s result for each file, in file order, running up to jobs
    files at once, each in its own forked process. Raises WorkerCrash, naming the
    file, when a worker raised a Python exception or died without a result."""
    context = multiprocessing.get_context('fork')
    running = {}  # file index -> (process, connection)
    results = {}
    next_start = next_yield = 0
    try:
        while next_yield < len(files):
            while next_start < len(files) and len(running) < jobs:
                parent_conn, child_conn = context.Pipe(duplex=False)
                process = context.Process(target=worker, args=(files[next_start], verbose, child_conn))
                process.start()
                child_conn.close()
                running[next_start] = (process, parent_conn)
                next_start += 1
            ready = multiprocessing.connection.wait([conn for _, conn in running.values()])
            for index, (process, conn) in list(running.items()):
                if conn not in ready:
                    continue
                try:
                    kind, payload = conn.recv()
                except EOFError:  # the worker died without sending anything
                    process.join()
                    raise WorkerCrash(f'a worker process died (exit status {process.exitcode}) running '
                                      f'{shown_path(files[index])}')
                conn.close()
                process.join()
                del running[index]
                if process.exitcode != 0:  # it sent its result but did not exit cleanly
                    raise WorkerCrash(f'a worker process exited with status {process.exitcode} after running '
                                      f'{shown_path(files[index])}')
                if kind == 'crash':
                    raise WorkerCrash(f'runner crash running {shown_path(files[index])}:\n{payload}')
                results[index] = payload
            while next_yield in results:
                yield results.pop(next_yield)
                next_yield += 1
    finally:
        for process, conn in running.values():
            process.terminate()
            process.join()


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
    # both of these rotate to 1.25 (see rotation_scale), so a normal run has them both pass
    'scaled_ok.lua': (0, 'ok    tests/lib/runner_fixtures/scaled_ok.lua  (3 cases, 3 checks)'),
    'scaled_fail_155.lua': (0, 'ok    tests/lib/runner_fixtures/scaled_fail_155.lua  (2 cases, 2 checks)'),
}
# Scaled runs: (fixture, flags, SAFTUI_TEST_SCALE or None, exit status, texts the output must contain,
# texts it must not). -v lists the passing cases, so a scaled case shows by name.
SCALED_EXPECTED = [
    ('scaled_ok.lua', ['-v'], None, 0, ['plain  (1 check)', 'scaled  (1 check)', 'scaled [at 1.25]  (1 check)'], ['[at 0.75]', '[at 1.55]']),
    ('scaled_ok.lua', ['-v', '--scales=all'], None, 0, ['scaled [at 0.75]', 'scaled [at 1.25]', 'scaled [at 1.55]'], []),
    ('scaled_ok.lua', ['-v'], '1.55', 0, ['scaled [at 1.55]'], ['[at 1.25]']),
    ('scaled_fail_155.lua', ['--scales=all'], None, EXIT_FAILED, ['FAIL  fails at 1.55 [at 1.55]', 'this case fails at 1.55'], ['[at 0.75]', '[at 1.25]']),
    ('scaled_fail_155.lua', [], '1.55', EXIT_FAILED, ['fails at 1.55 [at 1.55]'], []),
    ('scaled_fail_155.lua', [], '0.75', 0, ['ok    tests/lib/runner_fixtures/scaled_fail_155.lua'], ['FAIL']),
    ('scaled_ok.lua', [], '2', 2, [], []),  # an unknown scale is a bad argument
]
# The runner is made to crash on passing.lua with the hidden --crash-for-self-check flag, in main() or inside run_file().
CRASH_FIXTURES = [  # (fixture, flag value, text on stderr, -j flag)
    ('passing.lua', 'main', 'runner crash (self-check)', '-j1'),
    ('passing.lua', 'run_file', 'runner crash in run_file (self-check)', '-j1'),  # serial, in this process
    ('passing.lua', 'run_file', 'runner crash in run_file (self-check)', '-j2'),  # in a worker process
    ('passing.lua', 'worker_death', 'a worker process died', '-j2'),
    ('passing.lua', 'worker_exit', 'exited with status 3', '-j2'),
]
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

    clean_env = {k: v for k, v in os.environ.items() if k != SCALE_VARIABLE}  # a scale set around the self-check must not reach it

    def run(path, *flags, scale=None):
        env = dict(clean_env, **({SCALE_VARIABLE: scale} if scale else {}))
        return subprocess.run([sys.executable, os.path.abspath(__file__), *flags, path],
                              capture_output=True, text=True, env=env)

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

    for name, flags, scale, expected, texts, absent in SCALED_EXPECTED:
        done = run(os.path.join(FIXTURES, name), *flags, scale=scale)
        kind = classify(done)
        want = 'pass' if expected == 0 else 'fail'
        problems = []
        if expected == 2:
            if done.returncode != 2 or TRACEBACK in done.stderr + done.stdout:
                problems.append(f'exit {done.returncode}, expected 2')
        else:
            if kind != want:
                problems.append(f'classified {kind}, expected {want}')
            if done.returncode != expected:
                problems.append(f'exit {done.returncode}, expected {expected}')
            if done.stderr.strip():
                problems.append('wrote to stderr')
        problems += [f'output lacks {text!r}' for text in texts if text not in done.stdout]
        problems += [f'output has {text!r}' for text in absent if text in done.stdout]
        label = ' '.join([name, *flags] + ([f'{SCALE_VARIABLE}={scale}'] if scale else []))
        print(f'{"FAIL" if problems else "ok  "}  {label}: exit {done.returncode} ({kind})'
              + (f' - {"; ".join(problems)}' if problems else ''))
        if problems:
            bad += 1
            print_lines((done.stdout + done.stderr).splitlines(), '      ')

    for name, where, text, jobs in CRASH_FIXTURES:
        done = run(os.path.join(FIXTURES, name), f'--crash-for-self-check={where}', jobs)
        kind = classify(done)
        good = kind == 'crash' and done.returncode == EXIT_CRASHED and text in done.stderr
        print(f'{"ok  " if good else "FAIL"}  {name} with --crash-for-self-check={where} {jobs}: exit {done.returncode} ({kind}), '
              f'expected a crash (exit {EXIT_CRASHED})')
        if not good:
            bad += 1
            print_lines((done.stdout + done.stderr).splitlines(), '      ')

    # -j1 (serial, in one process) and the default (parallel, a process per file)
    # must give the same report and exit status for every fixture, in file order
    paths = [os.path.join(FIXTURES, name) for name in sorted(FIXTURE_EXPECTED)]
    serial = subprocess.run([sys.executable, os.path.abspath(__file__), '-j1', *paths], capture_output=True, text=True, env=clean_env)
    parallel = subprocess.run([sys.executable, os.path.abspath(__file__), '-j2', *paths], capture_output=True, text=True, env=clean_env)
    same = (serial.stdout, serial.stderr, serial.returncode) == (parallel.stdout, parallel.stderr, parallel.returncode)
    print(f'{"ok  " if same else "FAIL"}  -j1 and -j2 give the same report for the fixtures')
    if not same:
        bad += 1
        print_lines(['-j1: exit ' + str(serial.returncode)] + serial.stdout.splitlines(), '      ')
        print_lines(['-j2: exit ' + str(parallel.returncode)] + parallel.stdout.splitlines(), '      ')

    # a bad -j value is a bad argument (exit 2), like any other; so is a
    # worker crash asked for with no workers
    done = run(os.path.join(FIXTURES, 'passing.lua'), '--crash-for-self-check=worker_death', '-j1')
    good = done.returncode == 2 and TRACEBACK not in done.stderr
    print(f'{"ok  " if good else "FAIL"}  worker_death with -j1: exit {done.returncode}, expected 2')
    bad += not good
    for value in ('0', 'x', '-3'):
        done = subprocess.run([sys.executable, os.path.abspath(__file__), f'-j{value}',
                               os.path.join(FIXTURES, 'passing.lua')], capture_output=True, text=True, env=clean_env)
        good = done.returncode == 2 and TRACEBACK not in done.stderr
        print(f'{"ok  " if good else "FAIL"}  -j{value}: exit {done.returncode}, expected 2')
        bad += not good

    # every fixture on disk must be listed, so a new one can't go unchecked
    on_disk = {n for n in os.listdir(FIXTURES) if n.endswith('.lua')}
    for name in sorted(on_disk - set(FIXTURE_EXPECTED)):
        print(f'FAIL  {name}: a fixture the self-check does not list')
        bad += 1
    print(f'runner self-check: {"all fixtures behave" if not bad else f"{bad} problem(s)"}')
    return 1 if bad else 0


def default_jobs():
    try:
        return max(1, len(os.sched_getaffinity(0)))
    except AttributeError:
        return max(1, os.cpu_count() or 1)


def jobs_count(text):
    try:
        n = int(text)
    except ValueError:
        n = 0
    if n < 1:
        raise argparse.ArgumentTypeError(f'invalid job count {text!r}: a whole number, 1 or more')
    return n


def main():
    parser = argparse.ArgumentParser(prog='tests/run', description="Runs SaftUI's Lua tests on Lua 5.1.")
    parser.add_argument('paths', nargs='*', help='test files, or folders to search for *_test.lua (default: tests/)')
    parser.add_argument('-v', '--verbose', action='store_true', help='list every case and show what tests printed')
    parser.add_argument('-j', '--jobs', type=jobs_count, default=None, metavar='N',
                        help='run N files at once, each in its own process (default: the CPU count; -j1 runs them one after another in this process)')
    parser.add_argument('--scales', choices=['all'], default=None,
                        help="run each file's scaled_test cases at all three scales (0.75, 1.25 and 1.55), not at the one its path picks")
    parser.add_argument('--timings', metavar='FILE', help=argparse.SUPPRESS)  # per-file seconds, tab separated, for measuring the run
    parser.add_argument('--self-check', action='store_true',
                        help="check the runner itself: each file in tests/lib/runner_fixtures must give the exit status it should")
    parser.add_argument('--crash-for-self-check', nargs='?', const='main', choices=['main', 'run_file', 'worker_death', 'worker_exit'],
                        help=argparse.SUPPRESS)  # only the self-check uses this: a runner crash on demand
    args = parser.parse_args()
    if args.crash_for_self_check == 'main':
        raise RuntimeError('runner crash (self-check)')
    if args.crash_for_self_check == 'run_file':
        global CRASH_IN_RUN_FILE
        CRASH_IN_RUN_FILE = True
    if args.self_check:
        return self_check()

    global SCALES_ALL, FORCED_SCALE
    SCALES_ALL = args.scales == 'all'
    forced = os.environ.get(SCALE_VARIABLE)
    if forced:
        matching = [scale for scale in SCALES if scale_text(scale) == forced]
        if not matching:
            print(f'tests/run: {SCALE_VARIABLE}={forced!r} is not a scale: use ' + ', '.join(scale_text(x) for x in SCALES),
                  file=sys.stderr)
            return 2
        FORCED_SCALE = matching[0]

    try:
        files = collect(args.paths)
    except UsageError as error:
        print(f'tests/run: {error}', file=sys.stderr)
        return 2

    jobs = args.jobs or default_jobs()
    if args.crash_for_self_check in ('worker_death', 'worker_exit'):
        if jobs == 1:  # -j1 has no workers to crash
            print(f'tests/run: --crash-for-self-check={args.crash_for_self_check} needs workers (not -j1)', file=sys.stderr)
            return 2
        global KILL_WORKER_FOR, EXIT_BADLY_FOR
        if args.crash_for_self_check == 'worker_death':
            KILL_WORKER_FOR = files[-1]
        else:
            EXIT_BADLY_FOR = files[-1]
    failed_files = total_checks = total_failures = 0
    timings = []
    if jobs == 1:
        results = (render(path, args.verbose) for path in files)
    else:
        results = run_parallel(files, args.verbose, jobs)
    try:
        for path, (text, passed, checks, failures, seconds) in zip(files, results, strict=True):
            sys.stdout.write(text)
            sys.stdout.flush()
            timings.append((seconds, path))
            failed_files += not passed
            total_checks += checks
            total_failures += failures
    except WorkerCrash as error:
        print(f'tests/run: {error}', file=sys.stderr)
        return EXIT_CRASHED
    if args.timings:
        with open(args.timings, 'w', encoding='utf-8') as f:
            f.writelines(f'{seconds:.3f}\t{shown_path(path)}\n' for seconds, path in timings)

    print()
    print(f'{count(len(files), "file")}: {len(files) - failed_files} passed, {failed_files} failed '
          f'({count(total_checks, "check")}, {total_failures} failed)')
    return EXIT_FAILED if failed_files else 0


def entry():
    """Runs main(), turning an uncaught Python exception into EXIT_CRASHED
    (Python's own status for it is 1, the same as a test failure)."""
    global lua51, LuaError
    try:
        from lupa import lua51 as _lua51
        lua51, LuaError = _lua51, _lua51.LuaError
        return main()
    except Exception:
        import traceback
        traceback.print_exc()
        return EXIT_CRASHED


if __name__ == '__main__':
    sys.exit(entry())
