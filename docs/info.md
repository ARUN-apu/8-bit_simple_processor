# Simple 8-bit RISC Processor

## How it works

This project implements a simple 8-bit RISC processor with the following components:

### Architecture Overview
- **Program Counter (PC)**: 8-bit counter that tracks the current instruction address
- **Instruction Memory**: 256x8-bit memory containing pre-loaded instructions
- **Register File**: 8 registers (R0-R7), each 8-bits wide, with initial test values
- **ALU**: Arithmetic Logic Unit supporting ADD, SUB, and OR operations
- **Control Unit**: Decodes instructions and generates control signals

### Instruction Format
Each 8-bit instruction is structured as:
```
[7:6] - Opcode (2 bits)
[5:4] - Source Register 1 (RS)
[3:2] - Source Register 2 (RT) 
[1:0] - Destination Register (RD)
```

### Supported Operations
- **00**: ADD - RD = RS + RT
- **01**: SUB - RD = RS - RT  
- **10**: OR  - RD = RS | RT
- **11**: Undefined (no operation)

### Execution Flow
1. PC points to current instruction in memory
2. Instruction is fetched and decoded
3. Control unit generates appropriate control signals
4. Register file provides source operands
5. ALU performs the specified operation
6. Result is written back to destination register
7. PC increments to next instruction
8. Process repeats continuously

### Pre-loaded Program
The processor comes with a test program in instruction memory:
- Address 0: `00000001` - ADD R0,R0,R1 
- Address 1: `01000010` - SUB R1,R0,R2
- Address 2: `10000011` - OR R2,R0,R3
- Address 3: `11000100` - NOP (undefined)
- Address 4: `11001001` - NOP (undefined)  
- Address 5: `01000110` - SUB R1,R1,R2
- Address 6: `10000111` - OR R2,R1,R3
- Address 7: `00000000` - ADD R0,R0,R0

## How to test

### Basic Operation Test
1. **Power On**: Set `ena = 1`, apply clock signal
2. **Reset**: Assert `rst_n = 0` for several clock cycles, then release (`rst_n = 1`)
3. **Monitor Outputs**:
   - **uo_out[7:0]**: Displays current ALU result
   - **uio_out[7:0]**: Shows program counter value

### Expected Behavior
- **PC starts at 0** and increments each clock cycle
- **ALU results change** as different operations execute
- **After address 7**, PC wraps around to 0 (continuous execution)

### Testing Procedure
1. **Reset Test**: Verify PC returns to 0 when reset is asserted
2. **PC Increment**: Confirm PC advances sequentially (0→1→2→3...)
3. **ALU Operations**: Check that ALU results reflect the operations:
   - ADD operations produce sum of source registers
   - SUB operations produce difference 
   - OR operations produce bitwise OR result
4. **Continuous Operation**: Verify processor runs indefinitely without hanging

### Debug Information
During testing, you can observe:
- Current instruction being executed (internal signal)
- Source and destination register addresses
- Register file contents (internal signals)
- Control unit outputs (reg_write, alu_op)

### Simulation Testing
Use the provided testbench files:
- **Verilog testbench**: `tb.v` for basic simulation
- **Cocotb test**: `test.py` for automated verification
- Run simulation to generate `tb.vcd` waveform file
- View waveforms in GTKWave or similar tool

### Performance Verification
- **Clock frequency**: Tested at 100 KHz
- **Instruction throughput**: 1 instruction per clock cycle
- **Memory access**: Single-cycle instruction fetch
- **Register operations**: Single-cycle read/write

## External hardware

**No external hardware required.**

This processor is completely self-contained and operates using only the TinyTapeout interface:

### TinyTapeout Interface Usage
- **Clock input**: Standard TinyTapeout clock signal
- **Reset input**: Active-low reset (`rst_n`)
- **Enable input**: Standard enable signal (`ena`)
- **Dedicated outputs (8 pins)**: ALU result display
- **Bidirectional pins (8 pins)**: Program counter display (configured as outputs)
- **Dedicated inputs**: Not used in this design

### Optional External Components for Enhanced Testing
While not required, you could optionally add:

- **8 LEDs**: Connect to `uo_out[7:0]` to visualize ALU results
- **8 LEDs**: Connect to `uio_out[7:0]` to visualize program counter
- **Logic analyzer**: For detailed signal analysis during development
- **Oscilloscope**: To verify clock signal integrity

### Pin Configuration
- **All uio pins configured as outputs** (`uio_oe = 8'hFF`)
- **Input pins available** for future enhancements (currently unused)
- **Standard 3.3V logic levels** compatible with TinyTapeout

The processor design is intentionally simple and self-contained, making it ideal for educational purposes and ASIC implementation without requiring any external components for basic operation.
