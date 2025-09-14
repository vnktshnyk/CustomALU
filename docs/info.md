<!---

This file is used to generate your project datasheet. Please fill in the information below and delete any unused
sections.

You can also include images in this folder and reference them in the markdown. Each image must be less than
512 kb in size, and the combined size of all images must be less than 1 MB.
-->
## Credits
We gratefully acknowledge the Center of Excellence (CoE) in Integrated Circuits and Systems (ICAS) and the Department of Electronics and Communication Engineering (ECE) for providing the necessary resources and guidance.  
Special thanks to Dr. K. S. Geetha (Vice Principal) and Dr. K. N. Subramanya (Principal) for their constant encouragement and support in facilitating this Tiny Tapeout 8 submission

## How it works
This module implements a **Custom Arithmetic Logic Unit (ALU)** with two operating modes: standard ALU mode and Neural Processing Unit (NPU) mode.

In **ALU mode**, the design performs:
- Standard arithmetic operations: addition, subtraction, multiplication, division
- Bitwise logical operations: AND, OR, XOR, NOT
- Bit rotation (left and right)
- Priority encoder
- Gray code conversion
- Majority function logic
- Comparisons (greater than, equality)

In **NPU mode**, it performs simple neural-inspired computations including:
- Weighted sum with error correction
- ReLU-like activation
- Scaled dot product
- Max/min selection
- Thresholding
- Inverted XOR
- Sigmoid-like output
- Binary classification
- Bitwise weighted sum
- Quadratic neuron function

The operation is selected using a 4-bit opcode and mode bit provided via `uio_in`.
## How to test
- The 8-bit input signal `ui_in` is divided into:
  - **A** = `ui_in[3:0]` (lower 4 bits)
  - **B** = `ui_in[7:4]` (upper 4 bits)

- Operation is selected via:
  - **Opcode** = `uio_in[3:0]` (4-bit opcode for selecting ALU/NPU function)
  - **Mode** = `uio_in[4]`
    - `0`: ALU mode
    - `1`: NPU mode

- The 8-bit output `uo_out` is structured as:
  - `uo_out[3:0]`: ALU/NPU result
  - `uo_out[4]`: Error flag (e.g., divide by zero)
  - `uo_out[5]`: Sign flag (MSB of result)
  - `uo_out[6]`: Carry flag (for addition/subtraction)
  - `uo_out[7]`: Zero flag (result == 0)

**Testing can be done** by providing various combinations of `ui_in` and `uio_in`, then observing the result and status flags on `uo_out`.


## External hardware

List external hardware used in your project (e.g. PMOD, LED display, etc), if any
