# SPDX-FileCopyrightText: © 2024 Tiny Tapeout
# SPDX-License-Identifier: Apache-2.0

import cocotb
from cocotb.clock import Clock
from cocotb.triggers import ClockCycles


@cocotb.test()
async def test_project(dut):
    dut._log.info("Start")

    # Set the clock period to 10 us (100 KHz)
    clock = Clock(dut.clk, 10, units="us")
    cocotb.start_soon(clock.start())

    # Reset
    dut._log.info("Reset")
    dut.ena.value = 1
    dut.ui_in.value = 0
    dut.uio_in.value = 0
    dut.rst_n.value = 0
    await ClockCycles(dut.clk, 10)
    dut.rst_n.value = 1

    dut._log.info("Test project behavior")

   def print_out():
        # ALU_Result corresponds to the lower 4 bits (0 to 3) in Little Endian
        ALU_Result = dut.uo_out.value[3:0+1]  # Access bits 0-3 (lowest 4 bits)
        Zero = dut.uo_out.value[4]             # Zero is bit 4
        Carry = dut.uo_out.value[5]            # Carry is bit 5
        Sign = dut.uo_out.value[6]             # Sign is bit 6
        Error = dut.uo_out.value[7]            # Error is bit 7
    
        # Log the values
        dut._log.info(
            f"Result={ALU_Result}, Zero={Zero}, Carry={Carry}, Sign={Sign}, Error={Error}"
        )


    

    # Test addition: A=3, B=5, Opcode=0000 (add)
    dut.ui_in.value = (5 << 4) | 3
    dut.uio_in.value = 0b0000
    await ClockCycles(dut.clk, 1)
    print_out()

    # Test subtraction: A=7, B=2, Opcode=0001 (sub)
    dut.ui_in.value = (2 << 4) | 7
    dut.uio_in.value = 0b0001
    await ClockCycles(dut.clk, 1)
    print_out()

    # Test multiplication: A=4, B=3, Opcode=0010 (mul)
    dut.ui_in.value = (3 << 4) | 4
    dut.uio_in.value = 0b0010
    await ClockCycles(dut.clk, 1)
    print_out()

    # Test division: A=8, B=2, Opcode=0011 (div)
    dut.ui_in.value = (2 << 4) | 8
    dut.uio_in.value = 0b0011
    await ClockCycles(dut.clk, 1)
    print_out()

    # Test division by zero: A=8, B=0, Opcode=0011 (div)
    dut.ui_in.value = (0 << 4) | 8
    dut.uio_in.value = 0b0011
    await ClockCycles(dut.clk, 1)
    print_out()

    # Test rotate left: A=9 (1001), Opcode=0100
    dut.ui_in.value = (0 << 4) | 9
    dut.uio_in.value = 0b0100
    await ClockCycles(dut.clk, 1)
    print_out()

    # Test rotate right: A=9 (1001), Opcode=0101
    dut.ui_in.value = (0 << 4) | 9
    dut.uio_in.value = 0b0101
    await ClockCycles(dut.clk, 1)
    print_out()

    # Test priority encoder: A=4'b0100, Opcode=0110
    dut.ui_in.value = (0 << 4) | 4
    dut.uio_in.value = 0b0110
    await ClockCycles(dut.clk, 1)
    print_out()

    # Test gray code: A=7 (0111), Opcode=0111
    dut.ui_in.value = (0 << 4) | 7
    dut.uio_in.value = 0b0111
    await ClockCycles(dut.clk, 1)
    print_out()

    # Test majority function: A=5 (0101), B=10 (1010), Opcode=1000
    dut.ui_in.value = (10 << 4) | 5
    dut.uio_in.value = 0b1000
    await ClockCycles(dut.clk, 1)
    print_out()

    # Test parity detector: A=6 (0110), Opcode=1001
    dut.ui_in.value = (0 << 4) | 6
    dut.uio_in.value = 0b1001
    await ClockCycles(dut.clk, 1)
    print_out()

    # Test AND: A=12 (1100), B=10 (1010), Opcode=1010
    dut.ui_in.value = (10 << 4) | 12
    dut.uio_in.value = 0b1010
    await ClockCycles(dut.clk, 1)
    print_out()

    # Test OR: A=12 (1100), B=10 (1010), Opcode=1011
    dut.ui_in.value = (10 << 4) | 12
    dut.uio_in.value = 0b1011
    await ClockCycles(dut.clk, 1)
    print_out()

    # Test NOT: A=5 (0101), Opcode=1100
    dut.ui_in.value = (0 << 4) | 5
    dut.uio_in.value = 0b1100
    await ClockCycles(dut.clk, 1)
    print_out()

    # Test XOR: A=12 (1100), B=10 (1010), Opcode=1101
    dut.ui_in.value = (10 << 4) | 12
    dut.uio_in.value = 0b1101
    await ClockCycles(dut.clk, 1)
    print_out()

    # Test Greater than: A=7, B=5, Opcode=1110
    dut.ui_in.value = (5 << 4) | 7
    dut.uio_in.value = 0b1110
    await ClockCycles(dut.clk, 1)
    print_out()

    # Test Equality: A=7, B=7, Opcode=1111
    dut.ui_in.value = (7 << 4) | 7
    dut.uio_in.value = 0b1111
    await ClockCycles(dut.clk, 1)
    print_out()

    dut._log.info("All tests completed")

    # Set the input values you want to test
    #dut.ui_in.value = 20
    #dut.uio_in.value = 30

    # Wait for one clock cycle to see the output values
    #await ClockCycles(dut.clk, 1)

    # The following assersion is just an example of how to check the output values.
    # Change it to match the actual expected output of your module:
    #assert dut.uo_out.value == 50

    # Keep testing the module by changing the input values, waiting for
    # one or more clock cycles, and asserting the expected output values.
