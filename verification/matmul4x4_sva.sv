// Run with a commercial SVA-capable simulator (e.g. VCS), not Icarus.
// SVA samples signals before NBA updates. A transaction accepted at edge N
// sets busy after N, C+done after N+1. done is therefore observed by an
// assertion at edge N+2, matching |=> !done ##1 done below.
module matmul4x4_sva (
    input logic clk, rst_n, accept, done,
    input logic [127:0] matrix_a, matrix_b,
    input logic [127:0] latched_a, latched_b,
    input logic [511:0] matrix_c
);
    default clocking cb @(posedge clk); endclocking

    ap_accept_to_done: assert property (
        disable iff (!rst_n)
        accept |=> !done ##1 done
    ) else $error("done must follow accepted start with one-cycle result latency");

    ap_done_is_pulse: assert property (
        disable iff (!rst_n)
        done |=> !done
    ) else $error("done must be a one-clock pulse");

    ap_capture_together: assert property (
        disable iff (!rst_n)
        accept |=> (latched_a == $past(matrix_a) &&
                    latched_b == $past(matrix_b))
    ) else $error("both input matrices must be captured together");

    ap_result_holds: assert property (
        disable iff (!rst_n)
        done |=> $stable(matrix_c)
    ) else $error("matrix_c must hold after done");

    ap_sync_reset_done: assert property (
        !rst_n |=> !done
    ) else $error("done must clear at synchronous reset");
endmodule
