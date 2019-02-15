module uart_to_wb (
//CLOCK SIGNALS
input CLK,
//WB SIGNALS
input  [15:0] Dat_slave_io_lbus,
output reg [15:0] Adr_slave_i_lbus,
input Ack_slave_o_lbus,
//output Cyc_slave_i_lbus_,
output reg Stb_slave_i_lbus_,
//output Sel_slave_i_lbus_,
output reg We_slave_i_lbus_,
//SIGNALS FROM UART TX RX
input [7:0] uart_in_data,
input rxIdleOUT,
output reg [7:0] uart_out_data,
output txLoadIN,
//RESET
input RESET
);

//INTERNSL REGS
reg rxIdleOUT_reg_0=1'b0;
reg rxIdleOUT_reg_1=1'b0;
wire rxIdleOUT_strobe;

//assign Dat_slave_io_lbus_ = (We_slave_i_lbus_==1'b0)?Dat_slave_io_lbus:16'bz;

wire [15:0] Dat_slave_io_lbus_;

always @ (posedge CLK) begin
	if (RESET) begin
		rxIdleOUT_reg_0 <= 1'b0;
		rxIdleOUT_reg_1 <= 1'b0;
	end else if(~RESET) begin
		rxIdleOUT_reg_0 <= rxIdleOUT;
		rxIdleOUT_reg_1 <= rxIdleOUT_reg_0;
end
end

assign rxIdleOUT_strobe = rxIdleOUT && ~rxIdleOUT_reg_1;

always @ (posedge CLK) begin
	if (RESET) begin
		Adr_slave_i_lbus  <= 16'b0;
		Stb_slave_i_lbus_ <= 1'b0;
		We_slave_i_lbus_  <= 1'b0;
	end else if (rxIdleOUT_strobe) begin
		Adr_slave_i_lbus  <= {uart_in_data, 8'b0};
		Stb_slave_i_lbus_ <= 1'b1;
		We_slave_i_lbus_  <= 1'b0;
	end else if (Ack_slave_o_lbus==1'b1) begin
		Stb_slave_i_lbus_ <= 1'b0;
		Adr_slave_i_lbus  <= 16'b0;
		We_slave_i_lbus_  <= 1'b0;
	end
end

//assign We_slave_i_lbus_ = (uart_in_data[0] == 1'b1)?1'b1:1'b0;

//assign Dat_slave_io_lbus_ = (We_slave_i_lbus_==1'b0)?Dat_slave_io_lbus:16'bz;

always @ (posedge Ack_slave_o_lbus) begin
if (RESET)
uart_out_data <= 8'b0;
else 
uart_out_data <= Dat_slave_io_lbus [8:1];
end

assign txLoadIN = Ack_slave_o_lbus;

endmodule

