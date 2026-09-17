`timescale 1ns / 1ps
/*
 * ripple_adder.v
 * --------------
 * Parameterised N-bit ripple-carry adder.
 *
 * Constructed by chaining N full_adder cells.
 * The carry output of stage [i] feeds the carry input of stage [i+1].
 *
 * Internal carry bus:  c[0] = cin (external carry-in)
 *                      c[N] = cout (external carry-out / overflow flag)
 *
 * DATA BUSES:
 *   a[N-1:0]   — Operand A bus
 *   b[N-1:0]   — Operand B bus
 *   sum[N-1:0] — Result bus
 *   c[N:0]     — Internal carry chain (N+1 single-bit wires)
 *
 * Default width: WIDTH = 4 (fits TinyTapeout 4-bit operand pins).
 *
 * SPDX-License-Identifier: Apache-2.0
 */

`default_nettype none

module ripple_adder #(
    parameter WIDTH = 4
) (
    input  wire [WIDTH-1:0] a,     // Operand A bus
    input  wire [WIDTH-1:0] b,     // Operand B bus
    input  wire             cin,   // Carry-in (0 for plain add, 1 for subtract)
    output wire [WIDTH-1:0] sum,   // Sum bus
    output wire             cout   // Carry-out (overflow / borrow indicator)
);

    // Internal carry chain: c[0]=cin, c[WIDTH]=cout
    wire [WIDTH:0] c;
    assign c[0] = cin;             // Inject external carry-in at LSB stage

    // Generate WIDTH full-adder instances
    genvar i;
    generate
        for (i = 0; i < WIDTH; i = i + 1) begin : FA_STAGE
            full_adder fa_inst (
                .a    (a[i]),
                .b    (b[i]),
                .cin  (c[i]),
                .sum  (sum[i]),
                .cout (c[i+1])
            );
        end
    endgenerate

    assign cout = c[WIDTH];        // Final carry-out

endmodule
