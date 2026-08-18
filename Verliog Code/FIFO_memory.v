//=============================================================================
// Module: FIFO_memory — Dual-Port RAM
//=============================================================================
// Purpose: A simple dual-port memory array to store FIFO data.
//          - Write is synchronous (requires wclk and wclk_en).
//          - Read is asynchronous (rdata reflects mem[raddr] combinationally).
//            (Note: Since rptr is already synchronized to rclk, async read is safe)
//
// Parameters: DATA_SIZE — Width of data bus
//             ADDR_SIZE — Width of address bus (determines depth: 2^ADDR_SIZE)
//=============================================================================

module FIFO_memory #(parameter DATA_SIZE = 8, parameter ADDR_SIZE = 4)(
    output [DATA_SIZE-1:0] rdata,        // Read data output
    input  [DATA_SIZE-1:0] wdata,        // Write data input
    input  [ADDR_SIZE-1:0] waddr, raddr, // Write & read addresses
    input                  wclk_en,      // Write enable (winc)
    input                  wfull,        // Write full flag
    input                  wclk          // Write clock
);

    localparam DEPTH = 1 << ADDR_SIZE;
    reg [DATA_SIZE-1:0] mem [0:DEPTH-1];

    assign rdata = mem[raddr];

    always @(posedge wclk) begin
        if (wclk_en && !wfull) 
            mem[waddr] <= wdata;
    end

endmodule