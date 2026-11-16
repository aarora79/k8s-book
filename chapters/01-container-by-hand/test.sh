#!/bin/sh
# Tests every step of chapter 1. Runs as root on Linux: inside a kind node
# (make test does that for you) or on a Linux host (make test-local).
#   BIN     folder holding the step1..step4 binaries
#   ROOTFS  a busybox root filesystem
set -u
BIN="${BIN:-/usr/local/bin}"
ROOTFS="${ROOTFS:-/root/rootfs}"
failures=0

check() { # check <name> <expected substring> <actual output>
  case "$3" in
    *"$2"*) echo "  ok    $1" ;;
    *) echo "  FAIL  $1: wanted '$2', got:"; echo "$3" | sed 's/^/        /'; failures=$((failures + 1)) ;;
  esac
}

host_hostname=$(hostname)

echo "step1: UTS namespace"
out=$("$BIN/step1" run hostname 2>&1)
check "hostname inside is 'container'" "container" "$out"
check "host hostname unchanged" "$host_hostname" "$(hostname)"
"$BIN/step1" run sh -c 'exit 3' >/dev/null 2>&1
check "exit code passes through" "3" "$?"

echo "step2: PID namespace and root filesystem"
out=$("$BIN/step2" run "$ROOTFS" /bin/sh -c 'cat /proc/1/cmdline | tr "\0" " "' 2>&1)
check "pid 1 is our child process" "child $ROOTFS" "$out"
out=$("$BIN/step2" run "$ROOTFS" /bin/ls / 2>&1)
check "/ is the root filesystem" "bin" "$out"

echo "step3: mount namespace and /dev"
"$BIN/step3" run "$ROOTFS" /bin/sleep 30 >/dev/null 2>&1 &
sleep 1
leaked_while_running=$(grep -c " $ROOTFS/proc " /proc/self/mountinfo)
pkill -9 -f "exe child $ROOTFS /bin/sleep"
wait 2>/dev/null
check "container /proc is invisible to the host" "0" "$leaked_while_running"
out=$("$BIN/step3" run "$ROOTFS" /bin/sh -c 'head -c 4 /dev/zero | wc -c' 2>&1)
check "/dev/zero works inside" "4" "$out"

echo "step4: cgroup limits"
out=$("$BIN/step4" run -pids 20 "$ROOTFS" /bin/sh -c 'for i in $(seq 1 40); do sleep 1 & done; wait' 2>&1)
check "pids limit stops the 21st process" "can't fork" "$out"
"$BIN/step4" run -memory-mb 50 "$ROOTFS" /bin/sh -c 'x=$(head -c 200000000 /dev/zero | tr "\0" a)' >/dev/null 2>&1
check "memory limit kills a 200 MB shell variable" "137" "$?"
out=$("$BIN/step4" run -memory-mb 50 "$ROOTFS" /bin/sh -c 'x=$(head -c 20000000 /dev/zero | tr "\0" a); echo ${#x}' 2>&1)
check "20 MB fits under a 50 MiB limit" "20000000" "$out"
left=$(find /sys/fs/cgroup -maxdepth 2 -name 'hmlk8s-*' | wc -l)
check "cgroups removed after exit" "0" "$left"

echo
if [ "$failures" -eq 0 ]; then echo "chapter 1: all checks passed"; else echo "chapter 1: $failures check(s) failed"; exit 1; fi
