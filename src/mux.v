`timescale 1ns / 1ps
/*
 * mux.v
 * -----
 * 4-to-1 multiplexer on the 4-bit result bus.
 *
 * Selects one of four 4-bit data sources based on a 2-bit select signal.
 *
 *   sel | Output
 *   ----+--------------------
 *   00  | d0  (ADD result)
 *   01  | d1  (SUB result)
 *   10  | d2  (Registered result)
 *   11  | d3  (AND result)
 *
 * Implementation uses a priority chain of conditional assigns — synthesises
 * to a tree of 2-to-1 CMOS transmission-gate muxes.
 *
 * At CMOS level each 2-to-1 mux is built from two complementary
 * transmission gates (4 transistors total).  A 4-to-1 requires a two-level
 * tree = ~12 transistors plus inverters.
 *
 * SPDX-License-Identifier: Apache-2.0
 */

`default_nettype none

module mux4 (
    input  wire [1:0] sel,   // Operation select
    input  wire [3:0] d0,    // ADD result
    input  wire [3:0] d1,    // SUB result
    input  wire [3:0] d2,    // Register output
    input  wire [3:0] d3,    // AND result
    output wire [3:0] y      // Selected result bus
);

    // Two-level mux tree (structural style)
    wire [3:0] mux_lo;   // sel[0] chooses between d0/d1
    wire [3:0] mux_hi;   // sel[0] chooses between d2/d3

    assign mux_lo = sel[0] ? d1 : d0;
    assign mux_hi = sel[0] ? d3 : d2;

    // sel[1] picks between the two halves
    assign y = sel[1] ? mux_hi : mux_lo;

endmodule
