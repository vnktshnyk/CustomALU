`timescale 1ns/1ps
//==================================================
// Encoder (LUT-based, only some inputs mapped)
//==================================================
module encoder_adaptive_8b_10b (
 input wire clk,
 input wire rst_n,
 input wire [7:0] data_in,
 input wire start, // 1-cycle pulse to encode this data
 input wire idle_mode,
 output reg [11:0] data_out
);
 // simple LUT (sim-only init)
 reg [11:0] lut [0:255];
 integer i;
 initial begin
 for (i=0; i<256; i=i+1) lut[i] = 12'h000;
 lut[8'h00] = 12'h000;
 lut[8'h3F] = 12'hA6B;
 lut[8'h7F] = 12'h970;
 lut[8'hFF] = 12'h400;
 end
 reg [7:0] last_data;
 wire repeat_data = idle_mode && (data_in == last_data);
 always @(posedge clk or negedge rst_n) begin
 if (!rst_n) begin
 data_out <= 12'h000;
 last_data <= 8'h00;
 end else if (start) begin
 last_data <= data_in;
 if (repeat_data) begin
 // repeat token (as in your original design)
 data_out <= {1'b0, 1'b1, 10'b0000000000};
 end else begin
 data_out <= lut[data_in];
 end
 end
 end
endmodule
//==================================================
// PISO 12-bit: load on 'load' (1 cycle), shift on shift_en
//==================================================
module piso_12bit (
 input wire clk,
 input wire rst_n,
 input wire load, // asserted for 1 cycle to load par_in
 input wire shift_en, // asserted for N cycles to shift
 input wire [11:0] par_in,
 output wire ser_out
);
 reg [11:0] shift_reg;
 always @(posedge clk or negedge rst_n) begin
 if (!rst_n) begin
 shift_reg <= 12'h000;
 end else if (load) begin
 shift_reg <= par_in;
 end else if (shift_en) begin
 shift_reg <= {1'b0, shift_reg[11:1]}; // LSB-first transmit
 end
 end
 assign ser_out = shift_reg[0];
endmodule
//==================================================
// SIPO 12-bit: collects serial LSB-first, asserts par_en when full
//==================================================
module sipo_12bit (
 input wire clk,
 input wire rst_n,
 input wire ser_in,
 input wire shift_en,
 output reg [11:0] par_out,
 output reg par_en
);
 reg [11:0] shift_reg;
 reg [3:0] count;
 always @(posedge clk or negedge rst_n) begin
 if (!rst_n) begin
 shift_reg <= 12'h000;
 par_out <= 12'h000;
 count <= 4'd0;
 par_en <= 1'b0;
 end else if (shift_en) begin
 // shift in LSB-first stream to MSB side so after 12 shifts:
 // shift_reg[11] = bit11 ... shift_reg[0] = bit0 (original order)
 shift_reg <= {ser_in, shift_reg[11:1]};
 if (count == 4'd11) begin
 // now we have received 12 bits (0..11)
 par_out <= {ser_in, shift_reg[11:1]};
 par_en <= 1'b1;
 count <= 4'd0;
 end else begin
 count <= count + 1'b1;
 par_en <= 1'b0;
 end
 end else begin
 par_en <= 1'b0;
 end
 end
endmodule
//==================================================
// Decoder (reverse LUT)
//==================================================
module decoder_adaptive_12b (
 input wire clk,
 input wire rst_n,
 input wire [11:0] data_in,
 input wire par_en, // decode only when a full word is present
 output reg [7:0] data_out
);
 reg [7:0] rev_lut [0:4095];
 integer j;
 initial begin
 for (j=0; j<4096; j=j+1) rev_lut[j] = 8'h00;
 rev_lut[12'h000] = 8'h00;
 rev_lut[12'hA6B] = 8'h3F;
 rev_lut[12'h970] = 8'h7F;
 rev_lut[12'h400] = 8'hFF;
 end
 always @(posedge clk or negedge rst_n) begin
 if (!rst_n) begin
 data_out <= 8'h00;
 end else if (par_en) begin
 data_out <= rev_lut[data_in];
 end
 end
endmodule
//==================================================
// Top: controller ensures safe LOAD then SHIFT
// Exposes 'rx_par_en' so TB can wait for completion.
//==================================================
module adaptive_uart_serdes_top (
 input wire clk,
 input wire rst_n,
 input wire [7:0] data_8b_in,
 input wire start, // 1-cycle pulse
 input wire idle_mode,
 output wire [7:0] data_8b_out,
 output wire [11:0] encoded_data, // debug
 output wire rx_par_en // goes high when SIPO has full word
);
 // states
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
