# Baseline nominal constraint. 100 MHz is an initial evaluation reference,
# not evidence of achievable frequency. I/O delays must later be specified
# against actual system integration; only registered internal paths are
# appropriately constrained by the clock in this isolated educational IP.
create_clock -name clk -period 10.000 [get_ports clk]
set_clock_uncertainty 0.200 [get_clocks clk]
