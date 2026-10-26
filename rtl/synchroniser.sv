`ifndef SYNCHRONISER_SV
`define SYNCHRONISER_SV
module sync (
  input  logic clk,
  input  logic rst,
  input  logic d,
  output logic q2,
  output logic q
);
  logic q1;

  always_ff @(posedge clk or posedge rst) begin
    if (rst) begin
      q1 <= 1'b1;
      q2 <= 1'b1;
      q  <= 1'b1;
    end else begin
      q1 <= d;
      q2 <= q1;
      q  <= q2;
    end
  end
endmodule

`endif 
