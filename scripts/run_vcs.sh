#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
command -v vcs >/dev/null || { echo 'ERROR: Synopsys VCS not found (CIExpert environment required).' >&2; exit 127; }
mkdir -p build/vcs
python3 verification/generate_vectors.py --output vectors/matmul_vectors.txt --random "${RANDOM_CASES:-1000}" --seed 0x6A2026
vcs -full64 -sverilog -top tb_matmul4x4 +define+ENABLE_SVA \
  -l build/vcs/compile.log -o build/vcs/simv \
  rtl/matmul4x4.sv verification/matmul4x4_sva.sv verification/tb_matmul4x4.sv
./build/vcs/simv +VECTORS=vectors/matmul_vectors.txt -l build/vcs/run.log
grep -q '^PASS:' build/vcs/run.log || { echo 'ERROR: no PASS marker' >&2; exit 1; }
