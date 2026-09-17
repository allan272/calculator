`timescale 1ns / 1ps
/*
 * counter.v
 * ---------
 * 4-bit synchronous up-counter.
 *
 * Counts 0 → 1 → 2 → … → 15 → 0 (wraps naturally on overflow).
 * Increments on every rising clock edge when not in reset.
 *
 * Synchronous active-low reset clears the counter to 0.
 *
 * The counter output is exposed on uio_out[3:0] so that the user can
 * observe sequential behaviour (toggling bits, wrap-around) on the
 * bidirectional IO pins.
 *
 * Internally the counter is also used to demonstrate state / control
 * sequencing in the top-level design.
 *
 * DATA BUS:
 *   count[3:0] — Current counter value
 *
 * At gate level a 4-bit synchronous counter is typically built from
 * four T flip-flops (or DFFs with XOR feedback), with each stage gated
 * by the AND of all lower bits (carry look-ahead enable).
 *
 * SPDX-License-Identifier: Apache-2.0
 */

`default_nettype none

module counter4 (
    input  wire       clk,    // Rising-edge clock
    input  wire       rst_n,  // Synchronous active-low reset
    output reg  [3:0] count   // 4-bit counter value
);

    always @(posedge clk) begin
        if (!rst_n) begin
            count <= 4'b0000;   // Synchronous reset to 0
        end else begin
            count <= count + 4'b0001;  // Increment; wraps at 15→0
        end
    end

endmodule
