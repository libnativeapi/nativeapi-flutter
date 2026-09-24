#!/usr/bin/env bash
# Run after build_window_shapes_linux.sh, through remote.sh linux desktop.
set -euo pipefail
source "$(dirname "$0")/env.sh"
GDK_BACKEND=x11 "$REMOTE_SCRATCH/core_window_shape_test_linux" | tee "$REMOTE_SCRATCH/shape-core-linux-results.log"
