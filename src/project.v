/*
 * Copyright (c) 2024 Your Name
 * SPDX-License-Identifier: Apache-2.0
 */

`default_nettype none

module tt_um_customalu (
    input  wire [7:0] ui_in,    // Dedicated inputs
    output wire [7:0] uo_out,   // Dedicated outputs
    input  wire [7:0] uio_in,   // IOs: Input path
    output wire [7:0] uio_out,  // IOs: Output path
    output wire [7:0] uio_oe,   // IOs: Enable path (active high: 0=input, 1=output)
    input  wire       ena,      // always 1 when the design is powered, so you can ignore it
    input  wire       clk,      // clock
    input  wire       rst_n     // reset_n - low to reset
);

  // All output pins must be assigned. If not used, assign to 0.
 // assign uo_out  = ui_in + uio_in;  // Example: ou_out is the sum of ui_in and uio_in
  assign uio_out = 0;
  assign uio_oe  = 0;

  // List all unused inputs to prevent warnings
  //wire _unused = &{ena, clk, rst_n, 1'b0};
wire [3:0] A = ui_in[3:0]; 
wire [3:0] B = ui_in[7:4]; 
wire [3:0] Opcode = uio_in[3:0]; 
reg [3:0] ALU_Result; 
reg Zero, Carry, Sign, Error; 
assign uo_out = {Zero, Carry, Sign, Error, ALU_Result}; 
//assign uio_out = 8'b0; 
//assign uio_oe  = 8'b0; 
always @(*) begin 
ALU_Result = 4'b0; 
Zero = 1'b0; 
Carry = 1'b0; 
Sign = 1'b0; 
Error = 1'b0; 
case (Opcode) 
    4'b0000: begin // Addition 
        {Carry, ALU_Result} = A + B; 
        Zero = (ALU_Result == 4'b0); 
        Sign = ALU_Result[3]; 
    end 
    4'b0001: begin // Subtraction 
        {Carry, ALU_Result} = A - B; 
        Zero = (ALU_Result == 4'b0); 
        Sign = ALU_Result[3]; 
    end 
    4'b0010: begin // Multiplication 
        ALU_Result = A * B; 
        Zero = (ALU_Result == 4'b0); 
        Sign = ALU_Result[3]; 
    end 
    4'b0011: begin // Division 
      if (B != 0) begin 
        ALU_Result = A / B; 
        Zero = (ALU_Result == 4'b0); 
        Sign = ALU_Result[3]; 
        end else begin 
         Error = 1'b1; 
         Zero = 1'b1; 
         end 
     end 
     4'b0100: ALU_Result = {A[2:0],A[3]};        // Rotate left 
     4'b0101: ALU_Result = {A[0],A[3:1]};        // Rotate right 
     4'b0110: begin                              // Priority encoder (A) 
                if (A[3])      ALU_Result = 4'd3; 
                else if (A[2]) ALU_Result = 4'd2; 
                else if (A[1]) ALU_Result = 4'd1; 
                else if (A[0]) ALU_Result = 4'd0; 
                else           ALU_Result = 4'd15; // None set 
            end 
     4'b0111: ALU_Result = A ^ (A >> 1);         // Gray code of A 
     4'b1000: ALU_Result = (A & B) | (A & 4'b1010) | (B & 4'b0101); // Majority function 
      4'b1010: ALU_Result = A & B;          // AND 
      4'b1011: ALU_Result = A | B;          // OR 
      4'b1100: ALU_Result = ~A;             // NOT 
      4'b1101: ALU_Result = A ^ B;          // XOR 
      4'b1110: ALU_Result = {3'b0, (A > B)};         // Greater than 
      4'b1111: ALU_Result = {3'b0, (A == B)};        // Equality 
      default: begin 
                ALU_Result = 4'b0000; 
                Zero = 1'b1; 
        end 
        endcase 
    end  
    wire _unused = &{ena, clk, rst_n, 1'b0}; 
endmodule
