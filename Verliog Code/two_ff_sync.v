//=============================================================================
// Module: two_ff_sync — 2-Stage Flip-Flop Synchronizer
//=============================================================================
// Purpose: Safely transfer a multi-bit Gray-coded signal across clock domains
//          by passing it through two sequential flip-flops, allowing any
//          metastable state in FF1 a full clock period to resolve before
//          FF2 samples it. Achieves MTBF of centuries in modern CMOS.
//
// Usage:   Instantiated twice in the top-level FIFO:
//            sync_r2w: rptr (Gray) → wclk domain → wq2_rptr
//            sync_w2r: wptr (Gray) → rclk domain → rq2_wptr
//
// Parameter: SIZE — width of the bus being synchronized (ADDR_SIZE + 1)
//=============================================================================

module two_ff_sync #(parameter SIZE = 4)(
    output reg [SIZE-1:0] q2,       // Synchronized output (safe to use)
    input      [SIZE-1:0] din,      // Input from foreign clock domain
    input                 clk,      // Destination clock
    input                 rst_n     // Active-low asynchronous reset
);

    reg [SIZE-1:0] q1;              // Intermediate register (may go metastable)

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            {q2, q1} <= 0;             // Clear both stages on reset
        else
            {q2, q1} <= {q1, din};     // Shift pipeline: din → q1 → q2
    end

endmodule
