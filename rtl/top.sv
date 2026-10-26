`include "apb_i2c_controller.sv"
module top (
  input  logic        clk,
  input  logic        rst,

  // APB Slave Bus Interface
  input  logic        apb_psel,
  input  logic [31:0] apb_paddr,
  input  logic [31:0] apb_pwdata,
  input  logic        apb_pwrite,
  input  logic        apb_penable,
  output logic        apb_pready,
  output logic        apb_slverr,
  output logic [31:0] apb_prdata,

  output logic        interrupt,

  // I2C Pad Interface
  input  logic        scl_i,
  output logic        scl_o,
  output logic        scl_oen,

  input  logic        sda_i,
  output logic        sda_o,
  output logic        sda_oen
);

  apb_i2c_controller apb_i2c (
      .clk         (clk),
      .rst         (rst),
      .apb_psel    (apb_psel),
      .apb_paddr   (apb_paddr),
      .apb_pwdata  (apb_pwdata),
      .apb_pwrite  (apb_pwrite),
      .apb_penable (apb_penable),
      .apb_pready  (apb_pready),
      .apb_slverr  (apb_slverr),
      .apb_prdata  (apb_prdata),
      .scl_pad_i   (scl_i),
      .scl_pad_o   (scl_o),
      .scl_padoen_o(scl_oen),
      .sda_pad_i   (sda_i),
      .sda_pad_o   (sda_o),
      .sda_padoen_o(sda_oen),
      .interrupt   (interrupt)
  );

endmodule
