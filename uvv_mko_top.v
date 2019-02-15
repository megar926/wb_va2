`timescale 1ns / 100ps
//Main module of MKO FPGA GVM106/M

module uvv_mko_top (
CLK_32,
CLK_25,
CLK_24,
RESET_UVV_,
RESET_UVV_T_,
RESET_MKO_,
//CLK_25_OUT_A,
//CLK_25_OUT_B,

//FPGA BUS INTERFACE
Dat_slave_io_lbus,
Adr_slave_i_lbus,
Lock_slave_i_lbus,
Ack_slave_o_lbus,
Cyc_slave_i_lbus_,
Stb_slave_i_lbus_,
Sel_slave_i_lbus_,
We_slave_i_lbus_,
Err_slave_o_lbus,
Rty_slave_o_lbus,

//MKO BUS INTERFACE
MKO_CLK,
MKO_RES_N,
MKO_SSF_N,
MKO_STRBD_N,
MKO_SELECT_N,
MKO_RDWR_N,
MKO_RDAT0,
MKO_RDAT1,
MKO_RDAT2,
MKO_RDAT3,
MKO_RDAT4,
MKO_RDATP,
MKO_READYD_N,
MKO_INT,
DATA_MKO,
ADR_MKO,

//ds1620 ports
T_HIGH,
T_LOW,
T_COM,
DQ,
CLK,
RST,
//temp_out
TEMP_OUT
);

parameter                         WB_DATA_WIDTH                 =16; //
parameter                         WB_ADDR_WIDTH                 =16; //
//DS1620 SELECT ADRESS AND PARAMETERS
parameter                         DS1620_SET                    = 3'b110;//h6
//parameter                         DS1620_READ_STAT_REG          = 3'b111;//h6
//MKO SELECT ADRESS
parameter                         MKO0_SET                      =3'b000;//h0
parameter                         MKO1_SET                      =3'b001;//h1
parameter                         MKO2_SET                      =3'b010;//h2
parameter                         MKO3_SET                      =3'b011;//h3
parameter                         MKO4_SET                      =3'b100;//h4
parameter                         MKO_INT_REG                   =3'b101;//h5

input CLK_32;
input CLK_25;
input CLK_24;
input RESET_UVV_T_;
input RESET_UVV_;
input RESET_MKO_;

//FPGA BUS INTERFACE
inout               [WB_DATA_WIDTH-1:0]          Dat_slave_io_lbus; //DAN0-DAN15// BUS_REZERV_10 - DAN[4]
input               [WB_ADDR_WIDTH-1:0]          Adr_slave_i_lbus;  //A1-A16
input                                            Lock_slave_i_lbus; //pin 8 - xc4t//pin 188 //bus_rezerv9//NO USE
output               reg                         Ack_slave_o_lbus;  //pin 5 - xc4t//pin 184 //bus_rezerv4
input                                            Cyc_slave_i_lbus_;  //pin 6 - xc4t//pin 186 //bus_rezerv7
input                                            Stb_slave_i_lbus_;  //pin 12 - xc4t//pin 193 //bus_rezerv2
input                                            Sel_slave_i_lbus_;  //pin 16 - xc4t//pin 196 //CE_BUS
input                                            We_slave_i_lbus_;   //pin 14 - xc4t//pin 194 //WE_BUS
output                                           Err_slave_o_lbus;  //pin 7 - xc4t//pin 185 //bus_rezerv8//NO USE
output                                           Rty_slave_o_lbus;  //pin 11 - xc4t//pin 190 //bus_rezerv3//NO USE

//MKO interface
output              [4:0]                        MKO_CLK;
inout               [15:0]                       DATA_MKO;
output              [15:0]                       ADR_MKO;
output              [4:0]                        MKO_RES_N;
output              [4:0]                        MKO_SSF_N;
output              [4:0]                        MKO_STRBD_N;    
output              [4:0]                        MKO_SELECT_N;
output                                           MKO_RDWR_N;
output              [4:0]                        MKO_RDAT0;
output              [4:0]                        MKO_RDAT1;
output              [4:0]                        MKO_RDAT2;
output              [4:0]                        MKO_RDAT3;
output              [4:0]                        MKO_RDAT4;
output              [4:0]                        MKO_RDATP;
input               [4:0]                        MKO_READYD_N;
input               [4:0]                        MKO_INT;

//ds1620 interface
inout DQ;
output CLK;
output RST;
wire TERMOSTAT_REG;
input T_HIGH, T_LOW, T_COM;
//
output TEMP_OUT;

//EXTERNAL BLOCK REGISTERS
wire read_data_temp_done;
wire [15:0] DQ_I;
wire [15:0]Dat_slave_o_lbus;

//INTERNAL 25 MHZ FOR SPWIRE
//output CLK_25_OUT_A;
//output CLK_25_OUT_B;

//INTERNAL REGS
wire ack_set_reg;
reg ack_access_reg_0=1'b0;
reg ack_access_reg_1=1'b0;
reg ack_access_reg_2=1'b0;
reg ack_access_reg_3=1'b0;

wire ack_access_str;
wire addr_str;

wire CLK_32;
wire RESET;
wire ack_access;
wire RESET_MKO;
wire RESET_UVV;
wire RESET_UVV_T;
wire Stb_slave_i_lbus;

reg [WB_ADDR_WIDTH-1:0] Adr_slave_i_lbus_reg;
reg                     We_slave_i_lbus_reg;

assign Rty_slave_o_lbus   = 1'b0;
assign Err_slave_o_lbus   = 1'b0;
assign MKO_SSF_N[4:0]     = 5'b11111;

assign TEMP_OUT = ~(T_COM || TERMOSTAT_REG);//generate TEMP_OUT signal

//25 MHZ OUT//not use in ind 001
//assign CLK_25_OUT_A = CLK_25;
//assign CLK_25_OUT_B = CLK_25;

//TRIGGER FILTER FOR INPUT SIGNALS
trig_filt trig_filt_reset_uvv   (.clk(CLK_32), .sig_in(RESET_UVV_),        .sig_out(RESET_UVV));
trig_filt trig_filt_reset_uvv_t (.clk(CLK_32), .sig_in(RESET_UVV_T_),      .sig_out(RESET_UVV_T));
trig_filt trig_filt_reset_mko   (.clk(CLK_32), .sig_in(RESET_MKO_),        .sig_out(RESET_MKO));

trig_filt trig_filt_stb_wb      (.clk(CLK_32), .sig_in(Stb_slave_i_lbus_), .sig_out(Stb_slave_i_lbus));
trig_filt trig_filt_we_wb       (.clk(CLK_32), .sig_in(We_slave_i_lbus_),  .sig_out(We_slave_i_lbus));
trig_filt trig_filt_sel_wb      (.clk(CLK_32), .sig_in(Sel_slave_i_lbus_), .sig_out(Sel_slave_i_lbus));
trig_filt trig_filt_cyc_wb      (.clk(CLK_32), .sig_in(Cyc_slave_i_lbus_), .sig_out(Cyc_slave_i_lbus));

//assign RESET = (!RESET_MKO)?1'b1:1'b0;//for test
//assign RESET = (!RESET_UVV)?1'b1:1'b0;
assign RESET = !RESET_MKO|| !RESET_UVV|| !RESET_UVV_T;//used in last gvm 001
assign ack_access = (Stb_slave_i_lbus ==1 && Sel_slave_i_lbus ==1); //&& Cyc_slave_i_lbus==1 //used in last gvm 001

//assign ack_access = (Stb_slave_i_lbus ==1 || Cyc_slave_i_lbus==1 || Sel_slave_i_lbus ==1);
//assign ack_access = (Stb_slave_i_lbus ==1'b1)?1'b1:1'b0;//for test

always @ (posedge CLK_32) begin
if (RESET)
	begin
		ack_access_reg_0<=0;
		ack_access_reg_1<=0;
		ack_access_reg_2<=0;
		ack_access_reg_3<=0;
	end
else
	begin
		ack_access_reg_0<=ack_access;
		ack_access_reg_1<=ack_access_reg_0;
		ack_access_reg_2<=ack_access_reg_1;
		ack_access_reg_3<=ack_access_reg_2;
  end
end

assign addr_str = ack_access_reg_0 & ~ack_access_reg_1;
assign ack_access_str = ack_access_reg_2 & ~ack_access_reg_3;
assign ADR_MKO = Adr_slave_i_lbus_reg;
assign DATA_MKO = (We_slave_i_lbus_reg==1)?Dat_slave_io_lbus:16'hzzzz; 

assign Dat_slave_io_lbus = (We_slave_i_lbus_reg==0 && ack_access_reg_1==1'b1 && read_data_temp_done==1'b1)?(DQ_I):
                           (We_slave_i_lbus_reg==0 && ack_access_reg_3==1'b1 && ack_set_reg==1'b1)?(Dat_slave_o_lbus):
                           (We_slave_i_lbus_reg==0 && ack_access_reg_3==1'b1 && (MKO_SELECT_N[0]==1'b0 ||
                                                                                 MKO_SELECT_N[1]==1'b0 ||
                                                                                 MKO_SELECT_N[2]==1'b0 ||
                                                                                 MKO_SELECT_N[3]==1'b0 ||
                                                                                 MKO_SELECT_N[4]==1'b0 ))?(DATA_MKO):(16'hzzzz);

always @ (posedge CLK_32) begin
	if (RESET) begin 			
		Adr_slave_i_lbus_reg <= 0;
		We_slave_i_lbus_reg  <= 0;
		end
	else if (addr_str) begin
		Adr_slave_i_lbus_reg <= Adr_slave_i_lbus;
		We_slave_i_lbus_reg <= We_slave_i_lbus;
		end
	else begin				
		Adr_slave_i_lbus_reg <= Adr_slave_i_lbus_reg;
		We_slave_i_lbus_reg <= We_slave_i_lbus_reg;
		end
end

always @ (posedge CLK_32) begin //, negedge ack_access_reg_2) begin
	if (ack_access_reg_3==1'b0) begin
		Ack_slave_o_lbus<=1'b0;
	end else if (RESET) begin
		Ack_slave_o_lbus<=1'b0;
	end else if (ack_set_reg ||(~MKO_READYD_N[0])||(~MKO_READYD_N[1])||(~MKO_READYD_N[2])||(~MKO_READYD_N[3])||(~MKO_READYD_N[4])||(read_data_temp_done)==1'b1) begin  
		Ack_slave_o_lbus<=1'b1;
	end
 end
	
	ds1620_ctr 
	#(.DS1620_SET (DS1620_SET)) ds1620_ctr_(
.CLK_32 (CLK_32),
.READ_DATA_TEMP_SUCCESSFUL (read_data_temp_done),
.RESET (RESET),
.ack_access_reg_1 (ack_access_reg_1),
.We_slave_i_lbus_reg (We_slave_i_lbus_reg),
.Adr_slave_i_lbus_reg (Adr_slave_i_lbus_reg),
.DQ_TEMP (DQ_I), //TEMP DATA FROM DS1620
//DS1620 INTERFACE SIGNALS
.TERMOSTAT_REG (TERMOSTAT_REG),
.DQ (DQ),
.CLK (CLK),
.RST (RST)
);

mko #(.WB_DATA_WIDTH (WB_DATA_WIDTH),
      .WB_ADDR_WIDTH (WB_ADDR_WIDTH),
	   .MKO0_SET (MKO0_SET),
	   .MKO1_SET (MKO1_SET),
	   .MKO2_SET (MKO2_SET),
	   .MKO3_SET (MKO3_SET),
	   .MKO4_SET (MKO4_SET),
	   .MKO_INT_REG (MKO_INT_REG)	) mko_ (
.CLK_32                  (CLK_32),
.RESET                   (RESET),
//MKO SIGNALS
.MKO_CLK                 (MKO_CLK),
.MKO_RES_N               (MKO_RES_N),
.MKO_STRBD_N             (MKO_STRBD_N),
.MKO_SELECT_N            (MKO_SELECT_N),
.MKO_RDWR_N              (MKO_RDWR_N),
.MKO_RDAT0               (MKO_RDAT0),
.MKO_RDAT1               (MKO_RDAT1),
.MKO_RDAT2               (MKO_RDAT2),
.MKO_RDAT3               (MKO_RDAT3),
.MKO_RDAT4               (MKO_RDAT4),
.MKO_RDATP               (MKO_RDATP),
//WB bus signals
.Dat_slave_o_lbus        (Dat_slave_o_lbus),
.Dat_slave_io_lbus       (Dat_slave_io_lbus),
.Adr_slave_i_lbus_reg    (Adr_slave_i_lbus_reg),
.We_slave_i_lbus_reg     (We_slave_i_lbus_reg),
.ack_access_reg_3        (ack_access_reg_3),
.ack_access_str          (ack_access_str),
.ack_set_reg             (ack_set_reg)
);

endmodule


