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

        // Test 1: Transmit byte 0xA5 (1010_0101)
        ui_in = 8'b0000_0000; // clear inputs
        #10;
        ui_in = 8'b1010_0101; // data = 0xA5, EN=1, IDLE=0
        ui_in[0] = 1'b1; // ser_en
        ui_in[1] = 1'b0; // idle_mode
        #200;

        // Test 2: Repeat the same byte with IDLE = 1 to activate REP_FLAG
        ui_in = 8'b1010_0101;
        ui_in[0] = 1'b1; // ser_en
        ui_in[1] = 1'b1; // idle_mode to allow repeat
        #200;

        // Test 3: Transmit a new byte (0x3C)
        ui_in = 8'b0011_1100;
        ui_in[0] = 1'b1; // ser_en
        ui_in[1] = 1'b0; // idle_mode
        #200;

      
    end
endmodule
