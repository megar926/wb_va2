module uvv_mko_top (
CLK_32,
CLK_100,
RESET_UVV,
RESET_UVV_T,
RESET_MKO,

//FPGA BUS INTERFACE
Dat_slave_io_lbus,
Adr_slave_i_lbus,
Lock_slave_i_lbus,
Ack_slave_o_lbus,
Cyc_slave_i_lbus,
Stb_slave_i_lbus,
Sel_slave_i_lbus,
We_slave_i_lbus,
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
ADR_MKO
);

parameter                         WB_DATA_WIDTH                 =16; //
parameter                         WB_ADDR_WIDTH                 =16; //

//MKO SELECT ADRESS
parameter                         MKO0_SET                      =3'b000;//h0
parameter                         MKO1_SET                      =3'b001;//h1
parameter                         MKO2_SET                      =3'b010;//h2
parameter                         MKO3_SET                      =3'b011;//h3
parameter                         MKO4_SET                      =3'b100;//h4
parameter                         MKO_INT_REG                   =3'b101;//h5

input CLK_32;
input CLK_100;
input RESET_UVV_T;
input RESET_UVV;
input RESET_MKO;

//FPGA BUS INTERFACE
inout               [WB_DATA_WIDTH-1:0]          Dat_slave_io_lbus; //DAN0-DAN15// BUS_REZERV_10 - DAN[4]
input               [WB_ADDR_WIDTH-1:0]          Adr_slave_i_lbus;  //A1-A16
input                                            Lock_slave_i_lbus; //pin 8 - xc4t//pin 188 //bus_rezerv9//NO USE
output                                           Ack_slave_o_lbus;  //pin 5 - xc4t//pin 184 //bus_rezerv4
input                                            Cyc_slave_i_lbus;  //pin 6 - xc4t//pin 186 //bus_rezerv7
input                                            Stb_slave_i_lbus;  //pin 12 - xc4t//pin 193 //bus_rezerv2
input                                            Sel_slave_i_lbus;  //pin 16 - xc4t//pin 196 //CE_BUS
input                                            We_slave_i_lbus;   //pin 14 - xc4t//pin 194 //WE_BUS
output                                           Err_slave_o_lbus;  //pin 7 - xc4t//pin 185 //bus_rezerv8//NO USE
output                                           Rty_slave_o_lbus;  //pin 11 - xc4t//pin 190 //bus_rezerv3//NO USE

//MKO interface
output              [4:0]                        MKO_CLK;
inout               [15:0]                       DATA_MKO;
output              [15:0]                       ADR_MKO;
output              [4:0]                        MKO_RES_N;
output              [4:0]                        MKO_SSF_N;
output   reg        [4:0]                        MKO_STRBD_N;	
output   reg        [4:0]                        MKO_SELECT_N;
output   reg                                     MKO_RDWR_N;
output   reg        [4:0]                        MKO_RDAT0;
output   reg        [4:0]                        MKO_RDAT1;
output   reg        [4:0]                        MKO_RDAT2;
output   reg        [4:0]                        MKO_RDAT3;
output   reg        [4:0]                        MKO_RDAT4;
output              [4:0]                        MKO_RDATP;
input               [4:0]                        MKO_READYD_N;
input               [4:0]                        MKO_INT;

//INTERNAL REGS
reg clk_16=1'b0;
reg [WB_DATA_WIDTH-1:0] Dat_slave_o_lbus;

reg ack_set_reg;

reg str_rst_0_0=1'b0;
reg str_rst_1_0=1'b0;
reg str_rst_2_0=1'b0;
reg str_rst_3_0=1'b0;

reg str_rst_0_1=1'b0;
reg str_rst_1_1=1'b0;
reg str_rst_2_1=1'b0;
reg str_rst_3_1=1'b0;

reg str_rst_0_2=1'b0;
reg str_rst_1_2=1'b0;
reg str_rst_2_2=1'b0;
reg str_rst_3_2=1'b0;

reg str_rst_0_3=1'b0;
reg str_rst_1_3=1'b0;
reg str_rst_2_3=1'b0;
reg str_rst_3_3=1'b0;

reg str_rst_0_4=1'b0;
reg str_rst_1_4=1'b0;
reg str_rst_2_4=1'b0;
reg str_rst_3_4=1'b0;

reg mko_res_0=1'b0;
reg mko_res_1=1'b0;
reg mko_res_2=1'b0;
reg mko_res_3=1'b0;
reg mko_res_4=1'b0;

