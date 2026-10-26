`timescale 1ns/1ps

`include "typedefs.sv"
`include "sync.sv"
`include "edge_det.sv"
`include "clk_divider.sv"
`include "I2C_master.sv"
`include "apb_i2c_controller.sv"
`include "top.sv"

module tb_top;

  // Clock & Reset
  logic clk;
  logic rst;

  // APB Bus Signals
  logic        apb_psel;
  logic [31:0] apb_paddr;
  logic [31:0] apb_pwdata;
  logic        apb_pwrite;
  logic        apb_penable;
  logic        apb_pready;
  logic        apb_slverr;
  logic [31:0] apb_prdata;

  logic interrupt;

  wire scl;
  wire sda;

  logic scl_o, scl_oen, scl_i;
  logic sda_o, sda_oen, sda_i;

  pullup(scl);
  pullup(sda);

  assign scl   = scl_oen ? scl_o : 1'bz;
  assign scl_i = scl;

  assign sda   = sda_oen ? sda_o : 1'bz;
  assign sda_i = sda;

  localparam [31:0] ADDR_PRERLO = 32'h00;
  localparam [31:0] ADDR_PRERHI = 32'h04;
  localparam [31:0] ADDR_CTR    = 32'h08;
  localparam [31:0] ADDR_TXR    = 32'h0C;
  localparam [31:0] ADDR_CR     = 32'h10;
  localparam [31:0] ADDR_SR     = 32'h14;

  // DUT Instantiation
  top dut (
    .clk        (clk),
    .rst        (rst),
    .apb_psel   (apb_psel),
    .apb_paddr  (apb_paddr),
    .apb_pwdata (apb_pwdata),
    .apb_pwrite (apb_pwrite),
    .apb_penable(apb_penable),
    .apb_pready (apb_pready),
    .apb_slverr (apb_slverr),
    .apb_prdata (apb_prdata),
    .interrupt  (interrupt),
    .scl_i      (scl_i),
    .scl_o      (scl_o),
    .scl_oen    (scl_oen),
    .sda_i      (sda_i),
    .sda_o      (sda_o),
    .sda_oen    (sda_oen)
  );

  always #10 clk = ~clk;


  task apb_write(input logic [31:0] addr, input logic [7:0] data);
    @(posedge clk);
    apb_psel    <= 1'b1;
    apb_pwrite  <= 1'b1;
    apb_paddr   <= addr;
    apb_pwdata  <= {24'b0, data};
    apb_penable <= 1'b0;
    @(posedge clk);
    apb_penable <= 1'b1;
    wait(apb_pready);
    @(posedge clk);
    apb_psel    <= 1'b0;
    apb_penable <= 1'b0;
    apb_pwrite  <= 1'b0;
  endtask

  task apb_read(input logic [31:0] addr, output logic [7:0] data);
    @(posedge clk);
    apb_psel    <= 1'b1;
    apb_pwrite  <= 1'b0;
    apb_paddr   <= addr;
    apb_penable <= 1'b0;
    @(posedge clk);
    apb_penable <= 1'b1;
    wait(apb_pready);
    data = apb_prdata[7:0];
    @(posedge clk);
    apb_psel    <= 1'b0;
    apb_penable <= 1'b0;
  endtask

  task wait_for_interrupt();
    $display("[TB] Waiting for transaction completion (Interrupt / SR[0])...");
    wait(interrupt == 1'b1);
    $display("[TB] Interrupt Received!");
    apb_write(ADDR_SR, 8'h01); // Clear IF
  endtask

  logic sda_slave_drive;
  assign sda = sda_slave_drive ? 1'bz : 1'b0;

  initial sda_slave_drive = 1'b1;

  always begin
    logic [7:0] rx_byte;
    logic [7:0] tx_data_payload;
    integer i;

    @(negedge sda);
    if (scl == 1'b1) begin
      $display("\n[I2C SLAVE] START condition detected");

      for (i = 7; i >= 0; i--) begin
        @(posedge scl);
        rx_byte[i] = sda;
      end

      if (rx_byte[7:1] == 7'h50) begin
        $display("[I2C SLAVE] Address matched (7'h50), R/W = %0b", rx_byte[0]);

        @(negedge scl);
        sda_slave_drive <= 1'b0;
        @(negedge scl);
        sda_slave_drive <= 1'b1;

        if (rx_byte[0] == 1'b0) begin
   
          for (i = 7; i >= 0; i--) begin
            @(posedge scl);
            rx_byte[i] = sda;
          end
          $display("[I2C SLAVE] Received Data Byte: 0x%0h", rx_byte);

          @(negedge scl);
          sda_slave_drive <= 1'b0;
          @(negedge scl);
          sda_slave_drive <= 1'b1;

        end else begin
          
          tx_data_payload = 8'hA5;
          for (i = 7; i >= 0; i--) begin
            sda_slave_drive <= tx_data_payload[i];
            @(negedge scl);
          end
          sda_slave_drive <= 1'b1; 
          
          @(posedge scl);
          $display("[I2C SLAVE] Master ACK/NACK bit sampled: %0b", sda);
        end
      end
    end
  end

  
  initial begin
    logic [7:0] read_val;

    clk         = 0;
    rst         = 1;
    apb_psel    = 0;
    apb_penable = 0;
    apb_pwrite  = 0;
    apb_paddr   = 0;
    apb_pwdata  = 0;

    #100;
    rst = 0;
    #40;

    $display("       STARTING APB I2C CONTROLLER TEST           ");

    apb_write(ADDR_PRERLO, 8'h08);
    apb_write(ADDR_PRERHI, 8'h00);

    apb_write(ADDR_CTR, 8'h40);
    
    $display("\n---> TEST 1: Master Write Transmit (Addr: 0x50)");
    apb_write(ADDR_TXR, 8'hA0); 
    apb_write(ADDR_CR, 8'hC0);  
    wait_for_interrupt();

    apb_read(ADDR_SR, read_val);
    if (read_val[7] == 1'b0)
      $display("[TB SUCCESS] Slave ACKed Write transaction!");
    else
      $error("[TB ERROR] Slave NACKed Write transaction!");

    #200;

    $display("\n---> TEST 2: Master Read Receive (Expect 0xA5)");
    apb_write(ADDR_TXR, 8'hA1);
    apb_write(ADDR_CR, 8'hC8); 
    wait_for_interrupt();

    apb_read(ADDR_TXR, read_val);
    $display("[TB] Data read from RXR Register: 0x%0h", read_val);

    if (read_val == 8'hA5) begin
      $display("[TB SUCCESS] Read payload matched 0xA5!");
    end else begin
      $error("[TB ERROR] Mismatch! Expected 0xA5, got 0x%0h", read_val);
    end

    #500;
    $display("          ALL TESTS COMPLETED SUCCESSFULLY        ");
    $finish;
  end

endmodule
