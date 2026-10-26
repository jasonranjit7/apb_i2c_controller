`include "synchroniser.sv"
module edge_det (
  input  logic clk,
  input  logic rst,
  input  logic sig,
  output logic sync_sig,
  output logic rising,
  output logic falling
);
  logic [1:0] sync_reg;

  sync s1 (
    .clk(clk),
    .rst(rst),
    .d(sig),
    .q2(sync_reg[0]),
    .q(sync_reg[1])
  );

  assign rising   = (sync_reg == 2'b01);
  assign falling  = (sync_reg == 2'b10);
  assign sync_sig = sync_reg[0];
endmodule
