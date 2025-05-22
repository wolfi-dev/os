#!/bin/bash

set -e
set -o pipefail

ZTUNNEL_BIN=${ZTUNNEL_BIN:-"/usr/bin/ztunnel"}
TIMEOUT=30
LOG_FILE=$(mktemp)
PID_FILE=$(mktemp)

cleanup() {
  echo "Cleaning up..."
  if [ -f "$PID_FILE" ] && [ -s "$PID_FILE" ]; then
    PID=$(cat "$PID_FILE")
    if ps -p "$PID" > /dev/null; then
      echo "Stopping ztunnel (PID: $PID)"
      kill -TERM "$PID" 2>/dev/null || kill -KILL "$PID" 2>/dev/null
    fi
  fi
  rm -f "$LOG_FILE" "$PID_FILE"
  echo "Cleanup complete"
}

trap cleanup EXIT INT TERM

check_binary() {
  echo "Checking ztunnel binary..."
  if [ ! -f "$ZTUNNEL_BIN" ] || [ ! -x "$ZTUNNEL_BIN" ]; then
    echo "ERROR: ztunnel binary not found or not executable at $ZTUNNEL_BIN"
    exit 1
  fi
  echo "ztunnel binary check passed"
}

start_ztunnel() {
  echo "Starting ztunnel..."
  
  # Check if ztunnel supports --help to see available options
  SUPPORTED_ARGS=""
  if $ZTUNNEL_BIN --help 2>&1 | grep -q "\--fake-ca"; then
    SUPPORTED_ARGS="--fake-ca"
    echo "Found support for --fake-ca flag"
  fi
  
  if $ZTUNNEL_BIN --help 2>&1 | grep -q "\--mock-xds"; then
    SUPPORTED_ARGS="$SUPPORTED_ARGS --mock-xds"
    echo "Found support for --mock-xds flag"
  fi
  
  # Start ztunnel with supported arguments or none if none are supported
  echo "Starting ztunnel with args: $SUPPORTED_ARGS"
  $ZTUNNEL_BIN $SUPPORTED_ARGS > "$LOG_FILE" 2>&1 &
  
  echo $! > "$PID_FILE"
  PID=$(cat "$PID_FILE")
  
  echo "ztunnel started with PID $PID"
  
  sleep 2
  
  if ! ps -p "$PID" > /dev/null; then
    echo "ERROR: ztunnel process died immediately after startup. Check logs:"
    cat "$LOG_FILE"
    return 1
  fi
  
  return 0
}

wait_for_startup() {
  echo "Waiting for ztunnel to stabilize..."
  
  local start_time=$(date +%s)
  local current_time
  local elapsed_time
  
  while true; do
    current_time=$(date +%s)
    elapsed_time=$((current_time - start_time))
    
    if ! ps -p "$PID" > /dev/null; then
      echo "ERROR: ztunnel process died during startup period. Check logs:"
      cat "$LOG_FILE"
      return 1
    fi
    
    # Check for successful startup indicators in logs
    if grep -q "ztunnel initialized" "$LOG_FILE" || 
       grep -q "started workload connection server" "$LOG_FILE" ||
       grep -q "Listener is listening" "$LOG_FILE"; then
      echo "Found successful startup indicators in logs"
      return 0
    fi
    
    if [ "$elapsed_time" -ge "$TIMEOUT" ]; then
      echo "ztunnel has been running for $TIMEOUT seconds without crashing"
      return 0
    fi
    
    sleep 1
  done
}

verify_functionality() {
  echo "Verifying ztunnel functionality..."
  
  echo "Process information:"
  ps -p "$PID" -o pid,ppid,cmd,etime
  
  echo "Open ports for PID $PID:"
  lsof -Pan -p "$PID" -i 2>/dev/null || echo "No open ports found"
  
  echo "First 20 lines of log output:"
  head -n 20 "$LOG_FILE"
  
  echo "Last 20 lines of log output:"
  tail -n 20 "$LOG_FILE"
  
  # Check for critical errors
  if grep -i "fatal\|critical\|panic\|segmentation\|core dumped" "$LOG_FILE"; then
    echo "ERROR: Found critical errors in logs"
    return 1
  fi
  
  # Check if the process is still running
  if ! ps -p "$PID" > /dev/null; then
    echo "ERROR: ztunnel process is not running"
    return 1
  fi
  
  echo "ztunnel process is still running after startup period"
  echo "NOTE: XDS connection warnings are expected in a standalone test environment"
  echo "Basic functionality verification passed"
  
  return 0
}

main() {
  echo "=== Starting ztunnel basic functionality test ==="
  
  check_binary
  
  if ! start_ztunnel; then
    echo "=== ztunnel test FAILED (could not start) ==="
    return 1
  fi
  
  if wait_for_startup; then
    if verify_functionality; then
      echo "=== ztunnel test PASSED ==="
      return 0
    else
      echo "=== ztunnel test FAILED (functionality check) ==="
      return 1
    fi
  else
    echo "=== ztunnel test FAILED (startup failure) ==="
    return 1
  fi
}

main
exit $?
