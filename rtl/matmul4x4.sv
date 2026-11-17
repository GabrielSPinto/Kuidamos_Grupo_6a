// KUIDAMOS / CIExpert - Grupo 6A
// MatMul 4x4: signed int8 x signed int8 -> signed int32, row-major.
//
// Function: C[row,col] = sum_{k=0}^3 A[row,k] * B[k,col].
// Contract: simultaneous operand capture on posedge start when idle;
// one clock later, matrix_c updates and done pulses for one cycle.
// All state uses a single posedge clock and synchronous active-low reset.
// No pipeline, memories, inferred latches, scan ports or clock gating.
module matmul4x4 (
    input  logic         clk,
    input  logic         rst_n,
    input  logic         start,
    input  logic [127:0] matrix_a,
    input  logic [127:0] matrix_b,
    output logic         done,
    output logic [511:0] matrix_c
);
    // Coherent 256-bit input snapshot and one-bit in-flight flag.
    logic [127:0] a_q;
    logic [127:0] b_q;
    logic         busy_q;

    wire [511:0] c_comb;

    // Fully spatially parallel computation of 16 independent results.
    // Each result has four signed 8x8 multipliers, four 16->32 bit
    // sign extensions, and a balanced two-level addition tree.
    genvar row, col;
    generate
        for (row = 0; row < 4; row = row + 1) begin : g_row
            for (col = 0; col < 4; col = col + 1) begin : g_col
                wire signed [7:0] a0 = $signed(a_q[(row*4+0)*8 +: 8]);
                wire signed [7:0] a1 = $signed(a_q[(row*4+1)*8 +: 8]);
                wire signed [7:0] a2 = $signed(a_q[(row*4+2)*8 +: 8]);
                wire signed [7:0] a3 = $signed(a_q[(row*4+3)*8 +: 8]);
                wire signed [7:0] b0 = $signed(b_q[(0*4+col)*8 +: 8]);
                wire signed [7:0] b1 = $signed(b_q[(1*4+col)*8 +: 8]);
                wire signed [7:0] b2 = $signed(b_q[(2*4+col)*8 +: 8]);
                wire signed [7:0] b3 = $signed(b_q[(3*4+col)*8 +: 8]);

                wire signed [15:0] p0 = a0 * b0;
                wire signed [15:0] p1 = a1 * b1;
                wire signed [15:0] p2 = a2 * b2;
                wire signed [15:0] p3 = a3 * b3;

                // 8x8 products are exact in 16 bits. Extend *products*
                // before addition; no overflow possible in signed 32 bits.
                wire signed [31:0] s0 = {{16{p0[15]}}, p0};
                wire signed [31:0] s1 = {{16{p1[15]}}, p1};
                wire signed [31:0] s2 = {{16{p2[15]}}, p2};
                wire signed [31:0] s3 = {{16{p3[15]}}, p3};
                wire signed [31:0] sum01 = s0 + s1;
                wire signed [31:0] sum23 = s2 + s3;

                assign c_comb[(row*4+col)*32 +: 32] = sum01 + sum23;
            end
        end
    endgenerate

    // Interface protocol: start MUST be a single-cycle pulse.
    // start is only accepted when busy_q == 0. If asserted while busy,
    // it is ignored; no queue or error flag exists in v1.
    always_ff @(posedge clk) begin
        if (!rst_n) begin
            a_q      <= '0;
            b_q      <= '0;
            busy_q   <= 1'b0;
            matrix_c <= '0;
            done     <= 1'b0;
        end else begin
            done <= 1'b0;  // pulse, default deassertion
            if (busy_q) begin
                matrix_c <= c_comb;
                done     <= 1'b1;
                busy_q   <= 1'b0;
            end else if (start) begin
                a_q    <= matrix_a;
                b_q    <= matrix_b;
                busy_q <= 1'b1;
            end
            // Otherwise operands and matrix_c hold their last values.
        end
    end
endmodule
