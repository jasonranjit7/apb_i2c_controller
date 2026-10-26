`include "typedefs.sv"
`include "synchroniser.sv"
`include "edge_detector.sv"
`include "clk_divider.sv"
module I2C_master (
  input  logic        clk,
  input  logic        rst,
  input  logic        rw,
  input  logic [6:0]  addr,
  input  logic [7:0]  data,
  input  logic        start,
  input  logic        stop,
  input  logic        ack_bit,
  output logic [7:0]  m_data,
  input  logic [15:0] prescale,
  input  logic        SDA,
  input  logic        SCL,
  output logic        SDA_m,
  output logic        SCL_m,
  output logic        busy,
  output logic        cmd_done,
  output logic        rx_ack
);
  import typedefs::*;

  logic [7:0] addr_frame, s_data;
  logic SCL_en, SCL_r, SCL_f;
  logic SDA_sync, SCL_sync;
  logic [3:0] bit_count;
  state_t state, nxt_state;

  edge_det SCL_det (
    .clk(clk),
    .rst(rst),
    .sig(SCL),
    .sync_sig(SCL_sync),
    .rising(SCL_r),
    .falling(SCL_f)
  );

  sync sda_sync_inst (
    .clk(clk),
    .rst(rst),
    .d(SDA),
    .q2(SDA_sync),
    .q()
  );

  clk_divider clk_div (
    .clk(clk),
    .rst(rst),
    .en(SCL_en),
    .prescale(prescale),
    .SCL_s(SCL_sync),
    .SCL_m(SCL_m)
  );

  always_ff @(posedge clk or posedge rst) begin
    if (rst)
      state <= IDLE;
    else
      state <= nxt_state;
  end

  always_ff @(posedge clk or posedge rst) begin
    if (rst) begin
      bit_count <= '0;
    end else begin
      if (state == IDLE || state == START || state == ACK_ADDR || state == ACK_DATA) begin
        bit_count <= '0;
      end else if (SCL_f && (state == ADDR || state == DATA)) begin
        bit_count <= bit_count + 1'b1;
      end
    end
  end

  // Latch Slave ACK on SCL rising edge
  always_ff @(posedge clk or posedge rst) begin
    if (rst) begin
      rx_ack <= 1'b0;
    end else if (SCL_r && (state == ACK_ADDR || (state == ACK_DATA && !rw))) begin
      rx_ack <= SDA_sync;
    end
  end

  always_comb begin
    nxt_state = state;
    SCL_en    = 1'b1;

    case (state)
      IDLE: begin
        SCL_en = 1'b0;
        if (start)
          nxt_state = START;
      end

      START: begin
        if (SCL_f)
          nxt_state = ADDR;
      end

      ADDR: begin
        if (SCL_f && bit_count == 4'd7)
          nxt_state = ACK_ADDR;
      end

      ACK_ADDR: begin
        if (SCL_f) begin
          if (rx_ack == 1'b0)
            nxt_state = DATA;
          else
            nxt_state = STOP;
        end
      end

      DATA: begin
        if (SCL_f && bit_count == 4'd7)
          nxt_state = ACK_DATA;
      end

      ACK_DATA: begin
        if (SCL_f) begin
          if (stop || rx_ack == 1'b1)
            nxt_state = STOP;
          else if (start)
            nxt_state = START;
          else
            nxt_state = STOP;
        end
      end

      STOP: begin
        if (SCL_f)
          nxt_state = IDLE;
      end

      default: nxt_state = IDLE;
    endcase
  end

  // Receive Data Shift Register
  always_ff @(posedge clk or posedge rst) begin
    if (rst) begin
      m_data <= '0;
    end else if (rw && state == DATA && SCL_r) begin
      m_data <= {m_data[6:0], SDA_sync};
    end
  end

  // Transmit Data Shift Register
  always_ff @(posedge clk or posedge rst) begin
    if (rst) begin
      s_data <= '0;
    end else if (state == START) begin
      s_data <= data;
    end else if (!rw && state == DATA && SCL_f) begin
      s_data <= {s_data[6:0], 1'b0};
    end
  end

  // Address Shift Register
  always_ff @(posedge clk or posedge rst) begin
    if (rst) begin
      addr_frame <= '0;
    end else if (state == START) begin
      addr_frame <= {addr, rw};
    end else if (state == ADDR && SCL_f) begin
      addr_frame <= {addr_frame[6:0], 1'b0};
    end
  end

  always_comb begin
    SDA_m    = 1'b1;
    cmd_done = 1'b0;

    case (state)
      IDLE:     SDA_m = 1'b1;
      START:    SDA_m = 1'b0;
      ADDR:     SDA_m = addr_frame[7];
      ACK_ADDR: SDA_m = 1'b1;
      DATA:     SDA_m = rw ? 1'b1 : s_data[7];
      ACK_DATA: begin
        SDA_m = rw ? ack_bit : 1'b1;
        if (SCL_f)
          cmd_done = 1'b1;
      end
      STOP: begin
        SDA_m = SCL_sync ? 1'b1 : 1'b0;
      end
      default:  SDA_m = 1'b1;
    endcase
  end

  assign busy = (state != IDLE);
endmodule
