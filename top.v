module uart_peripheral(
    input  uart_rx,
    output uart_tx,
    output clk_out
);

    wire clk_12mhz;
    wire clk_9600hz;

    SB_HFOSC #(
        .CLKHF_DIV("0b10")
    ) hfosc_inst (
        .CLKHFEN(1'b1),
        .CLKHFPU(1'b1),
        .CLKHF(clk_12mhz)
    );

    SB_GB clk_glob_buf (
        .USER_SIGNAL_TO_GLOBAL_BUFFER (clk_9600hz),
        .GLOBAL_BUFFER_OUTPUT (clk_out)
    );

    reg [9:0] clk_counter;
    reg clk_state;

    always @(posedge clk_12mhz) begin
        if (clk_counter >= 10'd624) begin
            clk_counter <= 10'd0;
            clk_state <= ~clk_state;
        end else begin
            clk_counter <= clk_counter + 1;
        end
    end

    assign clk_9600hz = clk_state;

endmodule

