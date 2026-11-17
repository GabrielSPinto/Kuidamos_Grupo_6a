`timescale 1ns/1ps
// Self-checking functional smoke/regression testbench (Icarus and VCS).
// Golden reference is in externally generated NumPy vectors.
module tb_matmul4x4;
    reg clk = 1'b0;
    always #5 clk = ~clk;

    reg rst_n = 1'b0;
    reg start = 1'b0;
    reg [127:0] matrix_a = '0;
    reg [127:0] matrix_b = '0;
    wire done;
    wire [511:0] matrix_c;

    matmul4x4 dut (
        .clk(clk), .rst_n(rst_n), .start(start),
        .matrix_a(matrix_a), .matrix_b(matrix_b),
        .done(done), .matrix_c(matrix_c)
    );

`ifdef ENABLE_SVA
    matmul4x4_sva u_sva (
        .clk(clk), .rst_n(rst_n),
        .accept(start && !dut.busy_q),
        .done(done), .matrix_c(matrix_c),
        .matrix_a(matrix_a), .matrix_b(matrix_b),
        .latched_a(dut.a_q), .latched_b(dut.b_q)
    );
`endif

    integer checked = 0;
    integer fd;
    integer status;
    reg [127:0] va, vb;
    reg [511:0] vc;
    reg [1023:0] vector_path;

    task automatic assert_state(input bit expected_done,
                                input [511:0] expected_c,
                                input integer case_id);
        begin
            if (done !== expected_done) begin
                $display("ERROR case=%0d done=%b expected=%b t=%0t",case_id,done,expected_done,$time);
                $fatal(1, "done mismatch");
            end
            if (matrix_c !== expected_c) begin
                $display("ERROR case=%0d matrix_c=%0128h expected=%0128h",case_id,matrix_c,expected_c);
                $fatal(1, "matrix mismatch");
            end
        end
    endtask

    task automatic reset_dut;
        begin
            @(negedge clk);
            rst_n = 1'b0; start = 1'b0;
            matrix_a = '0; matrix_b = '0;
            repeat (2) @(posedge clk);
            #1;
            assert_state(1'b0, 512'b0, -10);
            @(negedge clk);
            rst_n = 1'b1;
        end
    endtask

    // Each transaction checks capture (N), registered result (N+1),
    // one-cycle done pulse and result retention (N+2).
    task automatic run_case(input [127:0] a,
                            input [127:0] b,
                            input [511:0] expected,
                            input integer case_id);
        begin
            @(negedge clk);
            start = 1'b1; matrix_a = a; matrix_b = b;
            @(posedge clk); #1;
            if (done !== 1'b0) $fatal(1, "done asserted on capture, case %0d",case_id);
            @(negedge clk);
            start = 1'b0;
            // Change live inputs to ensure the DUT uses captured registers.
            matrix_a = ~a; matrix_b = ~b;
            @(posedge clk); #1;
            assert_state(1'b1, expected, case_id);
            @(posedge clk); #1;
            assert_state(1'b0, expected, case_id);
            checked = checked + 1;
        end
    endtask

    task automatic check_busy_start_ignored;
        reg [127:0] zero;
        reg [127:0] ignored;
        begin
            zero = '0;
            ignored = {16{8'h7f}};
            @(negedge clk);
            start = 1'b1; matrix_a = zero; matrix_b = zero;
            @(posedge clk); #1;
            if (done !== 1'b0) $fatal(1, "done early in busy test");
            @(negedge clk);
            start = 1'b1; matrix_a = ignored; matrix_b = ignored;
            @(posedge clk); #1;
            assert_state(1'b1, 512'b0, -20);  // ignored busy start
            @(negedge clk);
            start = 1'b0;
            @(posedge clk); #1;
            assert_state(1'b0, 512'b0, -21);
            checked = checked + 1;
        end
    endtask

    task automatic check_reset_aborts;
        begin
            @(negedge clk);
            start = 1'b1; matrix_a = {16{8'h7f}}; matrix_b = {16{8'h7f}};
            @(posedge clk); #1;
            @(negedge clk);
            start = 1'b0; rst_n = 1'b0;
            @(posedge clk); #1;
            assert_state(1'b0, 512'b0, -30);
            @(negedge clk);
            rst_n = 1'b1;
            repeat (2) begin
                @(posedge clk); #1;
                assert_state(1'b0, 512'b0, -31);
            end
            checked = checked + 1;
        end
    endtask

    // Throughput: a second request can be sampled at the posedge just
    // after the previous done rises. At that edge old done deasserts.
    task automatic check_min_gap;
        reg [127:0] a;
        reg [127:0] b;
        reg [511:0] c;
        begin
            a = {16{8'h01}};
            b = {16{8'h01}};
            c = {16{32'd4}};
            @(negedge clk);
            start = 1; matrix_a = '0; matrix_b = '0;
            @(posedge clk); #1;
            @(negedge clk); start = 0;
            @(posedge clk); #1;
            assert_state(1'b1, 512'b0, -40);
            @(negedge clk);
            start = 1; matrix_a = a; matrix_b = b;
            @(posedge clk); #1;
            assert_state(1'b0, 512'b0, -41);
            @(negedge clk); start = 0;
            @(posedge clk); #1;
            assert_state(1'b1, c, -42);
            @(posedge clk); #1;
            assert_state(1'b0, c, -43);
            checked = checked + 1;
        end
    endtask

    initial begin
        if (!$value$plusargs("VECTORS=%s", vector_path))
            vector_path = "vectors/matmul_vectors.txt";
        // Prevent a stalled regression from passing indefinitely.
        #5000000;
        $fatal(1, "global testbench timeout");
    end

    initial begin
        reset_dut();
        fd = $fopen(vector_path, "r");
        if (fd == 0) $fatal(1, "could not open vector file %0s", vector_path);
        while (!$feof(fd)) begin
            status = $fscanf(fd, "%h %h %h", va, vb, vc);
            if (status == 3)
                run_case(va, vb, vc, checked);
            else if (status != -1 && status != 0)
                $fatal(1, "incomplete vector entry (read %0d fields)",status);
            else if (status == 0)
                $fatal(1, "invalid vector syntax");
        end
        $fclose(fd);
        check_busy_start_ignored();
        check_reset_aborts();
        check_min_gap();
        $display("PASS: %0d transactions/tests, plus 1-cycle protocol, reset, busy ignore and retention",checked);
        $finish;
    end
endmodule
