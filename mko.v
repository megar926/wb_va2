module mko
(
Dat_slave_o_lbus,
Dat_slave_io_lbus,
Adr_slave_i_lbus_reg,
We_slave_i_lbus_reg,
ack_access_reg_3,
ack_access_str,
ack_set_reg,
//MKO BUS INTERFACE
CLK_32,
RESET,
MKO_CLK,
MKO_RES_N,
MKO_STRBD_N,
MKO_SELECT_N,
MKO_RDWR_N,
MKO_RDAT0,
MKO_RDAT1,
MKO_RDAT2,
MKO_RDAT3,
MKO_RDAT4,
MKO_RDATP
);

parameter                         WB_DATA_WIDTH;//                 =16; //
parameter                         WB_ADDR_WIDTH;//                 =16; //

//MKO SELECT ADRESS
parameter                         MKO0_SET;//                      =3'b000;//h0
parameter                         MKO1_SET;//                      =3'b001;//h1
parameter                         MKO2_SET;//                      =3'b010;//h2
parameter                         MKO3_SET;//                      =3'b011;//h3
parameter                         MKO4_SET;//                      =3'b100;//h4
parameter                         MKO_INT_REG;//                   =3'b101;//h5

input                                            RESET;
input                                            CLK_32;
output       reg     [WB_DATA_WIDTH-1:0]         Dat_slave_o_lbus=16'hFFFF;
input                [WB_DATA_WIDTH-1:0]         Dat_slave_io_lbus;
input                [WB_ADDR_WIDTH-1:0]         Adr_slave_i_lbus_reg;
input                                            We_slave_i_lbus_reg;
input                                            ack_access_str;
input                                            ack_access_reg_3;
output               reg                         ack_set_reg;
//MKO interface
output              [4:0]                        MKO_CLK;
output              [4:0]                        MKO_RES_N;
output   reg        [4:0]                        MKO_STRBD_N  =5'b11111;    
output   reg        [4:0]                        MKO_SELECT_N =5'b11111;
output   reg                                     MKO_RDWR_N;
output   reg        [4:0]                        MKO_RDAT0;
output   reg        [4:0]                        MKO_RDAT1;
output   reg        [4:0]                        MKO_RDAT2;
output   reg        [4:0]                        MKO_RDAT3;
output   reg        [4:0]                        MKO_RDAT4;
output              [4:0]                        MKO_RDATP;


reg clk_16=1'b0;

reg mko_res_0=1'b0;
reg mko_res_1=1'b0;
reg mko_res_2=1'b0;
reg mko_res_3=1'b0;
reg mko_res_4=1'b0;

//DEL 2 FOR 1895VA2T
always @ (posedge CLK_32) begin
clk_16<=!clk_16; //62,5 nS
end

assign MKO_CLK[0]         =clk_16;
assign MKO_CLK[1]         =clk_16;
assign MKO_CLK[2]         =clk_16;
assign MKO_CLK[3]         =clk_16;
assign MKO_CLK[4]         =clk_16;


assign MKO_RES_N[0] = mko_res_0;
assign MKO_RES_N[1] = mko_res_1;
assign MKO_RES_N[2] = mko_res_2;
assign MKO_RES_N[3] = mko_res_3;
assign MKO_RES_N[4] = mko_res_4;

