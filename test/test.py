# SPDX-FileCopyrightText: © 2024 TinyTapeout Educational ALU
# SPDX-License-Identifier: Apache-2.0

import cocotb
from cocotb.clock import Clock
from cocotb.triggers import ClockCycles, RisingEdge

# ---------------------------------------------------------------------------
# Helper: drive inputs and wait one cycle
# ---------------------------------------------------------------------------
async def set_inputs(dut, a, b, op_sel, reg_load=0):
    """Drive the calculator inputs. op_sel is 2-bit int."""
    dut.ui_in.value  = (reg_load << 6) | (op_sel << 4) | (a & 0xF)
    dut.uio_in.value = b & 0xF
    await ClockCycles(dut.clk, 1)


# ---------------------------------------------------------------------------
# Main test
# ---------------------------------------------------------------------------
@cocotb.test()
async def test_calculator(dut):
    dut._log.info("=== TinyTapeout Educational Calculator/ALU Test Suite ===")

    clock = Clock(dut.clk, 10, unit="us")
    cocotb.start_soon(clock.start())

    # ------------------------------------------------------------------
    # 1. RESET BEHAVIOUR
    # ------------------------------------------------------------------
    dut._log.info("--- Test: Reset ---")
    dut.ena.value    = 1
    dut.ui_in.value  = 0
    dut.uio_in.value = 0
    dut.rst_n.value  = 0
    await ClockCycles(dut.clk, 5)

    # During reset: register and counter must be 0
    assert dut.uio_out.value & 0x0F == 0, "Counter should be 0 after reset"
    assert (dut.uio_out.value >> 4) & 0xF == 0, "Register should be 0 after reset"

    dut.rst_n.value = 1          # De-assert reset
    await ClockCycles(dut.clk, 1)

    # ------------------------------------------------------------------
    # 2. ADDITION  (op_sel = 00)
    # ------------------------------------------------------------------
    dut._log.info("--- Test: ADD ---")

    # 0 + 0 = 0, zero flag = 1, carry = 0
    await set_inputs(dut, a=0, b=0, op_sel=0b00)
    result    = dut.uo_out.value & 0x0F
    carry     = (dut.uo_out.value >> 4) & 1
    zero_flag = (dut.uo_out.value >> 5) & 1
    dut._log.info(f"  0 + 0 = {result}, carry={carry}, zero={zero_flag}")
    assert result    == 0, f"ADD 0+0: expected 0, got {result}"
    assert zero_flag == 1, "ADD 0+0: expected zero_flag=1"
    assert carry     == 0, "ADD 0+0: expected carry=0"

    # 3 + 5 = 8, no carry
    await set_inputs(dut, a=3, b=5, op_sel=0b00)
    result = dut.uo_out.value & 0x0F
    carry  = (dut.uo_out.value >> 4) & 1
    dut._log.info(f"  3 + 5 = {result}, carry={carry}")
    assert result == 8, f"ADD 3+5: expected 8, got {result}"
    assert carry  == 0, "ADD 3+5: expected no carry"

    # 9 + 7 = 16 → result = 0, carry = 1 (overflow)
    await set_inputs(dut, a=9, b=7, op_sel=0b00)
    result = dut.uo_out.value & 0x0F
    carry  = (dut.uo_out.value >> 4) & 1
    dut._log.info(f"  9 + 7 = {result} (carry={carry})")
    assert result == 0,  f"ADD 9+7: expected 0 (with carry), got {result}"
    assert carry  == 1,  "ADD 9+7: expected carry=1"

    # 15 + 15 = 30 → result = 14, carry = 1
    await set_inputs(dut, a=15, b=15, op_sel=0b00)
    result = dut.uo_out.value & 0x0F
    carry  = (dut.uo_out.value >> 4) & 1
    dut._log.info(f"  15 + 15 = {result} (carry={carry}), expected 14 carry=1")
    assert result == 14, f"ADD 15+15: expected 14, got {result}"
    assert carry  == 1,  "ADD 15+15: expected carry=1"

    # 7 + 8 = 15, no carry (max no-overflow case)
    await set_inputs(dut, a=7, b=8, op_sel=0b00)
    result = dut.uo_out.value & 0x0F
    carry  = (dut.uo_out.value >> 4) & 1
    dut._log.info(f"  7 + 8 = {result}, carry={carry}")
    assert result == 15, f"ADD 7+8: expected 15, got {result}"
    assert carry  == 0,  "ADD 7+8: expected no carry"

    # ------------------------------------------------------------------
    # 3. SUBTRACTION  (op_sel = 01)
    # ------------------------------------------------------------------
    dut._log.info("--- Test: SUB ---")

    # 5 - 3 = 2, no borrow (carry=1)
    await set_inputs(dut, a=5, b=3, op_sel=0b01)
    result = dut.uo_out.value & 0x0F
    carry  = (dut.uo_out.value >> 4) & 1
    dut._log.info(f"  5 - 3 = {result}, carry(~borrow)={carry}")
    assert result == 2, f"SUB 5-3: expected 2, got {result}"
    assert carry  == 1, "SUB 5-3: expected carry=1 (no borrow)"

    # 3 - 5 = -2 → two's complement = 14, borrow (carry=0)
    await set_inputs(dut, a=3, b=5, op_sel=0b01)
    result = dut.uo_out.value & 0x0F
    carry  = (dut.uo_out.value >> 4) & 1
    dut._log.info(f"  3 - 5 = {result} (two's complement), carry(~borrow)={carry}")
    assert result == 14, f"SUB 3-5: expected 14 (=-2 mod 16), got {result}"
    assert carry  == 0,  "SUB 3-5: expected carry=0 (borrow)"

    # 0 - 0 = 0, zero flag = 1, no borrow
    await set_inputs(dut, a=0, b=0, op_sel=0b01)
    result    = dut.uo_out.value & 0x0F
    carry     = (dut.uo_out.value >> 4) & 1
    zero_flag = (dut.uo_out.value >> 5) & 1
    dut._log.info(f"  0 - 0 = {result}, zero={zero_flag}")
    assert result    == 0, f"SUB 0-0: expected 0, got {result}"
    assert zero_flag == 1, "SUB 0-0: expected zero_flag=1"
    assert carry     == 1, "SUB 0-0: expected carry=1 (no borrow)"

    # 15 - 1 = 14
    await set_inputs(dut, a=15, b=1, op_sel=0b01)
    result = dut.uo_out.value & 0x0F
    dut._log.info(f"  15 - 1 = {result}")
    assert result == 14, f"SUB 15-1: expected 14, got {result}"

    # 0 - 1 = -1 → 15, borrow
    await set_inputs(dut, a=0, b=1, op_sel=0b01)
    result = dut.uo_out.value & 0x0F
    carry  = (dut.uo_out.value >> 4) & 1
    dut._log.info(f"  0 - 1 = {result} (two's complement)")
    assert result == 15, f"SUB 0-1: expected 15, got {result}"
    assert carry  == 0,  "SUB 0-1: expected carry=0 (borrow)"

    # ------------------------------------------------------------------
    # 4. AND OPERATION  (op_sel = 11)
    # ------------------------------------------------------------------
    dut._log.info("--- Test: AND ---")

    # 0xF & 0xA = 0xA
    await set_inputs(dut, a=0xF, b=0xA, op_sel=0b11)
    result = dut.uo_out.value & 0x0F
    dut._log.info(f"  0xF & 0xA = {result:#x}")
    assert result == 0xA, f"AND 0xF&0xA: expected 0xA, got {result:#x}"

    # 0x5 & 0x3 = 0x1
    await set_inputs(dut, a=0x5, b=0x3, op_sel=0b11)
    result = dut.uo_out.value & 0x0F
    dut._log.info(f"  0x5 & 0x3 = {result:#x}")
    assert result == 0x1, f"AND 0x5&0x3: expected 0x1, got {result:#x}"

    # 0 & 0xF = 0, zero flag
    await set_inputs(dut, a=0x0, b=0xF, op_sel=0b11)
    result    = dut.uo_out.value & 0x0F
    zero_flag = (dut.uo_out.value >> 5) & 1
    dut._log.info(f"  0x0 & 0xF = {result}, zero={zero_flag}")
    assert result    == 0, f"AND 0x0&0xF: expected 0, got {result}"
    assert zero_flag == 1, "AND 0x0&0xF: expected zero_flag=1"

    # ------------------------------------------------------------------
    # 5. REGISTER STORAGE  (op_sel = 10)
    # ------------------------------------------------------------------
    dut._log.info("--- Test: Register (DFF) ---")

    # Compute 6 + 3 = 9 with ADD, then load into register
    await set_inputs(dut, a=6, b=3, op_sel=0b00, reg_load=1)
    await ClockCycles(dut.clk, 1)   # Extra cycle so DFF captures on posedge

    # Switch to REG mode and change operands — register must still show 9
    await set_inputs(dut, a=0, b=0, op_sel=0b10, reg_load=0)
    result  = dut.uo_out.value & 0x0F
    reg_val = (dut.uio_out.value >> 4) & 0xF
    dut._log.info(f"  Stored 9; REG output={result}, uio_out[7:4]={reg_val}")
    assert result  == 9, f"REG mode: expected 9 on uo_out, got {result}"
    assert reg_val == 9, f"REG uio_out: expected 9 on uio_out[7:4], got {reg_val}"

    # Change A,B without reg_load — register must not change
    await set_inputs(dut, a=15, b=15, op_sel=0b10, reg_load=0)
    result  = dut.uo_out.value & 0x0F
    reg_val = (dut.uio_out.value >> 4) & 0xF
    dut._log.info(f"  Operands changed; REG still={result}")
    assert result  == 9, f"REG hold: expected 9, got {result}"
    assert reg_val == 9, f"REG hold uio: expected 9, got {reg_val}"

    # ------------------------------------------------------------------
    # 6. COUNTER OPERATION
    # ------------------------------------------------------------------
    dut._log.info("--- Test: Counter ---")

    # Reset to get counter to 0
    dut.rst_n.value = 0
    await ClockCycles(dut.clk, 2)
    dut.rst_n.value = 1

    # Counter should now be 0
    await ClockCycles(dut.clk, 1)
    cnt = dut.uio_out.value & 0x0F
    dut._log.info(f"  Counter after reset: {cnt}")
    assert cnt == 0, f"Counter: expected 0 after reset, got {cnt}"

    # Count up 16 cycles and verify it increments correctly and wraps
    prev = 0
    for i in range(1, 17):
        await ClockCycles(dut.clk, 1)
        cnt = dut.uio_out.value & 0x0F
        expected = i & 0xF   # Wraps at 16 → 0
        dut._log.info(f"  Counter cycle {i}: {cnt} (expected {expected})")
        assert cnt == expected, f"Counter at cycle {i}: expected {expected}, got {cnt}"

    # ------------------------------------------------------------------
    # 7. DEMUX / ACTIVE CHANNEL INDICATOR  (uo_out[7:6])
    # ------------------------------------------------------------------
    dut._log.info("--- Test: Demux active-channel indicator ---")

    for op, expected_bits in [(0b00, 0b01), (0b01, 0b10), (0b10, 0b00), (0b11, 0b11)]:
        await set_inputs(dut, a=0, b=0, op_sel=op)
        indicator = (dut.uo_out.value >> 6) & 0x3
        dut._log.info(f"  op_sel={op:02b} → uo_out[7:6]={indicator:02b} (expected {expected_bits:02b})")
        assert indicator == expected_bits, \
            f"Demux op_sel={op:02b}: expected {expected_bits:02b}, got {indicator:02b}"

    # ------------------------------------------------------------------
    # 8. ZERO FLAG CROSS-CHECK
    # ------------------------------------------------------------------
    dut._log.info("--- Test: Zero flag ---")
    await set_inputs(dut, a=3, b=3, op_sel=0b01)   # 3 - 3 = 0
    zero_flag = (dut.uo_out.value >> 5) & 1
    result    = dut.uo_out.value & 0x0F
    dut._log.info(f"  3 - 3 = {result}, zero={zero_flag}")
    assert result    == 0, f"Zero flag test: expected 0, got {result}"
    assert zero_flag == 1, "Zero flag test: expected zero_flag=1"

    dut._log.info("=== ALL TESTS PASSED ===")
