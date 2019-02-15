module top (
input uart_in,
output uart_out,
input reset_in,
input clk_in,
inout DQ,
input T_COM,
input we_active,
output CLK,
output RST,
output wire LED_0,
output wire LED_1);

wire [7:0] rxDataOUT;
wire [15:0] Adr_slave_i_lbus;
wire [15:0] Dat_slave_io_lbus;
wire [7:0] txDataIN;
wire DS1620_BUSY;
wire TEMP_OUT;
wire DATA_MKO;
//wire T_HIGH;

assign LED_0 = TEMP_OUT;
assign LED_1 = T_COM;

//assign We_slave_i_lbus_ = Adr_slave_i_lbus[12];

uart_to_wb uart_to_wb_ (
.CLK               (clk_in),
.RESET             (~reset_in),
.Adr_slave_i_lbus  (Adr_slave_i_lbus),
.Dat_slave_io_lbus (Dat_slave_io_lbus),
.Ack_slave_o_lbus  (Ack_slave_o_lbus),
.Stb_slave_i_lbus_ (Stb_slave_i_lbus_),
.We_slave_i_lbus_  (We_slave_i_lbus_),
.rxIdleOUT         (rxIdleOUT),
.uart_in_data      (rxDataOUT),
.txLoadIN          (txLoadIN),
.uart_out_data     (txDataIN),
.we_active         (we_active)
);

UART_RX UART_RX_(
.clockIN    (clk_in),
.rxIdleOUT  (rxIdleOUT),
.rxDataOUT  (rxDataOUT),
.rxIN       (uart_in),
.nRxResetIN (reset_in)
);

UART_TX UART_TX_(
.clockIN (clk_in),
.txLoadIN (txLoadIN),
.txDataIN (txDataIN),
.nTxResetIN (reset_in),
.txOUT     (uart_out)
);

assign DATA_MKO = 16'bz;

uvv_mko_top uvv_mko_top_ (
.CLK_32            (clk_in),
.RESET_MKO_        (reset_in),
.Adr_slave_i_lbus  (Adr_slave_i_lbus),
.Dat_slave_io_lbus (Dat_slave_io_lbus),
.Ack_slave_o_lbus  (Ack_slave_o_lbus),
.Stb_slave_i_lbus_ (Stb_slave_i_lbus_),
.We_slave_i_lbus_  (We_slave_i_lbus_),
.MKO_READYD_N      (5'b1),
.DQ                (DQ),
.CLK               (CLK),
.RST               (RST),
.T_COM             (T_COM),
.TEMP_OUT          (TEMP_OUT),
.DATA_MKO          (DATA_MKO)
//.DS1620_BUSY       (DS1620_BUSY)
);

endmodule