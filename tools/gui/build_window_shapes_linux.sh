#!/usr/bin/env bash
# Sources are snapshots in scratch; no remote checkout is changed.
set -euo pipefail
source "$(dirname "$0")/env.sh"
cd "$REMOTE_SCRATCH"
cmake -S shape-core-linux -B shape-core-linux-build -G Ninja -DCMAKE_BUILD_TYPE=Debug > shape-core-linux-build.log 2>&1
cmake --build shape-core-linux-build --target window_shape_test -j 4 >> shape-core-linux-build.log 2>&1
./shape-core-linux-build/tests/window_shape_test
c++ -std=c++17 core_window_shape_test_linux.cpp -I shape-core-linux/src \
  shape-core-linux-build/src/libnativeapi.a $(pkg-config --cflags --libs gtk+-3.0 x11 xi) \
  -lXext -pthread -o core_window_shape_test_linux
c++ -std=c++17 core_window_input_shape_test_linux.cpp -I shape-core-linux/src \
  shape-core-linux-build/src/libnativeapi.a $(pkg-config --cflags --libs gtk+-3.0 x11 xi) \
  -pthread -o core_window_input_shape_test_linux
