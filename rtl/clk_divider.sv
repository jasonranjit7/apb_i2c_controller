module clk_divider #(
  parameter TICK_DIV = 50
) (
  input  logic        clk,
  input  logic        rst,
  input  logic        en,
  input  logic [15:0] prescale,
  input  logic        SCL_s,
  output logic        SCL_m
);
  logic [15:0] count;

  always_ff @(posedge clk or posedge rst) begin
    if (rst || !en) begin
      count <= '0;
      SCL_m <= 1'b1;
    end else begin
      if (SCL_m && !SCL_s) begin
        count <= count; // Clock stretching: hold counter while slave pulls SCL low
      end else if (count >= prescale) begin
        count <= '0;
        SCL_m <= ~SCL_m;
      end else begin
        count <= count + 1'b1;
      end
    end
  end
endmodule
