`timescale 1ns / 1ps
/*
 * subtractor.v
 * ------------
 * 4-bit subtractor using two's complement method.
 *
 * A - B  is computed as  A + (~B) + 1
 *
 * The bit-inversion (~B) is applied on the B bus before feeding into the
 * ripple_adder.  The +1 is achieved by forcing cin = 1.
 *
 * Borrow (underflow):
 *   When A < B the final carry-out of the adder is 0.
 *   Conventionally:  borrow = ~cout
 *   This module exposes cout directly; the top level inverts for borrow.
 *
 * DATA BUSES:
 *   a[3:0]     — Minuend (operand A)
 *   b[3:0]     — Subtrahend (operand B)
 *   b_inv[3:0] — Bitwise-inverted B (intermediate wire)
 *   diff[3:0]  — Difference bus
 *
 * SPDX-License-Identifier: Apache-2.0
 */

`default_nettype none

module subtractor (
    input  wire [3:0] a,      // Minuend
    input  wire [3:0] b,      // Subtrahend
    output wire [3:0] diff,   // Difference = A - B (two's complement)
    output wire       cout    // Carry-out: 1 = no borrow, 0 = borrow occurred
);

    // Step 1: Bitwise invert B to begin two's complement negation
    wire [3:0] b_inv;
    assign b_inv = ~b;

    // Step 2: Feed A, ~B, and cin=1 into the ripple adder
    //         A + (~B) + 1 = A - B  (by two's complement identity)
    ripple_adder #(.WIDTH(4)) sub_adder (
        .a    (a),
        .b    (b_inv),
        .cin  (1'b1),   // The +1 of two's complement
        .sum  (diff),
        .cout (cout)
    );

endmodule
