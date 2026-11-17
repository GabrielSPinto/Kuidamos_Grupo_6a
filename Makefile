.PHONY: help test-model vectors test-rtl test-vcs lint test clean
help:
	@echo 'make test-model : Python/NumPy oracle, packing, static checks'
	@echo 'make vectors    : deterministic 1044-case vector set'
	@echo 'make test-rtl   : compile and simulate DUT using Icarus Verilog'
	@echo 'make test-vcs   : simulate DUT and SVA using Synopsys VCS'
	@echo 'make lint       : RTL lint using Verilator (when installed)'
	@echo 'make test       : Python plus RTL simulation (required for PASS)'

test-model:
	PYTHONPATH=verification python3 -m unittest discover -s verification -p 'test_*.py' -v

vectors:
	python3 verification/generate_vectors.py --output vectors/matmul_vectors.txt --random 1000 --seed 0x6A2026

test-rtl:
	bash scripts/run_iverilog.sh

test-vcs:
	bash scripts/run_vcs.sh

lint:
	verilator --lint-only --top-module matmul4x4 -Wall -Wno-fatal rtl/matmul4x4.sv

test: test-model test-rtl

clean:
	rm -rf build
