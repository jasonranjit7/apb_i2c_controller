`ifndef TYPEDEFS_SV
`define TYPEDEFS_SV

package typedefs;
  typedef enum logic [2:0] {
    IDLE     = 3'b000,
    START    = 3'b001,
    ADDR     = 3'b010,
    ACK_ADDR = 3'b011,
    DATA     = 3'b100,
    ACK_DATA = 3'b101,
    STOP     = 3'b110
  } state_t;
endpackage : typedefs

`endif // TYPEDEFS_SV
