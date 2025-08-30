/*
 * Copyright (c) 2024 Your Name
 * SPDX-License-Identifier: Apache-2.0
 */

`default_nettype none

module tt_um_adaptuart (
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
  //assign uio_out = 0;
  //assign uio_oe  = 0;

  // List all unused inputs to prevent warnings
  //wire _unused = &{ena, clk, rst_n, 1'b0};
    wire start = uio_in[0];
    wire idle_mode = uio_in[1];
    wire rx_par_en = uio_oe[5];
    wire [11:0] encoded_data = { uio_oe[4:0],uio_out[7:0]};
    
adaptive_uart_serdes_top uut (
        .clk(clk)
        .rst_n(rst_n)
        .data_8b_in(ui_in),
        .start(start), // 1-cycle pulse
        .idle_mode(idle_mode),
        .data_8b_out(o_out),
    .encoded_data(encoded_data), // debug
    .rx_par_en(rx_par_en)
    );
endmodule
