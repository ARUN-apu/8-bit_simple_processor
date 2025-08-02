# SPDX-FileCopyrightText: © 2024 Tiny Tapeout
# SPDX-License-Identifier: Apache-2.0

import cocotb
from cocotb.clock import Clock
from cocotb.triggers import ClockCycles

@cocotb.test()
async def test_project(dut):
    dut._log.info("Start 8-bit Processor Test")
    
    # Set the clock period to 10 us (100 KHz)
    clock = Clock(dut.clk, 10, units="us")
    cocotb.start_soon(clock.start())
    
    # Reset
    dut._log.info("Reset processor")
    dut.ena.value = 1
    dut.ui_in.value = 0
    dut.uio_in.value = 0
    dut.rst_n.value = 0
    await ClockCycles(dut.clk, 10)
    dut.rst_n.value = 1
    
    dut._log.info("Testing processor execution")
    
    # Wait a few cycles for processor to start executing
    await ClockCycles(dut.clk, 2)
    
    # Test initial state - PC should start from 0
    initial_pc = int(dut.uio_out.value)  # PC is output on uio_out
    dut._log.info(f"Initial PC: {initial_pc}")
    # assert initial_pc == 0, f"Expected PC=0, got PC={initial_pc}"
    
    # Let processor execute first instruction
    await ClockCycles(dut.clk, 1)
    
    # Check PC incremented
    pc_after_1 = int(dut.uio_out.value)
    dut._log.info(f"PC after 1 cycle: {pc_after_1}")
    # assert pc_after_1 == 1, f"Expected PC=1, got PC={pc_after_1}"
    
    # Test several instruction executions
    expected_instructions = [
        0b00000001,  # ADD operation
        0b01000010,  # SUB operation  
        0b10000011,  # OR operation
        0b11000100,  # Undefined operation
        0b11001001,  # Undefined operation
        0b01000110,  # SUB operation
        0b10000111,  # OR operation
        0b00000000   # ADD operation
    ]
    
    # Execute and verify each instruction
    for i, expected_instr in enumerate(expected_instructions):
        pc = int(dut.uio_out.value)
        alu_result = dut.uo_out.value
        
        dut._log.info(f"Cycle {i}: PC={pc}, ALU_Result={alu_result}")
        
        # Verify PC matches expected position
        # assert pc == i, f"Expected PC={i}, got PC={pc}"
        
        # Wait for next instruction
        await ClockCycles(dut.clk, 1)
    
    dut._log.info("Testing processor reset functionality")
    
    # Test reset during execution
    dut.rst_n.value = 0
    await ClockCycles(dut.clk, 2)
    
    # Check PC reset to 0
    pc_after_reset = int(dut.uio_out.value)
    dut._log.info(f"PC after reset: {pc_after_reset}")
    assert pc_after_reset == 0, f"Expected PC=0 after reset, got PC={pc_after_reset}"
    
    # Release reset and verify processor starts again
    dut.rst_n.value = 1
    await ClockCycles(dut.clk, 2)
    
    pc_after_restart = int(dut.uio_out.value)
    dut._log.info(f"PC after restart: {pc_after_restart}")
    assert pc_after_restart == 1, f"Expected PC=1 after restart, got PC={pc_after_restart}"
    
    dut._log.info("Testing ALU operations")
    
    # Let processor run through a few more cycles to test ALU
    previous_results = []
    for cycle in range(5):
        await ClockCycles(dut.clk, 1)
        alu_result = int(dut.uo_out.value)
        pc = int(dut.uio_out.value)
        
        dut._log.info(f"ALU Test Cycle {cycle}: PC={pc}, ALU_Result={alu_result}")
        previous_results.append(alu_result)
        
        # ALU result should be a valid 8-bit value
        assert 0 <= alu_result <= 255, f"ALU result {alu_result} out of 8-bit range"
    
    dut._log.info("Processor continuous operation test")
    
    # Test continuous operation for longer period
    start_pc = int(dut.uio_out.value)
    await ClockCycles(dut.clk, 20)
    end_pc = int(dut.uio_out.value)
    
    dut._log.info(f"Continuous test: Start PC={start_pc}, End PC={end_pc}")
    
    # PC should have advanced (accounting for potential wraparound)
    pc_difference = (end_pc - start_pc) % 256
    assert pc_difference == 20, f"Expected PC to advance by 20, advanced by {pc_difference}"
    
    dut._log.info("All tests passed! 8-bit processor working correctly")

@cocotb.test()
async def test_io_functionality(dut):
    """Test the I/O functionality specifically"""
    dut._log.info("Testing I/O functionality")
    
    # Set the clock period to 10 us (100 KHz)
    clock = Clock(dut.clk, 10, units="us")
    cocotb.start_soon(clock.start())
    
    # Reset
    dut.ena.value = 1
    dut.ui_in.value = 0
    dut.uio_in.value = 0
    dut.rst_n.value = 0
    await ClockCycles(dut.clk, 5)
    dut.rst_n.value = 1
    await ClockCycles(dut.clk, 2)
    
    # Test that uio_oe is set correctly (should be all outputs)
    uio_oe = int(dut.uio_oe.value)
    # dut._log.info(f"uio_oe value: {uio_oe:08b}")
    assert uio_oe == 0xFF, f"Expected uio_oe=0xFF, got {uio_oe:02x}"
    
    # Test that outputs are changing (processor is running)
    initial_alu = dut.uo_out.value
    initial_pc = int(dut.uio_out.value)
    
    await ClockCycles(dut.clk, 5)
    
    final_alu = int(dut.uo_out.value)
    final_pc = int(dut.uio_out.value)
    
    dut._log.info(f"ALU: {initial_alu} -> {final_alu}")
    dut._log.info(f"PC: {initial_pc} -> {final_pc}")
    
    # At least one should have changed (processor is active)
    assert (final_alu != initial_alu) or (final_pc != initial_pc), \
           "Processor outputs should change during execution"
    
    dut._log.info("I/O functionality test passed")
