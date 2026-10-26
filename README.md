APB I2C Master Controller IP

A fully synthesizable SystemVerilog IP core implementing an AMBA APB3 Slave to I2C Master Controller. 
Designed for embedded System-on-Chip (SoC) integration, this core enables a host processor to communicate with external I2C slave devices via standard software register accesses.

Features
  AMBA APB3 Slave Bus Interface: 32-bit APB slave interface with zero-wait-state transfers (pready = 1).

  I2C Master FSM: Supports Standard-mode and Fast-mode I2C transfers (Start, Repeated Start, Address, Data, ACK/NACK, and Stop framing).

  Programmable Clock Prescaler: 16-bit configurable clock divider (PRERhi/PRERlo) generating I2C SCL frequencies from any system clock.

  Clock Stretching Support: Hardware monitoring of the SCL line allows slow slave devices to hold SCL low without corrupting state transitions.

  Open-Drain Bus IO: Standard active-high output-enable (oen) controls for external tri-state pad buffers.

  Interrupt Generation: Configurable interrupt enable bit with a Write-1-to-Clear (W1C) status flag.

  2-Stage Synchronization: Full metastability protection on asynchronous incoming SCL and SDA signals.
