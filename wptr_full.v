//=============================================================================
// Module: wptr_full — Write Pointer & Full Flag Generator
//=============================================================================
// Purpose: Handles write domain logic.
//          - Maintains binary write pointer for memory addressing.
//          - Maintains Gray-coded write pointer to cross to read domain.
//          - Generates 'wfull' flag by comparing Gray write pointer with
//            the synchronized Gray read pointer.
//          - NEW: Generates 'walmost_full' flag based on threshold.
//=============================================================================

module wptr_full #(parameter ADDR_SIZE = 4, parameter ALMOST_FULL_THRESH = 2)(
    output reg                  wfull,
    output reg                  walmost_full,
    output [ADDR_SIZE-1:0]      waddr,
    output reg [ADDR_SIZE:0]    wptr,
    input  [ADDR_SIZE:0]        wq2_rptr, // Synchronized Gray read pointer
    input                       winc, wclk, wrst_n
);

    reg  [ADDR_SIZE:0] wbin;
    wire [ADDR_SIZE:0] wgray_next, wbin_next;
    wire wfull_val, walmost_full_val;
    
    // Internal wire for binary read pointer
    wire [ADDR_SIZE:0] rptr_bin;

    // Synchronous Write Pointer Updates
    always @(posedge wclk or negedge wrst_n) begin
        if (!wrst_n)
            {wbin, wptr} <= 0;
        else
            {wbin, wptr} <= {wbin_next, wgray_next};
    end

    // Binary next state & memory address
    assign waddr      = wbin[ADDR_SIZE-1:0];
    assign wbin_next  = wbin + (winc & ~wfull);
    
    // Binary to Gray conversion
    assign wgray_next = (wbin_next >> 1) ^ wbin_next;

    // Full Condition: Top 2 bits inverted, remaining bits match
    assign wfull_val = (wgray_next == {~wq2_rptr[ADDR_SIZE:ADDR_SIZE-1],
                                        wq2_rptr[ADDR_SIZE-2:0]});

    // Gray to Binary conversion for wq2_rptr (used for almost full)
    genvar i;
    generate
        for (i = 0; i <= ADDR_SIZE; i = i + 1) begin : gray_to_bin_block
            assign rptr_bin[i] = ^(wq2_rptr >> i);
        end
    endgenerate

    // Almost Full Condition
    localparam DEPTH = 1 << ADDR_SIZE;
    wire [ADDR_SIZE:0] fill_count = wbin_next - rptr_bin;
    assign walmost_full_val = (fill_count >= (DEPTH - ALMOST_FULL_THRESH));

    // Registering flags for clean outputs
    always @(posedge wclk or negedge wrst_n) begin
        if (!wrst_n) begin
            wfull        <= 1'b0;
            walmost_full <= 1'b0;
        end else begin
            wfull        <= wfull_val;
            walmost_full <= walmost_full_val;
        end
    end

endmodule