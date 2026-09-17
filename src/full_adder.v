`timescale 1ns / 1ps
/*
 * full_adder.v
 * ------------
 * Single-bit full adder.
 *
 * Truth table:
 *   a  b  cin | sum  cout
 *   0  0   0  |  0    0
 *   0  0   1  |  1    0
 *   0  1   0  |  1    0
 *   0  1   1  |  0    1
 *   1  0   0  |  1    0
 *   1  0   1  |  0    1
 *   1  1   0  |  0    1
 *   1  1   1  |  1    1
 *
 * Boolean equations:
 *   sum  = a XOR b XOR cin
 *   cout = (a AND b) OR (a AND cin) OR (b AND cin)
 *
 * At transistor level each XOR gate is ~8 CMOS transistors,
 * each AND/OR pair reduces to ~6, giving roughly 22 transistors
 * per full adder cell.
 *
 * SPDX-License-Identifier: Apache-2.0
 */

`default_nettype none

module full_adder (
    input  wire a,      // Bit from operand A
    input  wire b,      // Bit from operand B
    input  wire cin,    // Carry-in from the previous stage
    output wire sum,    // Sum output bit
    output wire cout    // Carry-out to the next stage
);

    // ---- SUM: two-level XOR tree ----------------------------------------
    assign sum  = a ^ b ^ cin;

    // ---- CARRY: majority function ----------------------------------------
    assign cout = (a & b) | (a & cin) | (b & cin);

endmodule
