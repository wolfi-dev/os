#!/bin/sh
# Functional checks for pytest-asyncio, run once per Python version:
#   sh ./run-tests.sh python3.X
set -eu
py="$1"

run() {
  # run <expected-summary> <pytest args...>
  want="$1"
  shift
  if ! "$py" -m pytest -p no:cacheprovider "$@" > out.txt 2>&1; then
    cat out.txt
    echo "FAIL: $py -m pytest $*"
    exit 1
  fi
  cat out.txt
  grep -qF "$want" out.txt
}

echo "== strict mode: marked coroutine tests and async generator fixtures"
run "3 passed" test_strict.py
grep -qE "^plugins:.*asyncio-" out.txt
# The header formats the Mode str-enum, which Python 3.11+ renders as
# "mode=Mode.STRICT" rather than the bare value.
grep -qiE "mode=(Mode\.)?strict" out.txt

echo "== auto mode: unmarked coroutine tests and async fixtures"
run "2 passed" --asyncio-mode=auto test_auto.py
grep -qiE "mode=(Mode\.)?auto" out.txt

echo "== module loop_scope shares one event loop across tests"
run "2 passed" test_loop_scope.py

echo "== plugin loads explicitly with entry-point autoload disabled"
export PYTEST_DISABLE_PLUGIN_AUTOLOAD=1
run "1 passed" -p pytest_asyncio.plugin test_explicit.py
unset PYTEST_DISABLE_PLUGIN_AUTOLOAD
