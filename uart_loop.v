module UART_Loop (
    input  i_Reset,
    input  i_UART_Rx,
    output o_UART_Tx
);

    wire w_Clk_12MHz;
    wire w_Clk_10kHz;

    SB_HFOSC #(
        .CLKHF_DIV("0b10")
    ) HFOSC_Instance (
        .CLKHFEN(1'b1),
        .CLKHFPU(1'b1),
        .CLKHF(w_Clk_12MHz)
    );

    SB_LFOSC LFOSC_Instance (
        .CLKLFEN(1'b1),
        .CLKLFPU(1'b1),
        .CLKLF(w_Clk_10kHz)
    );

    wire w_Rx_Ready;
    wire w_Tx_Ready;

    reg [7:0] r_Data_In;
    reg [7:0] r_Data_Out;

    reg r_Rd_En;
    reg r_Wr_En;

    UART_Transceiver UT_Instance (
        .i_Reset     (i_Reset),
        .i_Clk_12MHz (w_Clk_12MHz),
        .i_Rx        (i_UART_Rx),
        .o_Tx        (o_UART_Tx),
        .i_Data_In   (r_Data_In),
        .o_Data_Out  (r_Data_Out),
        .i_Rd_En     (r_Rd_En),
        .i_Wr_En     (r_Wr_En),
        .o_Rx_Ready  (w_Rx_Ready),
        .o_Tx_Ready  (w_Tx_Ready)
    );

    localparam S_IDLE    = 2'b00;
    localparam S_WAITING = 2'b01;
    localparam S_SENDING = 2'b10;
    
    reg [1:0] r_State;
    reg [11:0] r_Wait_Counter;

    always @(posedge w_Clk_10kHz or posedge i_Reset) begin
        if (i_Reset) begin
            r_State <= S_IDLE;
            r_Wait_Counter <= 12'd0;
            r_Data_In <= 8'h00;
            r_Wr_En <= 1'b0;
        end else begin
            case (r_State)
                S_IDLE : begin
                    if (w_Tx_Ready) begin
                        r_State <= S_SENDING;
                        r_Data_In <= 8'h57;
                        r_Wr_En <= 1'b1;
                    end
                end
                S_SENDING : begin
                    if (w_Tx_Ready) begin
                        r_State <= S_WAITING;
                        r_Wait_Counter <= 12'd0;
                    end
                end
                S_WAITING : begin
                    if (r_Wait_Counter == 12'hFFF) begin
                        r_State <= S_IDLE;
                    end else begin
                        r_Wait_Counter <= r_Wait_Counter + 1;
                    end
                end
            endcase
        end
    end

endmodule