//MKO RDAT INTERNAL REGISTERS
always @ (posedge CLK_32) begin
	if (RESET==1) begin
		MKO_RDAT4<=5'b00000;
		MKO_RDAT3<=5'b00000;
		MKO_RDAT2<=5'b00000;
		MKO_RDAT1<=5'b00000;
		MKO_RDAT0<=5'b00000;
		mko_res_0<=1'b0;
		mko_res_1<=1'b0;
		mko_res_2<=1'b0;
		mko_res_3<=1'b0;
		mko_res_4<=1'b0;
	end else if (We_slave_i_lbus_reg==1 && ack_access_str==1 && Adr_slave_i_lbus_reg[15:13]==MKO_INT_REG) begin//write data to RDAT register
		case (Adr_slave_i_lbus_reg[2:0])
			MKO0_SET:   begin
                               mko_res_0<=Dat_slave_io_lbus[15];
                               {MKO_RDAT4 [0], MKO_RDAT3 [0], MKO_RDAT2 [0], MKO_RDAT1 [0], MKO_RDAT0 [0]}<=Dat_slave_io_lbus[4:0];
                        end
			MKO1_SET:   begin
                               mko_res_1<=Dat_slave_io_lbus[15];
                              {MKO_RDAT4 [1], MKO_RDAT3 [1], MKO_RDAT2 [1], MKO_RDAT1 [1], MKO_RDAT0 [1]}<=Dat_slave_io_lbus[4:0];
                        end
			MKO2_SET:   begin
                               mko_res_2<=Dat_slave_io_lbus[15];
                               {MKO_RDAT4 [2], MKO_RDAT3 [2], MKO_RDAT2 [2], MKO_RDAT1 [2], MKO_RDAT0 [2]}<=Dat_slave_io_lbus[4:0];
                        end
			MKO3_SET:   begin
                               mko_res_3<=Dat_slave_io_lbus[15];
                              {MKO_RDAT4 [3], MKO_RDAT3 [3], MKO_RDAT2 [3], MKO_RDAT1 [3], MKO_RDAT0 [3]}<=Dat_slave_io_lbus[4:0];
                        end
			MKO4_SET:   begin
                               mko_res_4<=Dat_slave_io_lbus[15];
                              {MKO_RDAT4 [4], MKO_RDAT3 [4], MKO_RDAT2 [4], MKO_RDAT1 [4], MKO_RDAT0 [4]}<=Dat_slave_io_lbus[4:0];
                        end
			default:    begin
                               mko_res_0<=mko_res_0;
                               mko_res_1<=mko_res_1;
                               mko_res_2<=mko_res_2;
                               mko_res_3<=mko_res_3;
                               mko_res_4<=mko_res_4;
                               MKO_RDAT0<=MKO_RDAT0;
                               MKO_RDAT1<=MKO_RDAT1;
                               MKO_RDAT2<=MKO_RDAT2;
                               MKO_RDAT3<=MKO_RDAT3;
                               MKO_RDAT4<=MKO_RDAT4;
                        end
		endcase
	end
end
assign MKO_RDATP [0] = ~(MKO_RDAT0 [0]^MKO_RDAT1 [0]^MKO_RDAT2 [0]^MKO_RDAT3 [0]^MKO_RDAT4 [0]);
assign MKO_RDATP [1] = ~(MKO_RDAT0 [1]^MKO_RDAT1 [1]^MKO_RDAT2 [1]^MKO_RDAT3 [1]^MKO_RDAT4 [1]);
assign MKO_RDATP [2] = ~(MKO_RDAT0 [2]^MKO_RDAT1 [2]^MKO_RDAT2 [2]^MKO_RDAT3 [2]^MKO_RDAT4 [2]);
assign MKO_RDATP [3] = ~(MKO_RDAT0 [3]^MKO_RDAT1 [3]^MKO_RDAT2 [3]^MKO_RDAT3 [3]^MKO_RDAT4 [3]);
assign MKO_RDATP [4] = ~(MKO_RDAT0 [4]^MKO_RDAT1 [4]^MKO_RDAT2 [4]^MKO_RDAT3 [4]^MKO_RDAT4 [4]);
     
