`include "typedefs.sv"
`include "i2c_master.sv"

module apb_i2c_controller (
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

    // Control Pins
    input  logic        scl_pad_i,    
    output logic        scl_pad_o,    
    output logic        scl_padoen_o, 
    input  logic        sda_pad_i,    
    output logic        sda_pad_o,    
    output logic        sda_padoen_o, 

    output logic        interrupt
);

  // Configuration and Status Registers
  logic [7:0] PRERlo, PRERhi, CTR, TXR, RXR, CR, SR;
  logic busy_wire, cmd_done_wire, rx_ack_wire;
  logic [7:0] rx_data_wire;
  logic sda_m_out, scl_m_out;

  assign apb_pready = 1'b1;
  assign apb_slverr = 1'b0;

  wire apb_write = apb_psel && apb_penable && apb_pwrite;
  wire apb_read  = apb_psel && apb_penable && !apb_pwrite;

  assign interrupt = CTR[6] && SR[0]; // CTR[6] = IE, SR[0] = IF

  // APB Register Writes & Data Latching
  always_ff @(posedge clk or posedge rst) begin
    if (rst) begin
      PRERhi <= 8'h00;
      PRERlo <= 8'h00;
      CTR    <= 8'h00;
      TXR    <= 8'h00;
      RXR    <= 8'h00;
      CR     <= 8'h00;
      SR     <= 8'h00;
    end else begin
      if (cmd_done_wire) begin
        SR[0] <= 1'b1;          // Set Interrupt Flag
        SR[7] <= rx_ack_wire;    // Latch RxACK Status (0=ACK, 1=NACK)
        RXR   <= rx_data_wire;   // Latch Received Data Byte into RXR
        CR    <= 8'h00;          // Self-clear CR command
      end

      if (apb_write) begin
        case (apb_paddr[4:2])
          3'b000: PRERlo <= apb_pwdata[7:0];
          3'b001: PRERhi <= apb_pwdata[7:0];
          3'b010: CTR    <= apb_pwdata[7:0];
          3'b011: TXR    <= apb_pwdata[7:0];
          3'b100: CR     <= apb_pwdata[7:0];
          3'b101: SR[0]  <= SR[0] & ~apb_pwdata[0]; // Write-1-to-clear IF
          default: ;
        endcase
      end
    end
  end

  // APB Register Read Interface
  always_comb begin
    apb_prdata = 32'b0;
    if (apb_read) begin
      case (apb_paddr[4:2])
        3'b000: apb_prdata = {24'b0, PRERlo};
        3'b001: apb_prdata = {24'b0, PRERhi};
        3'b010: apb_prdata = {24'b0, CTR};
        3'b011: apb_prdata = {24'b0, RXR}; // Returns latched RXR data
        3 me00: apb_prdata = {24'b0, CR};
        3'b101: apb_prdata = {24'b0, SR[7], 5'b0, busy_wire, SR[0]};
        default: apb_prdata = 32'b0;
      endcase
    end
  end

  assign scl_pad_o    = 1'b0;
  assign scl_padoen_o = ~scl_m_out;

  assign sda_pad_o    = 1'b0;
  assign sda_padoen_o = ~sda_m_out;

  // I2C Master Core Instantiation
  I2C_master u_i2c_master (
      .clk     (clk),
      .rst     (rst),
      .rw      (TXR[0]),
      .addr    (TXR[7:1]),
      .data    (TXR),
      .start   (CR[7]),
      .stop    (CR[6]),
      .ack_bit (CR[3]),
      .prescale({PRERhi, PRERlo}),
      .m_data  (rx_data_wire),
      .busy    (busy_wire),
      .cmd_done(cmd_done_wire),
      .rx_ack  (rx_ack_wire),
      .SDA     (sda_pad_i),
      .SCL     (scl_pad_i),
      .SDA_m   (sda_m_out),
      .SCL_m   (scl_m_out)
  );

endmodule
