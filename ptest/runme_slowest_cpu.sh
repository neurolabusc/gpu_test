#!/usr/bin/env bash
# run_twice_threads.sh
# Runs your test twice: single-threaded and multi-threaded using a detected/estimated high-perf core count.
#
# Usage:
#   HIGH_PERF_CORES=10 ./run_twice_threads.sh   # to override auto-detection
#   ./run_twice_threads.sh

set -euo pipefail

# Path to the original script location (assumes same directory as your uploaded script)
pushd "$(dirname "$0")" > /dev/null
SCRIPTPATH="$(pwd -P)"
popd > /dev/null

# Point this to the command file created by your original script (runme_slowest_gpu.sh).
COMMANDNAME="$SCRIPTPATH/command.txt"
LOGNAME="$SCRIPTPATH/logs"

# Helper: detect platform
OS="$(uname -s)"

# Allow override from env var
if [[ -n "${HIGH_PERF_CORES:-}" ]]; then
  HIGH_PERF="${HIGH_PERF_CORES}"
else
  HIGH_PERF=""

  if [[ "$OS" == "Linux" ]]; then
    if command -v lscpu >/dev/null 2>&1; then
      cores_per_socket=$(lscpu | awk -F: '/Core\(s\) per socket/ {gsub(/ /,"",$2); print $2}')
      sockets=$(lscpu | awk -F: '/Socket\(s\)/ {gsub(/ /,"",$2); print $2}')
      if [[ -n "$cores_per_socket" && -n "$sockets" ]]; then
        physical=$(( cores_per_socket * sockets ))
        HIGH_PERF="$physical"
      fi
    fi

    # Fallback: try /proc/cpuinfo counting unique physical ids + core ids
    if [[ -z "$HIGH_PERF" && -r /proc/cpuinfo ]]; then
      physical=$(awk '/^physical id/ {phy=$4} /^core id/ {core=$4; print phy "-" core}' /proc/cpuinfo \
                 | sort -u | wc -l | tr -d ' ')
      if [[ -n "$physical" && "$physical" -gt 0 ]]; then
        HIGH_PERF="$physical"
      fi
    fi

    # final fallback: logical CPUs / 2 (if nothing else)
    if [[ -z "$HIGH_PERF" ]]; then
      logical=$(nproc)
      HIGH_PERF=$(( logical / 2 > 0 ? logical / 2 : 1 ))
    fi

  elif [[ "$OS" == "Darwin" ]]; then
    # macOS
    if command -v sysctl >/dev/null 2>&1; then
      physical=$(sysctl -n hw.physicalcpu 2>/dev/null || true)
      logical=$(sysctl -n hw.logicalcpu 2>/dev/null || true)
      # If physical detected, use it. For Apple Silicon heterogeneous chips,
      # sysctl does not always report separate P-core counts — allow override.
      if [[ -n "$physical" && "$physical" -gt 0 ]]; then
        HIGH_PERF="$physical"
      elif [[ -n "$logical" && "$logical" -gt 0 ]]; then
        HIGH_PERF="$logical"
      fi
    fi

    # final fallback: 1
    if [[ -z "$HIGH_PERF" ]]; then
      HIGH_PERF=1
    fi
  else
    # unknown OS
    HIGH_PERF=1
  fi
fi

# Apply a small safety multiplier so system remains responsive (tweakable)
# For very large machines (like 96 cores) we keep it high (0.95). You can set SAFE_FRACTION env var to change.
SAFE_FRACTION="${SAFE_FRACTION:-0.95}"

# compute final threads to use (integer, >=1)
THREADS=$(awk -v h="$HIGH_PERF" -v f="$SAFE_FRACTION" 'BEGIN{t=int(h*f+0.000001); if(t<1) t=1; print t}')

echo "Detected OS: $OS"
echo "Auto-detected high-performance core estimate: $HIGH_PERF"
echo "Using SAFE_FRACTION=$SAFE_FRACTION -> THREADS=$THREADS"
echo

if [[ ! -f "$COMMANDNAME" ]]; then
  echo "Error: command file '$COMMANDNAME' not found. Run your existing generator script first (it writes $COMMANDNAME)"
  exit 2
fi

# Run 1: single-threaded (the original baseline)
echo "=== RUN 1: single-threaded ==="
time fsl_sub -l "$LOGNAME" -N probtrackx_single -T 1 -t "$COMMANDNAME"

echo
# Run 2: high-performance threaded run
echo "=== RUN 2: multi-threaded (threads=$THREADS) ==="
time fsl_sub -l "$LOGNAME" -N probtrackx_mt -T "$THREADS" -t "$COMMANDNAME"

echo
echo "Done. Logs: $LOGNAME"