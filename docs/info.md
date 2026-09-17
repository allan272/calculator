<!--
This file is used to generate your project datasheet.
-->

## How it works

This is a **4-bit Educational Calculator / ALU** built from discrete, structural RTL blocks
to demonstrate how a calculator reduces from behavioural description all the way to gates and transistors.

### Block Diagram

```
  ui_in[3:0]  ─────────────────────┐
  (Operand A)                       │
  ui_in[5:4]  ─────┐               │   ┌─────────────────────────┐
  (op_sel)         │               ├──►│  ripple_adder (ADD)     │─ add_out[3:0]
  ui_in[6]    ─────┼──(reg_load)   │   │  subtractor  (SUB)      │─ sub_out[3:0]   ┌──────┐
  uio_in[3:0] ─────┼──────────────►│   │  AND (combinational)    │─ and_out[3:0] ──►      │
  (Operand B)      │               │   └─────────────────────────┘                  │ mux4 │─► result[3:0] ──► uo_out[3:0]
                   │               │   (register feedback) reg_q ──────────────────►│      │
                   │               │                                                 └──────┘
                   │               └─────────────────────────── op_sel ─────────────────┘
                   │
                   ├── op_sel ──► demux4 ──► uo_out[7:6]  (active channel indicator)
                   │
                   │   result ──► dff4 ──(reg_load)──► reg_q ──► uio_out[7:4]
                   │
                   └── clk/rst_n ──► counter4 ──► uio_out[3:0]
```

### Modules

| Module | File | Purpose |
|---|---|---|
| `full_adder` | `full_adder.v` | 1-bit full adder cell (XOR + majority) |
| `ripple_adder` | `ripple_adder.v` | N-bit adder from chained full_adder cells |
| `subtractor` | `subtractor.v` | A–B via two's complement: A + (~B) + 1 |
| `mux4` | `mux.v` | 4-to-1 result multiplexer |
| `demux4` | `demux.v` | 1-to-4 decoder / active channel indicator |
| `dff4` | `dff.v` | 4-bit D flip-flop with sync reset + load |
| `counter4` | `counter.v` | 4-bit synchronous up-counter |
| `alu` | `alu.v` | ALU wrapper: adder + subtractor + mux + flags |
| `tt_um_calculatorversion1` | `project.v` | TinyTapeout top-level — connects everything |

### Operations

| op_sel (ui[5:4]) | Operation | Description |
|---|---|---|
| `00` | ADD | `A + B` using ripple-carry adder |
| `01` | SUB | `A - B` via two's complement |
| `10` | REG | Output stored register value |
| `11` | AND | Bitwise `A & B` |

### Flags

- **carry_out** (`uo[4]`): carry from ADD; ~borrow from SUB (0 = borrow occurred)
- **zero_flag** (`uo[5]`): HIGH when result is zero

## How to test

1. Set `ui[3:0]` = Operand A, `uio[3:0]` = Operand B
2. Set `ui[5:4]` = operation (00=ADD, 01=SUB, 10=REG, 11=AND)
3. Read result from `uo[3:0]`, flags from `uo[5:4]`
4. To store a result: pulse `ui[6]` (reg_load) HIGH for one clock cycle
5. Read stored value from `uio[7:4]`; free-running counter on `uio[3:0]`

### Example: 5 + 3

- `ui[3:0]` = `0101` (5), `uio[3:0]` = `0011` (3), `ui[5:4]` = `00`
- Read: `uo[3:0]` = `1000` (8), `uo[4]` = 0 (no carry), `uo[5]` = 0

### Example: 3 − 5 (underflow)

- `ui[3:0]` = `0011` (3), `uio[3:0]` = `0101` (5), `ui[5:4]` = `01`
- Read: `uo[3:0]` = `1110` (14 = −2 mod 16), `uo[4]` = 0 (borrow occurred)

## External hardware

None required. All inputs are driven from the TinyTapeout demo board switches
and outputs observed on LEDs.
