`timescale 1ns / 1ps
/*
 * demux.v
 * -------
 * 1-to-4 demultiplexer / output decoder.
 *
 * Decodes a 2-bit select signal into a one-hot 4-bit output.
 * Bit [i] is HIGH when sel == i, LOW otherwise.
 *
 * In this calculator the demux drives the upper two bits of uo_out
 * (only bits [1:0] of the one-hot vector are routed to pins — see top level)
 * to indicate which ALU channel is currently active.
 *
 * This block also serves as the architectural template for understanding
 * how a decoder is implemented in gates:
 *   Each output is a 2-input AND of (possibly inverted) select lines.
 *   e.g.  y[0] = ~sel[1] & ~sel[0]
 *         y[1] = ~sel[1] &  sel[0]
 *         y[2] =  sel[1] & ~sel[0]
 *         y[3] =  sel[1] &  sel[0]
 *
 * At CMOS level each AND-with-inverter is a 6-transistor NAND+INV cell.
 *
 * SPDX-License-Identifier: Apache-2.0
 */

`default_nettype none

module demux4 (
    input  wire [1:0] sel,   // Operation/channel select
    output wire [3:0] y      // One-hot decoded output
);

    // Structural decoder equations (AND of select literals)
    assign y[0] = (~sel[1]) & (~sel[0]);   // sel == 00 : ADD active
    assign y[1] = (~sel[1]) &   sel[0];    // sel == 01 : SUB active
    assign y[2] =   sel[1]  & (~sel[0]);   // sel == 10 : REG active
    assign y[3] =   sel[1]  &   sel[0];    // sel == 11 : AND active

endmodule