always  @ (posedge CLK_32) begin
	if (RESET==1'b1) begin // || ack_access_reg_3==0) begin
		Dat_slave_o_lbus[15:0]<=16'h0000;
	end else if (We_slave_i_lbus_reg==0 && ack_access_str==1 && Adr_slave_i_lbus_reg[15:13]==MKO_INT_REG) begin//read data from RDAT and RESET register
		case (Adr_slave_i_lbus_reg[2:0])
			MKO0_SET: Dat_slave_o_lbus[15:0]<={MKO_RES_N[0] ,10'b0000000000,MKO_RDAT4 [0], MKO_RDAT3 [0], MKO_RDAT2 [0], MKO_RDAT1 [0], MKO_RDAT0 [0]};
			MKO1_SET: Dat_slave_o_lbus[15:0]<={MKO_RES_N[1] ,10'b0000000000,MKO_RDAT4 [1], MKO_RDAT3 [1], MKO_RDAT2 [1], MKO_RDAT1 [1], MKO_RDAT0 [1]};
			MKO2_SET: Dat_slave_o_lbus[15:0]<={MKO_RES_N[2] ,10'b0000000000,MKO_RDAT4 [2], MKO_RDAT3 [2], MKO_RDAT2 [2], MKO_RDAT1 [2], MKO_RDAT0 [2]};
			MKO3_SET: Dat_slave_o_lbus[15:0]<={MKO_RES_N[3] ,10'b0000000000,MKO_RDAT4 [3], MKO_RDAT3 [3], MKO_RDAT2 [3], MKO_RDAT1 [3], MKO_RDAT0 [3]};
			MKO4_SET: Dat_slave_o_lbus[15:0]<={MKO_RES_N[4] ,10'b0000000000,MKO_RDAT4 [4], MKO_RDAT3 [4], MKO_RDAT2 [4], MKO_RDAT1 [4], MKO_RDAT0 [4]};
			default : Dat_slave_o_lbus[15:0]<=16'h0000;                                      
		endcase
	end
end

always @ (posedge CLK_32) begin
	if (RESET==1 || ack_access_reg_3==0) begin
		ack_set_reg<=1'b0;
	end else if (ack_access_reg_3==1 && Adr_slave_i_lbus_reg[15:13]==MKO_INT_REG &&  (Adr_slave_i_lbus_reg[2:0]==MKO0_SET ||
                                                                                    Adr_slave_i_lbus_reg[2:0]==MKO1_SET ||
                                                                                    Adr_slave_i_lbus_reg[2:0]==MKO2_SET ||
                                                                                    Adr_slave_i_lbus_reg[2:0]==MKO3_SET ||
                                                                                    Adr_slave_i_lbus_reg[2:0]==MKO4_SET )) begin//TODO
		ack_set_reg<=1'b1;
	end
end

always @ (negedge clk_16) begin
	if (RESET==1 || ack_access_reg_3==1'b0) begin
		MKO_STRBD_N<=5'b11111;
		MKO_SELECT_N<=5'b11111;
	end else if (ack_access_reg_3==1'b1) begin
		case (Adr_slave_i_lbus_reg [15:13])
			MKO0_SET: begin
						MKO_STRBD_N   <=5'b11110;
						MKO_SELECT_N  <=5'b11110;
					end
			MKO1_SET: begin
						MKO_STRBD_N   <=5'b11101;
						MKO_SELECT_N  <=5'b11101;
					end
			MKO2_SET: begin
						MKO_STRBD_N   <=5'b11011;
						MKO_SELECT_N  <=5'b11011;
					end
			MKO3_SET: begin
						MKO_STRBD_N   <=5'b10111;
						MKO_SELECT_N  <=5'b10111;
					end
			MKO4_SET: begin
						MKO_STRBD_N   <=5'b01111;
						MKO_SELECT_N  <=5'b01111;
					end
			default:  begin
						MKO_STRBD_N<=5'b11111;
						MKO_SELECT_N<=5'b11111;
					end
        endcase
    end
end

always @ (posedge CLK_32) begin
	if (RESET==1 || (ack_access_reg_3==1'b1 && We_slave_i_lbus_reg==1'b1 && (Adr_slave_i_lbus_reg [15:13]==MKO0_SET ||
                                                                           Adr_slave_i_lbus_reg [15:13]==MKO1_SET ||
                                                                           Adr_slave_i_lbus_reg [15:13]==MKO2_SET ||
                                                                           Adr_slave_i_lbus_reg [15:13]==MKO3_SET ||
                                                                           Adr_slave_i_lbus_reg [15:13]==MKO4_SET )))
		MKO_RDWR_N<=1'b0;
	else
		MKO_RDWR_N<=1'b1;
end

endmodule