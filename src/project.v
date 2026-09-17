`timescale 1ns / 1ps
/*
 * project.v  —  tt_um_example  (TinyTapeout top-level)
 * ======================================================
 * Educational 4-bit Calculator / ALU for TinyTapeout (IHP SG13G2).
 *
 * PIN ASSIGNMENT
 * ──────────────
 *  ui_in[3:0]   Operand A (4-bit)
 *  ui_in[5:4]   op_sel[1:0] — ALU operation select
 *                 00 = ADD   (A + B, ripple-carry adder)
 *                 01 = SUB   (A - B, two's complement)
 *                 10 = REG   (output stored register value)
 *                 11 = AND   (A & B, bitwise)
 *  ui_in[6]     reg_load — rising-edge captures result into DFF register
 *  ui_in[7]     (unused, tied off)
 *
 *  uio_in[3:0]  Operand B (4-bit)
 *  uio_in[7:4]  (unused, tied off)
 *
 *  uo_out[3:0]  ALU result[3:0]       (from MUX)
 *  uo_out[4]    carry_out / ~borrow   (1=carry for ADD, 1=no-borrow for SUB)
 *  uo_out[5]    zero_flag             (result == 0)
 *  uo_out[7:6]  demux active-channel  (one-hot[1:0] of op_sel)
 *
 *  uio_out[3:0] counter[3:0]          (free-running 4-bit up-counter)
 *  uio_out[7:4] reg_q[3:0]            (stored register value)
 *  uio_oe[7:0]  8'hFF                 (all bidirectional pins → output)
 *
 * TOP-LEVEL DATA FLOW
 * ───────────────────
 *  ui_in, uio_in
 *       │
 *       ▼
 *  ┌─────────────┐   operand buses A[3:0], B[3:0]
 *  │  Pin decode  │──────────────────────────────┐
 *  └─────────────┘                               │
 *                                                ▼
 *                                       ┌──────────────┐
 *                                       │  ripple_adder │ → add_result
 *                                       │  subtractor   │ → sub_result
 *                                       │  AND          │ → and_result
 *                                       └──────┬───────┘
 *                                              │
 *                                       ┌──────▼───────┐
 *                                       │    mux4       │ op_sel → result
 *                                       └──────┬───────┘
 *                                              │
 *                               ┌──────────────┼──────────────┐
 *                               ▼              ▼              ▼
 *                          ┌────────┐   ┌──────────┐   ┌──────────┐
 *                          │ demux4 │   │   dff4   │   │ counter4 │
 *                          │decoder │   │ register │   │  (free-  │
 *                          └───┬────┘   └────┬─────┘   │ running) │
 *                              │             │          └────┬─────┘
 *                              ▼             ▼               ▼
 *                        uo_out[7:6]   uio_out[7:4]   uio_out[3:0]
 *
 * SPDX-FileCopyrightText: 2024 TinyTapeout Educational ALU
 * SPDX-License-Identifier: Apache-2.0
 */

`default_nettype none

module tt_um_calculatorversion1 (
    input  wire [7:0] ui_in,    // Dedicated inputs  (see pin table above)
    output wire [7:0] uo_out,   // Dedicated outputs (see pin table above)
    input  wire [7:0] uio_in,   // IOs: Input path
    output wire [7:0] uio_out,  // IOs: Output path
    output wire [7:0] uio_oe,   // IOs: Enable path (active high: 1=output)
    input  wire       ena,      // Always 1 when powered — can be ignored
    input  wire       clk,      // System clock
    input  wire       rst_n     // Synchronous active-low reset
);

    // =========================================================
    // Section 1: INPUT DECODE — extract signals from pin buses
    // =========================================================

    // Operand buses
    wire [3:0] a;          // Operand A bus: ui_in[3:0]
    wire [3:0] b;          // Operand B bus: uio_in[3:0]
    assign a = ui_in[3:0];
    assign b = uio_in[3:0];

    // ALU control
    wire [1:0] op_sel;     // Operation select: ui_in[5:4]
    assign op_sel = ui_in[5:4];

    // Register load (clock-enable for DFF)
    wire reg_load;
    assign reg_load = ui_in[6];

    // =========================================================
    // Section 2: ALU (adder + subtractor + mux + flags)
    // =========================================================

    wire [3:0] alu_result;   // Muxed ALU result bus
    wire       carry_out;    // Carry/borrow flag
    wire       zero_flag;    // Zero flag
    wire [3:0] reg_q;        // Registered result (fed back into ALU mux)

    alu alu_inst (
        .op_sel    (op_sel),
        .a         (a),
        .b         (b),
        .reg_q     (reg_q),
        .result    (alu_result),
        .carry_out (carry_out),
        .zero_flag (zero_flag)
    );

    // =========================================================
    // Section 3: REGISTER — D flip-flop stores ALU result
    // =========================================================

    dff4 register (
        .clk   (clk),
        .rst_n (rst_n),
        .load  (reg_load),    // ui_in[6] high → capture result
        .d     (alu_result),  // Feed ALU result into register
        .q     (reg_q)        // Registered value fed back into ALU mux
    );

    // =========================================================
    // Section 4: COUNTER — free-running 4-bit up-counter
    // =========================================================

    wire [3:0] count;

    counter4 cnt (
        .clk   (clk),
        .rst_n (rst_n),
        .count (count)
    );

    // =========================================================
    // Section 5: DEMUX — output channel decoder
    // =========================================================

    wire [3:0] demux_y;   // One-hot active-channel indicator

    demux4 op_decoder (
        .sel (op_sel),
        .y   (demux_y)
    );

    // =========================================================
    // Section 6: OUTPUT ASSIGNMENTS
    // =========================================================

    // uo_out — dedicated output pins
    assign uo_out[3:0] = alu_result;       // ALU result bus
    assign uo_out[4]   = carry_out;        // Carry / ~borrow
    assign uo_out[5]   = zero_flag;        // Zero flag
    assign uo_out[7:6] = demux_y[1:0];     // Active-channel indicator (lsbs of one-hot)

    // uio_out — bidirectional pins used as outputs
    assign uio_out[3:0] = count;           // Counter value
    assign uio_out[7:4] = reg_q;           // Stored register value

    // uio_oe — all bidirectional pins configured as outputs
    assign uio_oe = 8'hFF;

    // =========================================================
    // Tie off unused inputs to silence linter warnings
    // =========================================================
    wire _unused = &{ena, ui_in[7], uio_in[7:4], 1'b0};

endmodule
