`timescale 1ns / 1ps
/*
 * alu.v
 * -----
 * 4-bit Arithmetic Logic Unit.
 *
 * Instantiates the ripple_adder and subtractor, computes the AND operation
 * combinatorially, and selects the result using the mux4.
 *
 * Operations (op_sel):
 *   2'b00  ADD  — a + b  (carry-out on cout)
 *   2'b01  SUB  — a - b  (two's complement; borrow = ~cout)
 *   2'b10  REG  — pass-through the externally stored register value
 *   2'b11  AND  — bitwise AND  a & b
 *
 * DATA BUSES:
 *   a[3:0]       — Operand A input bus
 *   b[3:0]       — Operand B input bus
 *   reg_q[3:0]   — Registered result bus (from external DFF, fed back in)
 *   result[3:0]  — Muxed ALU result bus (goes to DFF input and uo_out)
 *   add_out[3:0] — Adder sum bus (internal)
 *   sub_out[3:0] — Subtractor difference bus (internal)
 *   and_out[3:0] — AND result bus (internal)
 *   add_c        — Adder carry-out
 *   sub_c        — Subtractor carry-out (inverted = borrow)
 *
 * SPDX-License-Identifier: Apache-2.0
 */

`default_nettype none

module alu (
    input  wire [1:0] op_sel,    // Operation select (see table above)
    input  wire [3:0] a,         // Operand A bus
    input  wire [3:0] b,         // Operand B bus
    input  wire [3:0] reg_q,     // Registered result (fed back from DFF)
    output wire [3:0] result,    // Selected result bus
    output wire       carry_out, // Carry/overflow from ADD (or SUB carry)
    output wire       zero_flag  // HIGH when result == 0
);

    // ---- Arithmetic unit outputs -----------------------------------------
    wire [3:0] add_out;   // Adder sum bus
    wire [3:0] sub_out;   // Subtractor difference bus
    wire [3:0] and_out;   // Bitwise AND bus
    wire       add_c;     // Adder carry-out
    wire       sub_c;     // Subtractor carry-out (1=no borrow, 0=borrow)

    // ---- Adder instance --------------------------------------------------
    ripple_adder #(.WIDTH(4)) adder (
        .a    (a),
        .b    (b),
        .cin  (1'b0),    // No carry-in for plain addition
        .sum  (add_out),
        .cout (add_c)
    );

    // ---- Subtractor instance ---------------------------------------------
    subtractor sub (
        .a    (a),
        .b    (b),
        .diff (sub_out),
        .cout (sub_c)
    );

    // ---- Bitwise AND (pure combinational, no extra hardware) -------------
    assign and_out = a & b;

    // ---- Operation multiplexer -------------------------------------------
    mux4 result_mux (
        .sel (op_sel),
        .d0  (add_out),  // 00 = ADD
        .d1  (sub_out),  // 01 = SUB
        .d2  (reg_q),    // 10 = REG (feed registered value back to output)
        .d3  (and_out),  // 11 = AND
        .y   (result)
    );

    // ---- Flags -----------------------------------------------------------
    // Carry-out: valid for ADD (op_sel==00) and SUB (op_sel==01)
    // For SUB: carry=0 means borrow occurred (A < B)
    assign carry_out = op_sel[0] ? sub_c : add_c;

    // Zero flag: asserted when the selected result is all zeros
    assign zero_flag = (result == 4'b0000);

endmodule
