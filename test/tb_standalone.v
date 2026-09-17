`timescale 1ns / 1ps
/*
 * tb_standalone.v
 * ---------------
 * Self-checking Icarus Verilog testbench for the Educational Calculator/ALU.
 * Does NOT require cocotb or Python — pure Verilog simulation.
 *
 * Run with:
 *   iverilog -g2005 -I src -o test/tb_sa.vvp \
 *       src/full_adder.v src/ripple_adder.v src/subtractor.v \
 *       src/mux.v src/demux.v src/dff.v src/counter.v \
 *       src/alu.v src/project.v test/tb_standalone.v
 *   vvp test/tb_sa.vvp
 *
 * SPDX-License-Identifier: Apache-2.0
 */

`default_nettype none

module tb_standalone;

    // ---- DUT signals ----
    reg        clk;
    reg        rst_n;
    reg        ena;
    reg  [7:0] ui_in;
    reg  [7:0] uio_in;
    wire [7:0] uo_out;
    wire [7:0] uio_out;
    wire [7:0] uio_oe;

    // ---- Waveform dump ----
    initial begin
        $dumpfile("test/tb_standalone.fst");
        $dumpvars(0, tb_standalone);
    end

    // ---- DUT instantiation ----
    tt_um_calculatorversion1 dut (
        .ui_in   (ui_in),
        .uo_out  (uo_out),
        .uio_in  (uio_in),
        .uio_out (uio_out),
        .uio_oe  (uio_oe),
        .ena     (ena),
        .clk     (clk),
        .rst_n   (rst_n)
    );

    // ---- Clock: 10 ns period ----
    initial clk = 0;
    always #5 clk = ~clk;

    // ---- Helper macros / tasks ----
    integer test_num;
    integer pass_count;
    integer fail_count;

    task check;
        input [63:0] actual;
        input [63:0] expected;
        input [127:0] label;
        begin
            test_num = test_num + 1;
            if (actual === expected) begin
                $display("  PASS [%0d] %s: got %0d", test_num, label, actual);
                pass_count = pass_count + 1;
            end else begin
                $display("  FAIL [%0d] %s: expected %0d, got %0d", test_num, label, expected, actual);
                fail_count = fail_count + 1;
            end
        end
    endtask

    // Helper: set inputs synchronously
    task set_in;
        input [3:0] a;
        input [3:0] b;
        input [1:0] op;
        input       ld;
        begin
            @(negedge clk);               // Drive on negedge to be stable by posedge
            ui_in  = {1'b0, ld, op, a};
            uio_in = {4'b0, b};
            @(posedge clk);               // Wait for rising edge
            #1;                           // Small settle time
        end
    endtask

    // ---- Convenience aliases ----
    `define RESULT     uo_out[3:0]
    `define CARRY      uo_out[4]
    `define ZERO       uo_out[5]
    `define DEMUX      uo_out[7:6]
    `define COUNTER    uio_out[3:0]
    `define REG_Q      uio_out[7:4]

    // ---- MAIN TEST ----
    initial begin
        test_num   = 0;
        pass_count = 0;
        fail_count = 0;
        ena   = 1;
        ui_in = 0;
        uio_in = 0;
        rst_n = 0;

        $display("");
        $display("============================================================");
        $display("  TinyTapeout Educational Calculator/ALU — Self-test");
        $display("============================================================");

        // ---- RESET ----
        $display("");
        $display("--- RESET ---");
        repeat(5) @(posedge clk); #1;
        check(`COUNTER, 0, "Counter=0 during reset");
        check(`REG_Q,   0, "Register=0 during reset");
        @(negedge clk); rst_n = 1;

        // ===== ADDITION (op_sel=00) =====
        $display("");
        $display("--- ADD ---");

        set_in(4'd0,  4'd0,  2'b00, 0);
        check(`RESULT, 0,  "ADD 0+0=0");
        check(`ZERO,   1,  "ADD 0+0 zero_flag=1");
        check(`CARRY,  0,  "ADD 0+0 carry=0");

        set_in(4'd3,  4'd5,  2'b00, 0);
        check(`RESULT, 8,  "ADD 3+5=8");
        check(`CARRY,  0,  "ADD 3+5 carry=0");

        set_in(4'd7,  4'd8,  2'b00, 0);
        check(`RESULT, 15, "ADD 7+8=15");
        check(`CARRY,  0,  "ADD 7+8 carry=0");

        set_in(4'd9,  4'd7,  2'b00, 0);
        check(`RESULT, 0,  "ADD 9+7=16 result=0 (overflow)");
        check(`CARRY,  1,  "ADD 9+7 carry=1 (overflow)");

        set_in(4'd15, 4'd15, 2'b00, 0);
        check(`RESULT, 14, "ADD 15+15=30 result=14");
        check(`CARRY,  1,  "ADD 15+15 carry=1");

        set_in(4'd1,  4'd0,  2'b00, 0);
        check(`RESULT, 1,  "ADD 1+0=1");

        // ===== SUBTRACTION (op_sel=01) =====
        $display("");
        $display("--- SUB ---");

        set_in(4'd5, 4'd3, 2'b01, 0);
        check(`RESULT, 2,  "SUB 5-3=2");
        check(`CARRY,  1,  "SUB 5-3 carry=1 (no borrow)");

        set_in(4'd3, 4'd5, 2'b01, 0);
        check(`RESULT, 14, "SUB 3-5=14 (=-2 mod16)");
        check(`CARRY,  0,  "SUB 3-5 carry=0 (borrow)");

        set_in(4'd0, 4'd0, 2'b01, 0);
        check(`RESULT, 0,  "SUB 0-0=0");
        check(`ZERO,   1,  "SUB 0-0 zero_flag=1");
        check(`CARRY,  1,  "SUB 0-0 carry=1 (no borrow)");

        set_in(4'd15, 4'd1, 2'b01, 0);
        check(`RESULT, 14, "SUB 15-1=14");
        check(`CARRY,  1,  "SUB 15-1 carry=1");

        set_in(4'd0, 4'd1, 2'b01, 0);
        check(`RESULT, 15, "SUB 0-1=15 (=-1 mod16)");
        check(`CARRY,  0,  "SUB 0-1 carry=0 (borrow)");

        set_in(4'd8, 4'd8, 2'b01, 0);
        check(`RESULT, 0,  "SUB 8-8=0");
        check(`ZERO,   1,  "SUB 8-8 zero_flag=1");

        // ===== AND (op_sel=11) =====
        $display("");
        $display("--- AND ---");

        set_in(4'hF, 4'hA, 2'b11, 0);
        check(`RESULT, 4'hA, "AND 0xF&0xA=0xA");

        set_in(4'h5, 4'h3, 2'b11, 0);
        check(`RESULT, 4'h1, "AND 0x5&0x3=0x1");

        set_in(4'h0, 4'hF, 2'b11, 0);
        check(`RESULT, 0,  "AND 0x0&0xF=0");
        check(`ZERO,   1,  "AND 0x0&0xF zero_flag=1");

        set_in(4'hF, 4'hF, 2'b11, 0);
        check(`RESULT, 4'hF, "AND 0xF&0xF=0xF");

        // ===== REGISTER (op_sel=10) =====
        $display("");
        $display("--- REGISTER ---");

        // Compute 6+3=9 ADD, then load into register (reg_load=1 for one cycle)
        set_in(4'd6, 4'd3, 2'b00, 1);    // ADD with reg_load=1
        // One more clock so DFF captures cleanly
        set_in(4'd6, 4'd3, 2'b00, 0);

        // Switch to REG mode, change operands — register must hold 9
        set_in(4'd0, 4'd0, 2'b10, 0);
        check(`RESULT, 9,  "REG output=9 after store");
        check(`REG_Q,  9,  "uio_out[7:4]=9 stored value");

        // Change operands again — register must still hold 9
        set_in(4'd15, 4'd15, 2'b10, 0);
        check(`RESULT, 9,  "REG holds 9 when operands change");

        // Store new value: 4+2=6
        set_in(4'd4, 4'd2, 2'b00, 1);    // ADD 4+2=6, load
        set_in(4'd4, 4'd2, 2'b00, 0);
        set_in(4'd0, 4'd0, 2'b10, 0);
        check(`RESULT, 6, "REG now holds 6");

        // ===== DEMUX INDICATOR =====
        $display("");
        $display("--- DEMUX active-channel indicator ---");
        //  op_sel  demux_y  y[1:0]
        //   00     0001     01
        //   01     0010     10
        //   10     0100     00
        //   11     1000     00 (y[3:2] not routed to uo_out — only y[1:0])
        // Note: uo_out[7:6] = demux_y[1:0]
        set_in(4'd0, 4'd0, 2'b00, 0);
        check(`DEMUX, 2'b01, "DEMUX op=00 → uo[7:6]=01");

        set_in(4'd0, 4'd0, 2'b01, 0);
        check(`DEMUX, 2'b10, "DEMUX op=01 → uo[7:6]=10");

        set_in(4'd0, 4'd0, 2'b10, 0);
        check(`DEMUX, 2'b00, "DEMUX op=10 → uo[7:6]=00");

        set_in(4'd0, 4'd0, 2'b11, 0);
        check(`DEMUX, 2'b00, "DEMUX op=11 → uo[7:6]=00 (y[3] not routed)");

        // ===== COUNTER =====
        $display("");
        $display("--- COUNTER ---");

        // Reset counter
        @(negedge clk); rst_n = 0;
        repeat(3) @(posedge clk); #1;
        check(`COUNTER, 0, "Counter reset to 0");
        @(negedge clk); rst_n = 1;

        // Count 0→16 (wraps back to 0)
        begin : COUNT_LOOP
            integer i;
            integer expected_cnt;
            for (i = 1; i <= 17; i = i + 1) begin
                @(posedge clk); #1;
                expected_cnt = i & 4'hF;
                if (`COUNTER === expected_cnt[3:0]) begin
                    $display("  PASS [cnt] cycle %0d: counter=%0d", i, `COUNTER);
                    pass_count = pass_count + 1;
                end else begin
                    $display("  FAIL [cnt] cycle %0d: expected=%0d got=%0d", i, expected_cnt, `COUNTER);
                    fail_count = fail_count + 1;
                end
                test_num = test_num + 1;
            end
        end

        // ===== ZERO FLAG =====
        $display("");
        $display("--- ZERO FLAG cross-check ---");
        set_in(4'd3, 4'd3, 2'b01, 0);   // 3-3=0
        check(`RESULT, 0, "3-3=0");
        check(`ZERO,   1, "3-3 zero_flag=1");

        set_in(4'd1, 4'd1, 2'b00, 0);   // 1+1=2 → not zero
        check(`RESULT, 2, "1+1=2");
        check(`ZERO,   0, "1+1 zero_flag=0");

        // ===== SUMMARY =====
        $display("");
        $display("============================================================");
        $display("  RESULTS: %0d passed, %0d failed, %0d total",
                 pass_count, fail_count, test_num);
        if (fail_count == 0)
            $display("  *** ALL TESTS PASSED ***");
        else
            $display("  *** %0d TEST(S) FAILED ***", fail_count);
        $display("============================================================");
        $display("");

        $finish;
    end

    // Timeout watchdog
    initial begin
        #500000;
        $display("TIMEOUT: simulation ran too long");
        $finish;
    end

endmodule
