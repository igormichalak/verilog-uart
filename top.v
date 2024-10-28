module uart_peripheral(
    input  uart_rx,
    output uart_tx,
    output clk_out
);

    wire clk;

    SB_HFOSC #(
        .CLKHF_DIV("0b11")
    ) hfosc_inst (
        .CLKHFEN(1'b1),
        .CLKHFPU(1'b1),
        .CLKHF(clk)
    );

    SB_GB clk_glob_buf (
        .USER_SIGNAL_TO_GLOBAL_BUFFER (clk),
        .GLOBAL_BUFFER_OUTPUT (clk_out)
    );

endmodule

