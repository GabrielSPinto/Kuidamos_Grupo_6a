#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
command -v iverilog >/dev/null || { echo 'ERROR: iverilog not found. Install Icarus Verilog or use GitHub Actions.' >&2; exit 127; }
command -v vvp >/dev/null || { echo 'ERROR: vvp not found.' >&2; exit 127; }
mkdir -p build
python3 verification/generate_vectors.py --output vectors/matmul_vectors.txt --random "${RANDOM_CASES:-1000}" --seed 0x6A2026
iverilog -g2012 -Wall -s tb_matmul4x4 -o build/tb_matmul4x4.vvp rtl/matmul4x4.sv verification/tb_matmul4x4.sv
vvp build/tb_matmul4x4.vvp +VECTORS=vectors/matmul_vectors.txt | tee build/iverilog_result.log
grep -q '^PASS:' build/iverilog_result.log || { echo 'ERROR: no PASS marker' >&2; exit 1; }
