module uart_peripheral(
    input      reset,
    input      uart_rx,
    output reg uart_tx,
    output     clk_out
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

    localparam tx_idle  = 2'b00;
    localparam tx_start = 2'b01;
    localparam tx_data  = 2'b10;
    localparam tx_stop  = 2'b11;

    reg [1:0] tx_state;
    reg [2:0] bit_counter;

    reg [7:0] tx_data_reg;
    reg       tx_sig_transmit;
    reg       tx_sig_done;

    always @(negedge reset) begin
        tx_data_reg <= 8'h77; // ASCII 'w' (0x77)
        tx_sig_transmit <= 1'b1;
        tx_sig_done <= 1'b0;
    end

    always @(posedge clk_9600hz or negedge reset) begin
        if (!reset) begin
            tx_state <= tx_idle;
            bit_counter <= 3'd0;
        end else begin
            case (tx_state)
                tx_idle : begin
                    if (tx_sig_transmit && !tx_sig_done) begin
                        tx_state <= tx_start;
                        bit_counter <= 3'd0;
                    end
                end
                tx_start : begin
                    tx_state <= tx_data;
                end
                tx_data : begin
                    if (bit_counter == 3'd7) begin
                        tx_state <= tx_stop;
                    end else begin
                        bit_counter <= bit_counter + 1;
                    end
                end
                tx_stop : begin
                    tx_state <= tx_idle;
                    tx_sig_done <= 1'b1;
                end
            endcase
        end
    end

    always @(posedge clk_9600hz or negedge reset) begin
        if (!reset) begin
            uart_tx <= 1'b1;
        end else begin
            case (tx_state)
                tx_idle : begin
                    uart_tx <= 1'b1;
                end
                tx_start : begin
                    uart_tx <= 1'b0;
                end
                tx_data : begin
                    uart_tx <= tx_data_reg[bit_counter];
                end
                tx_stop : begin
                    uart_tx <= 1'b1;
                end
            endcase
        end
    end

endmodule

