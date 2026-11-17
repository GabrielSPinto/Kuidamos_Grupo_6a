#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
command -v dc_shell >/dev/null || { echo 'ERROR: Design Compiler not found (CIExpert required).' >&2; exit 127; }
: "${TARGET_LIB:?Set TARGET_LIB to the full path of the CIExpert .db standard-cell library}"
mkdir -p build/dc
# Typical Synopsys install supports -f -output_log_file. Adapt to lab version if needed.
dc_shell -f scripts/dc_synth.tcl -output_log_file build/dc/dc.log
