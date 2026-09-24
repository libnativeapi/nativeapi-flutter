#!/bin/bash
# build_core_example_linux.sh <target> — build a core example on a Linux host, from the
# snapshot of core/ in the scratch directory ($REMOTE_SCRATCH/core-src), so a run does
# not depend on what is being edited in the host's own checkout. See ../README.md.
set -e
. "$(dirname "$0")/env.sh"
target=${1:?target}
src="$REMOTE_SCRATCH/core-src"
build="$REMOTE_SCRATCH/core-build"
cmake -S "$src" -B "$build" -DCMAKE_BUILD_TYPE=Debug -G Ninja > "$REMOTE_SCRATCH/cmake-configure.log" 2>&1 \
  || { tail -30 "$REMOTE_SCRATCH/cmake-configure.log"; exit 1; }
cmake --build "$build" --target "$target" -j 8 2>&1 | tail -6
ls -l "$build/examples/$target/$target"
