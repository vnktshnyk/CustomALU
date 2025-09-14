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


assign uio_out = 0;
assign uio_oe  = 0;
    
reg [3:0] A_reg, B_reg, Opcode_reg;
reg Mode_reg;
    
parameter MOD_Q    = 17;
parameter WEIGHT_COEFF = 3;
parameter ERROR_E  = 2;
    
always @(posedge clk or negedge rst_n) begin
if (!rst_n) begin
    A_reg      <= 4'b0;
    B_reg      <= 4'b0;
    Opcode_reg <= 4'b0;
    Mode_reg   <= 1'b0;
end else begin
    A_reg      <= ui_in[3:0];
    B_reg      <= ui_in[7:4];
    Opcode_reg <= uio_in[3:0];
    Mode_reg   <= uio_in[4];
end

reg [3:0] ALU_Result;
reg Zero, Carry, Sign, Error;

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        ALU_Result <= 4'b0;
        Zero       <= 1'b0;
        Carry      <= 1'b0;
        Sign       <= 1'b0;
        Error      <= 1'b0;
        end else begin
            // Default values
        ALU_Result <= 4'b0;
        Zero       <= 1'b0;
        Carry      <= 1'b0;
        Sign       <= 1'b0;
        Error      <= 1'b0;
        if (Mode_reg == 1'b0) begin
                // ALU Mode
                case (Opcode_reg)
    4'b0000: begin // Addition 
         {Carry, ALU_Result} <= A_reg + B_reg;
         Zero <= ((A_reg + B_reg) == 4'b0);
         Sign <= (A_reg + B_reg)[3];
    end 
    4'b0001: begin // Subtraction 
       {Carry, ALU_Result} <= A_reg - B_reg;
        Zero <= ((A_reg - B_reg) == 4'b0);
        Sign <= (A_reg - B_reg)[3]; 
    end 
    4'b0010: begin // Multiplication 
        ALU_Result <= A_reg * B_reg;
        Zero <= ((A_reg * B_reg) == 4'b0);
        Sign <= (A_reg * B_reg)[3];
    end 
    4'b0011: begin // Division 
      if (B_reg != 0) begin
          ALU_Result <= A_reg / B_reg;
          Zero <= ((A_reg / B_reg) == 4'b0);
          Sign <= (A_reg / B_reg)[3];
       end else begin
          Error <= 1'b1;
          Zero  <= 1'b1;
       end
       end
     4'b0100: ALU_Result <= {A_reg[2:0], A_reg[3]};       // Rotate left 
     4'b0101: ALU_Result <= {A_reg[0], A_reg[3:1]};// Rotate right 
     4'b0110: begin                              // Priority encoder (A) 
              casez (A_reg)
                4'b1???: ALU_Result <= 4'd3;
                4'b01??: ALU_Result <= 4'd2;
                4'b001?: ALU_Result <= 4'd1;
                4'b0001: ALU_Result <= 4'd0;
                default: ALU_Result <= 4'd15;
                endcase
     end 
     4'b0111: ALU_Result <= A_reg ^ (A_reg >> 1);         // Gray code of A 
     4'b1000: ALU_Result <= (A_reg & B_reg) | (A_reg & 4'b1010) | (B_reg & 4'b0101); // Majority function 
     4'b1001: ALU_Result <= ((A_reg * WEIGHT_COEFF) + ERROR_E) % MOD_Q;
     4'b1010: ALU_Result <= A_reg & B_reg;        // AND 
     4'b1011: ALU_Result <= A_reg | B_reg;       // OR 
     4'b1100: ALU_Result <= ~A_reg;          // NOT 
     4'b1101: ALU_Result <= A_reg ^ B_reg;   // XOR 
     4'b1110: ALU_Result <= {3'b000, (A_reg > B_reg)};    // Greater than 
     4'b1111: ALU_Result <= {3'b000, (A_reg == B_reg)};       // Equality 
      default: begin 
                ALU_Result <= 4'b0000;
                Zero       <= 1'b1;
        end 
    endcase 
    end else begin
                // NPU Mode
                case (Opcode_reg)
                    4'b0000: ALU_Result <= ((A_reg * WEIGHT_COEFF) + ERROR_E) % MOD_Q; // Base neuron
                    4'b0001: ALU_Result <= (A_reg > B_reg) ? A_reg - B_reg : 4'b0000; // ReLU(A - B)
                    4'b0010: ALU_Result <= (A_reg * B_reg) >> 2;                       // Scaled dot product
                    4'b0011: ALU_Result <= (A_reg > B_reg) ? A_reg : B_reg;             // max(A, B)
                    4'b0100: ALU_Result <= (A_reg < B_reg) ? A_reg : B_reg;             // min(A, B) 
                    4'b0101: ALU_Result <= (A_reg > 4) ? 4'b1111 : 4'b0000;              // Threshold
                    4'b0110: ALU_Result <= ~(A_reg ^ B_reg);                            // Inverted XOR
                    4'b0111: ALU_Result <= ((A_reg + B_reg + WEIGHT_COEFF) % 10);           // Noisy neuron
                    4'b1000: ALU_Result <= (A_reg == B_reg) ? 4'b1111 : 4'b0000;        // Equality neuron
                    4'b1001: ALU_Result <= 4'b0000;
                    4'b1010: ALU_Result <= {3'b000, (A_reg[3] ^ B_reg[3])};             // Sign bit agreement
                    4'b1011: ALU_Result <= ((A_reg > 2) && (A_reg < 13)) ? 4'b1000 : 4'b0000; // Sigmoid-like
                    4'b1100: ALU_Result <= ((A_reg > B_reg) && (A_reg - B_reg > 2)) ? 4'b1111 : 4'b0000;// Fire on diff
                    4'b1101: ALU_Result <= (A_reg[3]*4 + A_reg[2]*3 + A_reg[1]*2 + A_reg[0]*1); // Bitwise weighted sum
                    4'b1110: ALU_Result <= ((A_reg * A_reg) + B_reg) % 16;                      //Quadratic neuron
                    4'b1111: ALU_Result <= (A_reg > B_reg) ? 4'b0001 : 4'b0000;                 // Binary classification
                    default: ALU_Result <= 4'b0000;
                endcase
            end
        end
    end

    wire _unused = &{ena}; 
    assign uo_out = {Zero, Carry, Sign, Error, ALU_Result}; 
endmodule
