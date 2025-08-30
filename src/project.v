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
localparam IDLE = 2'd0;
 localparam LOAD = 2'd1;
 localparam SHIFT = 2'd2;
 reg [1:0] state;
 reg [3:0] sh_cnt;
 wire [11:0] enc_word;
 wire load;
 wire shift_en;
 wire ser_line;
 wire [11:0] rx_word;
 wire sipo_par_en;
 // Encoder: enc_word updated when 'start' asserted
 encoder_adaptive_8b_10b u_enc (
 .clk(clk), .rst_n(rst_n),
 .data_in(data_8b_in),
 .start(start),
 .idle_mode(idle_mode),
 .data_out(enc_word)
 );
 assign encoded_data = enc_word;
 // state machine: IDLE -> LOAD -> SHIFT(n cycles) -> IDLE
 always @(posedge clk or negedge rst_n) begin
 if (!rst_n) begin
 state <= IDLE;
 sh_cnt <= 4'd0;
 end else begin
 case (state)
 IDLE: begin
 if (start) state <= LOAD;
 end
 LOAD: begin
 // load happens in this cycle; begin shifting next cycle
 state <= SHIFT;
 sh_cnt <= 4'd0;
 end
 SHIFT: begin
 // perform 12 shift cycles (count from 0..11)
 if (sh_cnt == 4'd11) state <= IDLE;
 else sh_cnt <= sh_cnt + 1'b1;
 end
 default: state <= IDLE;
 endcase
 end
 end
 assign load = (state == LOAD);
 assign shift_en = (state == SHIFT);
 // PISO loads when 'load' is asserted, shifts when shift_en
 piso_12bit u_piso (
 .clk(clk), .rst_n(rst_n),
 .load(load), .shift_en(shift_en),
 .par_in(enc_word),
 .ser_out(ser_line)
 );
 // SIPO reconstructs and asserts par_en when full
 sipo_12bit u_sipo (
 .clk(clk), .rst_n(rst_n),
 .ser_in(ser_line), .shift_en(shift_en),
 .par_out(rx_word), .par_en(sipo_par_en)
 );
 // Decoder decodes only on par_en
 decoder_adaptive_12b u_dec (
    .clk(clk), .rst_n(rst_n),
 .data_in(rx_word), .par_en(sipo_par_en),
 .data_out(data_8b_out)
 );
 assign rx_par_en = sipo_par_en;
endmodule