wire RESET;
wire ack_access;

assign Rty_slave_o_lbus   = 1'b0;
assign Err_slave_o_lbus   = 1'b0;
assign MKO_SSF_N[4:0]     = 5'b11111;

assign RESET = (!RESET_MKO)?1'b1:1'b0;
//assign RESET = (!RESET_MKO || !RESET_UVV || !RESET_UVV_T)?1'b1:1'b0;
//assign ack_access = (Stb_slave_i_lbus ==1 && Cyc_slave_i_lbus==1 && Sel_slave_i_lbus ==1); 



//assign ack_access = (Stb_slave_i_lbus ==1 || Cyc_slave_i_lbus==1 || Sel_slave_i_lbus ==1);
assign ack_access = (Stb_slave_i_lbus ==1);
//DEL 2 FOR 1895VA2T
always @ (posedge CLK_32) begin
clk_16<=!clk_16; //62,5 nS
end

assign MKO_CLK[0]         =clk_16;
assign MKO_CLK[1]         =clk_16;
assign MKO_CLK[2]         =clk_16;
assign MKO_CLK[3]         =clk_16;
assign MKO_CLK[4]         =clk_16;

//DELAY 4 TACTS RESET FOR MKO 1895va2t
always @ (posedge clk_16) begin
if (RESET==1'b1) begin
  str_rst_0_0<=1'b0;
  str_rst_1_0<=1'b0;
  str_rst_2_0<=1'b0;
  str_rst_3_0<=1'b0;
end else begin
  str_rst_0_0<=mko_res_0;
  str_rst_1_0<=str_rst_0_0;
  str_rst_2_0<=str_rst_1_0;
  str_rst_3_0<=str_rst_2_0;
end
end

always @ (posedge clk_16) begin
if (RESET==1'b1) begin
  str_rst_0_1<=1'b0;
  str_rst_1_1<=1'b0;
  str_rst_2_1<=1'b0;
  str_rst_3_1<=1'b0;
end else begin
  str_rst_0_1<=mko_res_1;
  str_rst_1_1<=str_rst_0_1;
  str_rst_2_1<=str_rst_1_1;
  str_rst_3_1<=str_rst_2_1;
end
end

always @ (posedge clk_16) begin
if (RESET==1'b1) begin
  str_rst_0_2<=1'b0;
  str_rst_1_2<=1'b0;
  str_rst_2_2<=1'b0;
  str_rst_3_2<=1'b0;
end else begin
  str_rst_0_2<=mko_res_2;
  str_rst_1_2<=str_rst_0_2;
  str_rst_2_2<=str_rst_1_2;
  str_rst_3_2<=str_rst_2_2;
end
end

always @ (posedge clk_16) begin
if (RESET==1'b1) begin
  str_rst_0_3<=1'b0;
  str_rst_1_3<=1'b0;
  str_rst_2_3<=1'b0;
  str_rst_3_3<=1'b0;
end else begin
  str_rst_0_3<=mko_res_3;
  str_rst_1_3<=str_rst_0_3;
  str_rst_2_3<=str_rst_1_3;
  str_rst_3_3<=str_rst_2_3;
end
end

always @ (posedge clk_16) begin
if (RESET==1'b1) begin
  str_rst_0_4<=1'b0;
  str_rst_1_4<=1'b0;
  str_rst_2_4<=1'b0;
  str_rst_3_4<=1'b0;
end else begin
  str_rst_0_4<=mko_res_4;
  str_rst_1_4<=str_rst_0_4;
  str_rst_2_4<=str_rst_1_4;
  str_rst_3_4<=str_rst_2_4;
end
end

assign MKO_RES_N[0] = ((str_rst_0_0 && str_rst_1_0 && str_rst_2_0 && str_rst_3_0)==1)?1'b1:1'b0;
assign MKO_RES_N[1] = ((str_rst_0_1 && str_rst_1_1 && str_rst_2_1 && str_rst_3_1)==1)?1'b1:1'b0;
assign MKO_RES_N[2] = ((str_rst_0_2 && str_rst_1_2 && str_rst_2_2 && str_rst_3_2)==1)?1'b1:1'b0;
assign MKO_RES_N[3] = ((str_rst_0_3 && str_rst_1_3 && str_rst_2_3 && str_rst_3_3)==1)?1'b1:1'b0;
assign MKO_RES_N[4] = ((str_rst_0_4 && str_rst_1_4 && str_rst_2_4 && str_rst_3_4)==1)?1'b1:1'b0;

 
//MKO RDAT INTERNAL REGISTERS
always @ (posedge clk_16) begin
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
  end else if (We_slave_i_lbus==1 && ack_access==1 && Adr_slave_i_lbus[15:13]==MKO_INT_REG) begin//write data to RDAT register
    case (Adr_slave_i_lbus[2:0])
     MKO0_SET: begin
                               mko_res_0<=Dat_slave_io_lbus[15];
                               MKO_RDAT4 [0]<=Dat_slave_io_lbus[4];
                               MKO_RDAT3 [0]<=Dat_slave_io_lbus[3];
                               MKO_RDAT2 [0]<=Dat_slave_io_lbus[2];
                               MKO_RDAT1 [0]<=Dat_slave_io_lbus[1];
                               MKO_RDAT0 [0]<=Dat_slave_io_lbus[0];
                            end
     MKO1_SET: begin
                               mko_res_1<=Dat_slave_io_lbus[15]; 
                              {MKO_RDAT4 [1], MKO_RDAT3 [1], MKO_RDAT2 [1], MKO_RDAT1 [1], MKO_RDAT0 [1]}<=Dat_slave_io_lbus[4:0];
                            end
     MKO2_SET: begin
                               mko_res_2<=Dat_slave_io_lbus[15];
                               MKO_RDAT4 [2]<=Dat_slave_io_lbus[4];
                               MKO_RDAT3 [2]<=Dat_slave_io_lbus[3];
                               MKO_RDAT2 [2]<=Dat_slave_io_lbus[2];
                               MKO_RDAT1 [2]<=Dat_slave_io_lbus[1];
                               MKO_RDAT0 [2]<=Dat_slave_io_lbus[0];
                            end
     MKO3_SET: begin
                               mko_res_3<=Dat_slave_io_lbus[15]; 
                              {MKO_RDAT4 [3], MKO_RDAT3 [3], MKO_RDAT2 [3], MKO_RDAT1 [3], MKO_RDAT0 [3]}<=Dat_slave_io_lbus[4:0];
                            end
     MKO4_SET: begin
                               mko_res_4<=Dat_slave_io_lbus[15]; 
                              {MKO_RDAT4 [4], MKO_RDAT3 [4], MKO_RDAT2 [4], MKO_RDAT1 [4], MKO_RDAT0 [4]}<=Dat_slave_io_lbus[4:0];
                            end
      default:                begin
                               mko_res_0<=1'b0;
                               mko_res_1<=1'b0;
                               mko_res_2<=1'b0;
                               mko_res_3<=1'b0;
                               mko_res_4<=1'b0;
                               MKO_RDAT0<=5'b00000;
                               MKO_RDAT1<=5'b00000;
                               MKO_RDAT2<=5'b00000;
                               MKO_RDAT3<=5'b00000;
                               MKO_RDAT4<=5'b00000;
                               end
    endcase
 end
 end
 
assign MKO_RDATP [0] = MKO_RDAT0 [0]^MKO_RDAT1 [0]^MKO_RDAT2 [0]^MKO_RDAT3 [0]^MKO_RDAT4 [0];
assign MKO_RDATP [1] = MKO_RDAT0 [1]^MKO_RDAT1 [1]^MKO_RDAT2 [1]^MKO_RDAT3 [1]^MKO_RDAT4 [1];
assign MKO_RDATP [2] = MKO_RDAT0 [2]^MKO_RDAT1 [2]^MKO_RDAT2 [2]^MKO_RDAT3 [2]^MKO_RDAT4 [2];
assign MKO_RDATP [3] = MKO_RDAT0 [3]^MKO_RDAT1 [3]^MKO_RDAT2 [3]^MKO_RDAT3 [3]^MKO_RDAT4 [3];
assign MKO_RDATP [4] = MKO_RDAT0 [4]^MKO_RDAT1 [4]^MKO_RDAT2 [4]^MKO_RDAT3 [4]^MKO_RDAT4 [4];
     
always  @ (posedge clk_16) begin
  if (RESET==1 || ack_access==0) begin
    Dat_slave_o_lbus<=16'h0000;
  end else if (We_slave_i_lbus==0 && ack_access==1 && Adr_slave_i_lbus[15:13]==MKO_INT_REG) begin//read data from RDAT and RESET register
    case (Adr_slave_i_lbus[2:0])
      MKO0_SET: Dat_slave_o_lbus[15:0]<={MKO_RES_N[0] ,10'b0,MKO_RDAT4 [0], MKO_RDAT3 [0], MKO_RDAT2 [0], MKO_RDAT1 [0], MKO_RDAT0 [0]};
      MKO1_SET: Dat_slave_o_lbus<={MKO_RES_N[1] ,10'b0,MKO_RDAT4 [1], MKO_RDAT3 [1], MKO_RDAT2 [1], MKO_RDAT1 [1], MKO_RDAT0 [1]};
      MKO2_SET: Dat_slave_o_lbus<={MKO_RES_N[2] ,10'b0,MKO_RDAT4 [2], MKO_RDAT3 [2], MKO_RDAT2 [2], MKO_RDAT1 [2], MKO_RDAT0 [2]};
      MKO3_SET: Dat_slave_o_lbus<={MKO_RES_N[3] ,10'b0,MKO_RDAT4 [3], MKO_RDAT3 [3], MKO_RDAT2 [3], MKO_RDAT1 [3], MKO_RDAT0 [3]};
      MKO4_SET: Dat_slave_o_lbus<={MKO_RES_N[4] ,10'b0,MKO_RDAT4 [4], MKO_RDAT3 [4], MKO_RDAT2 [4], MKO_RDAT1 [4], MKO_RDAT0 [4]};
      default : Dat_slave_o_lbus<=16'h0000;                                      
    endcase
    end
  end
    

always @ (posedge clk_16) begin
  if (RESET==1 || ack_access==0) begin
      ack_set_reg<=1'b0;
  end else if (ack_access==1 && (Adr_slave_i_lbus[15:13]==MKO_INT_REG && (Adr_slave_i_lbus[2:0]==MKO0_SET ||
                                                                          Adr_slave_i_lbus[2:0]==MKO1_SET || 
                                                                          Adr_slave_i_lbus[2:0]==MKO2_SET ||
                                                                          Adr_slave_i_lbus[2:0]==MKO3_SET ||
                                                                          Adr_slave_i_lbus[2:0]==MKO4_SET ))) begin//TODO
    ack_set_reg<=1'b1;
  end
end

assign Dat_slave_io_lbus = (We_slave_i_lbus==0 && ack_access==1)?(Dat_slave_o_lbus||DATA_MKO):16'bz;
assign ADR_MKO = Adr_slave_i_lbus;
assign DATA_MKO = (We_slave_i_lbus==0 && ack_access==1 && (      Adr_slave_i_lbus[15:13]==MKO0_SET||
                                                                 Adr_slave_i_lbus[15:13]==MKO1_SET||
                                                                 Adr_slave_i_lbus[15:13]==MKO2_SET||
                                                                 Adr_slave_i_lbus[15:13]==MKO3_SET||
                                                                 Adr_slave_i_lbus[15:13]==MKO4_SET))?16'bz:Dat_slave_io_lbus;
                                                                 //wait READYD_N signal TO DO
always @ (posedge clk_16) begin
  if (RESET==1 || ack_access==1'b0) begin
    MKO_STRBD_N<=5'b11111;
    MKO_SELECT_N<=5'b11111;
  end else if (ack_access==1'b1) begin
    case (Adr_slave_i_lbus [15:13])
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

//assign MKO_RDWR_N=(We_slave_i_lbus==1)?1'b0:1'b1;


always @ (negedge clk_16) begin
  if (RESET==1 || (ack_access==1'b1 && We_slave_i_lbus==1 && (Adr_slave_i_lbus [15:13]==(MKO0_SET || MKO1_SET || MKO2_SET || MKO3_SET || MKO4_SET)))) begin
  MKO_RDWR_N<=1'b0;
end else if (ack_access==1'b1 && (We_slave_i_lbus==0 && (Adr_slave_i_lbus [15:13]==(MKO0_SET || MKO1_SET || MKO2_SET || MKO3_SET || MKO4_SET)))) begin
  MKO_RDWR_N<=1'b1;
end
end

assign Ack_slave_o_lbus=(ack_access==1)?(ack_set_reg||(~MKO_READYD_N[0])||(~MKO_READYD_N[1])||(~MKO_READYD_N[2])||(~MKO_READYD_N[3])||(~MKO_READYD_N[4])):1'b0;
           
endmodule

