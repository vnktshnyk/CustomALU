`default_nettype none
`timescale 1ns / 1ps

/* This testbench just instantiates the module and makes some convenient wires
   that can be driven / tested by the cocotb test.py.
*/
module tb ();

  // Dump the signals to a VCD file. You can view it with gtkwave or surfer.
  initial begin
    $dumpfile("tb.vcd");
    $dumpvars(0, tb);
    #1;
  end

  // Wire up the inputs and outputs:
  reg clk;
  reg rst_n;
  reg ena;
  reg [7:0] ui_in;
  reg [7:0] uio_in;
  wire [7:0] uo_out;
  wire [7:0] uio_out;
  wire [7:0] uio_oe;

 
   initial clk = 0;
   always #5 clk = ~clk

  // Replace tt_um_example with your module name:
  tt_um_adaptuart user_project (
      .ui_in  (ui_in),    // Dedicated inputs
      .uo_out (uo_out),   // Dedicated outputs
      .uio_in (uio_in),   // IOs: Input path
      .uio_out(uio_out),  // IOs: Output path
      .uio_oe (uio_oe),   // IOs: Enable path (active high: 0=input, 1=output)
      .ena    (ena),      // enable - goes high when design is selected
      .clk    (clk),      // clock
      .rst_n  (rst_n)     // not reset
  );
  initial begin
        rst_n = 0;
        #20;
        rst_n = 1;
    end

    // Test sequence
    initial begin
        ui_in = 8'b0000_0000;

        @(posedge rst_n);
        #10;

        initial begin 
// Initialize inputs 
ena = 0; 
clk = 0; 
rst_n = 1; 
ui_in = 8'b0; 
uio_in = 8'b0; 

#10; 
// Test addition: A=3, B=5, Opcode=0000 (add) 
ui_in = {4'd5, 4'd3}; // B=5, A=3 
uio_in = 8'b0000;     // Opcode = 0000 (add) 
#10; 

// Test subtraction: A=7, B=2, Opcode=0001 (sub) 
ui_in = {4'd2, 4'd7}; 
uio_in = 8'b0001; 
#10; 

// Test multiplication: A=4, B=3, Opcode=0010 (mul) 
ui_in = {4'd3, 4'd4}; 
uio_in = 8'b0010; 
#10; 

// Test division: A=8, B=2, Opcode=0011 (div) 
ui_in = {4'd2, 4'd8}; 
uio_in = 8'b0011; 
#10; 

// Test division by zero: A=8, B=0, Opcode=0011 (div) 
ui_in = {4'd0, 4'd8}; 
uio_in = 8'b0011; 
#10; 
 
// Test rotate left: A=9 (1001), Opcode=0100 
ui_in = {4'd0, 4'd9}; 
uio_in = 8'b0100; 
#10; 
 
// Test priority encoder: A=4'b0100, Opcode=0110 
ui_in = {4'd0, 4'b0100}; 
uio_in = 8'b0110; 
#10; 

// Test gray code: A=7 (0111), Opcode=0111 
ui_in = {4'd0, 4'd7}; 
uio_in = 8'b0111; 
#10; 

// Test majority function: A=5 (0101), B=10 (1010), Opcode=1000 
ui_in = {4'd10, 4'd5}; 
uio_in = 8'b1000; 
#10; 

// Test parity detector: A=6 (0110), Opcode=1001 
ui_in = {4'd0, 4'd6}; 
uio_in = 8'b1001; 
#10; 
 
// Test AND: A=12 (1100), B=10 (1010), Opcode=1010 
ui_in = {4'd10, 4'd12}; 
uio_in = 8'b1010; 
#10; 

// Test OR: A=12 (1100), B=10 (1010), Opcode=1011 
ui_in = {4'd10, 4'd12}; 
uio_in = 8'b1011; 
#10; 
 
// Test NOT: A=5 (0101), Opcode=1100 
ui_in = {4'd0, 4'd5}; 
uio_in = 8'b1100; 
#10; 

// Test XOR: A=12 (1100), B=10 (1010), Opcode=1101 
ui_in = {4'd10, 4'd12}; 
uio_in = 8'b1101; 
#10; 

// Test Greater than: A=7, B=5, Opcode=1110 
ui_in = {4'd5, 4'd7}; 
uio_in = 8'b1110; 
#10; 

// Test Equality: A=7, B=7, Opcode=1111 
ui_in = {4'd7, 4'd7}; 
uio_in = 8'b1111; 
#10; 
 
$finish; 
      
    end
endmodule
