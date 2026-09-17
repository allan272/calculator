`timescale 1ns / 1ps
/*
 * dff.v
 * -----
 * 4-bit D flip-flop with:
 *   - Synchronous active-low reset (rst_n): clears Q to 0 on the rising
 *     clock edge while rst_n is asserted low.
 *   - Clock-enable (load): Q only updates from D when load is HIGH.
 *     When load is LOW the register holds its current value.
 *
 * This models a standard loadable register cell as found in any
 * digital design.
 *
 * At gate level each D flip-flop is built from two master/slave latches,
 * each latch comprising two cross-coupled NAND/NOR gates (~12 transistors
 * per bit in a typical standard-cell library).
 *
 * DATA BUSES:
 *   d[3:0] — 4-bit data input (from ALU result bus)
 *   q[3:0] — 4-bit registered output
 *
 * SPDX-License-Identifier: Apache-2.0
 */

`default_nettype none

module dff4 (
    input  wire       clk,    // Rising-edge clock
    input  wire       rst_n,  // Synchronous active-low reset
    input  wire       load,   // Clock-enable: 1 = capture D, 0 = hold
    input  wire [3:0] d,      // Data input bus
    output reg  [3:0] q       // Registered output bus
);

    always @(posedge clk) begin
        if (!rst_n) begin
            q <= 4'b0000;     // Synchronous reset: clear register
        end else if (load) begin
            q <= d;           // Load new value from ALU result bus
        end
        // else: hold current value (implicit, no assignment)
    end

endmodule
