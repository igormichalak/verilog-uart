module UART_Transceiver (
    input i_Reset,
    input i_Clk_12MHz,
    input i_Rx,
    output o_Tx,
    input [7:0] i_Data_In,
    output reg [7:0] o_Data_Out,
    input i_Rd_En,
    input i_Wr_En,
    output o_Rx_Ready,
    output o_Tx_Ready
);

    wire w_Clk_9600Hz;

    reg [15:0] r_Clk_Counter;
    reg r_Clk_State;

    always @(posedge i_Clk_12MHz or posedge i_Reset) begin
        if (i_Reset) begin
            r_Clk_Counter <= 16'd0;
            r_Clk_State <= 1'b0;
        end else begin
            if (r_Clk_Counter == 16'd624) begin
                r_Clk_Counter <= 16'd0;
                r_Clk_State <= ~r_Clk_State;
            end else begin
                r_Clk_Counter <= r_Clk_Counter + 1;
            end
        end
    end

    assign w_Clk_9600Hz = r_Clk_State;

    reg r_Rx_Ready;
    reg r_Tx_Ready;
    assign o_Rx_Ready = r_Rx_Ready;
    assign o_Tx_Ready = r_Tx_Ready;

    localparam TX_IDLE  = 2'b00;
    localparam TX_START = 2'b01;
    localparam TX_DATA  = 2'b10;
    localparam TX_STOP  = 2'b11;

    reg [1:0] r_Tx_State;
    reg [7:0] r_Tx_Buf;
    reg [2:0] r_Tx_Buf_Ptr;

    always @(posedge w_Clk_9600Hz or posedge i_Reset) begin
        if (i_Reset) begin
            r_Tx_State <= TX_IDLE;
            r_Tx_Buf <= 8'h00;
            r_Tx_Buf_Ptr <= 3'b000;
            r_Tx_Ready <= 1'b1;
        end else begin
            case (r_Tx_State)
                TX_IDLE : begin
                    if (i_Wr_En) begin
                        r_Tx_State <= TX_START;
                        r_Tx_Buf <= i_Data_In;
                        r_Tx_Ready <= 1'b0;
                    end
                end
                TX_START : begin
                    r_Tx_State <= TX_DATA;
                    r_Tx_Buf_Ptr <= 3'b000;
                end
                TX_DATA : begin
                    if (r_Tx_Buf_Ptr == 3'b111) begin
                        r_Tx_State <= TX_STOP;
                    end else begin
                        r_Tx_Buf_Ptr <= r_Tx_Buf_Ptr + 1;
                    end
                end
                TX_STOP : begin
                    r_Tx_State <= TX_IDLE;
                    r_Tx_Ready <= 1'b1;
                end
            endcase
        end
    end

    assign o_Tx =
        r_Tx_State == TX_IDLE
            ? 1'b1 :
        r_Tx_State == TX_START
            ? 1'b0 :
        r_Tx_State == TX_DATA
            ? r_Tx_Buf[r_Tx_Buf_Ptr] :
        // TX_STOP
              1'b1;

endmodule
