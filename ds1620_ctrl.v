module ds1620_ctr (
//ds1620 signals
DQ,
CLK,
RST,

//main controller signals
CLK_32,
RESET,
//wb signals
ack_access_reg_1,
We_slave_i_lbus_reg,
Adr_slave_i_lbus_reg,
//internal signals    
DQ_TEMP,
TERMOSTAT_REG,
READ_DATA_TEMP_SUCCESSFUL);

/*****************************************************************************
 *                           Constant Declarations                           *
 *****************************************************************************/
parameter                         DS1620_SET;                   // = 3'b110;//h6
//parameter                         DS1620_READ_STAT_REG;         // = 3'b111;//h6
parameter                         READ_TEMP_REG                 = 8'hAA;
parameter                         READ_COUNTER_REG              = 8'hA0;
parameter                         READ_SLOPE_REG                = 8'hA9;
parameter                         READ_CONFIG_REG               = 8'hAC;
parameter                         START_CONVERT_REG             = 8'hEE;
parameter                         STOP_CONVERT_REG              = 8'h22;
parameter                         WRITE_CONFIG_REG              = 8'h0C;
parameter                         CONTINUE_MOD_REG              = 8'b0000_0010;
parameter                         WRITE_TH_REG                  = 8'h01;
parameter                         WRITE_TL_REG                  = 8'h02;
parameter                         TH_REG                        = {8'd90, 1'b0}; //SET 90 DEGREES{8'd90, 1'b0} 9'b010110100
parameter                         TL_REG                        = {8'd85, 1'b0};  //SET 85 DEGREES{8'd90, 1'b0} 9'b010101010
parameter                         TEST_WORD                     = 9'h0FA;
parameter                         CONFIG_REG                    = 8'b00001010;//reg after initialization h008

//PARAMETERS FOR CLOCK DEVIDER 1 MHZ
//parameter WIDTH = 5; // 
//parameter N = 25;// 

parameter WIDTH = 4; // 4
parameter N = 8;// 8

//DS1620 INTERFACE
inout   DQ;
output  CLK;
output  RST;
output  TERMOSTAT_REG=1'b0;

//main controller signals
input CLK_32;
input RESET;

//wb signals
input ack_access_reg_1;
input We_slave_i_lbus_reg;
input [15:0]Adr_slave_i_lbus_reg;

output reg [15:0] DQ_TEMP;
output reg READ_DATA_TEMP_SUCCESSFUL;

//CLOCK DEVIDER REGS 1 MHZ
reg [WIDTH-1:0] r_reg;
wire [WIDTH-1:0] r_nxt;
reg clk_track;
reg CLK_2_REG_0=1'b0;
reg CLK_2_REG_1=1'b0;
wire CLK_2_STROBE;

 /*****************************************************************************
 *                 Internal wires and registers Declarations                 *
 *****************************************************************************/

//INTERNAL DS1620 REGS
reg DQ_O_0;                      //REGISTER FOR START INITIALIZATION
reg DQ_O_1;
reg [8:0] CONFIG_REG_I;
reg [8:0] DQ_I_REG_0;            //REGISTER FOR START INITIALIZATION
reg [8:0] DQ_I_REG_1;
reg [15:0] count_0=16'd0;        //REGISTER FOR START INITIALIZATION
reg [19:0]  count_1=20'd0;
reg half_clk=1'b0;
reg read_data_temp_done=1'b1;
reg read_data_temp_done_reg_0;
reg read_data_temp_done_reg_1;
wire read_data_temp_done_strobe;
reg START_INIT_DONE=1'b0;        //REGISTER FOR START INITIALIZATION
wire DS1620_BUSY_STROBE;
reg RELOAD_INIT_REG=1'b0;
reg RELOAD_INIT_REG_1=1'b0;
reg RELOAD_INIT_REG_0=1'b0;
wire RELOAD_INIT_STROBE;
reg DS1620_BUSY_REG_0;
reg DS1620_BUSY_REG_1;
reg TERMOSTAT_REG;
//reg RELOAD_INIT_REG_0 = 1'b0;
reg RELOAD_INIT = 1'b0;
reg END_START_INIT=1'b0;
reg DS1620_BUSY;
reg RST_INT_0=1'b0;              //REGISTER FOR START INITIALIZATION
reg RST_INT_1=1'b0;
reg CLK_1=1'b0;
reg CLK_1_0=1'b1;                //REGISTER FOR START INITIALIZATION
wire CLK_2;

//output RST signal ds1620
assign RST = (END_START_INIT==1'b0 ||  RELOAD_INIT_REG==1'b1)?RST_INT_0 : RST_INT_1; //RST FOR DS1620

//INTERNAL DS1620 CLOCK

//2 MHZ //HALF BAUD FOR MAIN CLK DS1620
always @(posedge CLK_32 or posedge RESET)
begin
  if (RESET)
     begin
        r_reg <= 0;
	clk_track <= 1'b0;
     end
  else if (r_nxt == N)
 	   begin
	     r_reg <= 0;
	     clk_track <= ~clk_track;
	   end
  else 
      r_reg <= r_nxt;
end
 assign r_nxt = r_reg+1;   	      
 assign CLK_2 = clk_track;
 
 always @ (posedge CLK_32) begin
 CLK_2_REG_1 <= CLK_2;
 CLK_2_REG_0 <= CLK_2_REG_1;
 end
 assign CLK_2_STROBE = CLK_2 && ~CLK_2_REG_1;
//DS1620 MAIN PROGRAM

assign CLK  = (RST_INT_0==1'b1) ? CLK_1_0 : (RST_INT_1==1'b1) ? CLK_1 : 1'b1;

assign DQ   = ((END_START_INIT==1'b0 && (count_0<= 16'd60272)) ||  (RELOAD_INIT_REG==1'b1 && (count_0<= 16'd60272))) ? DQ_O_0:((count_1>=6'd2 && count_1<=6'd18) && END_START_INIT==1'b1 && RELOAD_INIT_REG==1'b0) ? DQ_O_1:1'bz;

/////////START INITIALIZATION DS1620//////////////
always  @ (posedge CLK_32, posedge RESET) begin
 if (RESET==1'b1) 
	begin
	count_0             <= 16'd0;
	RST_INT_0           <= 1'b0;
	CLK_1_0             <= 1'b1;
	DS1620_BUSY         <= 1'b0;
	end 
 else if ((RELOAD_INIT_REG==1'b0 && END_START_INIT==1'b1)) 
		begin
		count_0             <= 16'd0;
		RST_INT_0           <= 1'b0;
		CLK_1_0             <= 1'b1;
		end 
 else if ((END_START_INIT==1'b0 || (RELOAD_INIT_REG)) && read_data_temp_done==1'b1 && CLK_2_STROBE) begin
 count_0<=count_0 + 1'b1;
		case (count_0)
 ////////////////START WRITE CONFIG REGISTER///////////////////////
			6'd1:   begin                                           
					RST_INT_0    <= 1'b1;
					CLK_1_0      <= 1'b1;
					DS1620_BUSY  <= 1'b1;
					end 
			 6'd2:  begin
					DQ_O_0       <= WRITE_CONFIG_REG[0];
					CLK_1_0      <= 1'b0;
					end
			 6'd3:  CLK_1_0      <= 1'b1;
			 6'd4:  begin
					DQ_O_0       <= WRITE_CONFIG_REG[1];
					CLK_1_0      <= 1'b0;
					end
			 6'd5:  CLK_1_0      <= 1'b1;
			 6'd6:  begin
					DQ_O_0       <= WRITE_CONFIG_REG[2];
					CLK_1_0      <= 1'b0;
					end
			 6'd7:  CLK_1_0      <= 1'b1;
			 6'd8:  begin
					DQ_O_0       <= WRITE_CONFIG_REG[3];
					CLK_1_0      <= 1'b0;
					end
			 6'd9:  CLK_1_0      <= 1'b1; 
			 6'd10: begin
					DQ_O_0       <= WRITE_CONFIG_REG[4];
					CLK_1_0      <= 1'b0;
					end
			 6'd11: CLK_1_0      <= 1'b1;
			 6'd12: begin
					DQ_O_0       <= WRITE_CONFIG_REG[5];
					CLK_1_0      <= 1'b0;
					end
			 6'd13: CLK_1_0      <= 1'b1;
			 6'd14: begin
					DQ_O_0       <= WRITE_CONFIG_REG[6];
					CLK_1_0      <= 1'b0;
					end
			 6'd15: CLK_1_0      <= 1'b1;
			 6'd16: begin
					DQ_O_0       <= WRITE_CONFIG_REG[7];
					CLK_1_0      <= 1'b0;
					end
			 6'd17: CLK_1_0      <= 1'b1;
			///////////////////////////////////////////////////////////////
			 6'd21: RST_INT_0    <= 1'b1;
			 6'd22: begin
					DQ_O_0       <= CONTINUE_MOD_REG[0];
					CLK_1_0      <= 1'b0;
					end
			 6'd23: CLK_1_0      <= 1'b1;
			 6'd24: begin
					DQ_O_0       <= CONTINUE_MOD_REG[1];
					CLK_1_0      <= 1'b0;
					end
			 6'd25: CLK_1_0      <= 1'b1;
			 6'd26: begin
					DQ_O_0       <= CONTINUE_MOD_REG[2];
					CLK_1_0      <= 1'b0;
					end
			 6'd27: CLK_1_0      <= 1'b1;
			 6'd28: begin
					DQ_O_0       <= CONTINUE_MOD_REG[3];
					CLK_1_0      <= 1'b0;
					end
			 6'd29: CLK_1_0      <= 1'b1;
			 6'd30: begin
					DQ_O_0       <= CONTINUE_MOD_REG[4];
					CLK_1_0      <= 1'b0;
					end
			 6'd31: CLK_1_0      <= 1'b1;
			 6'd32: begin
					DQ_O_0       <= CONTINUE_MOD_REG[5];
					CLK_1_0      <= 1'b0;
					end
			 6'd33: CLK_1_0      <= 1'b1;
			 6'd34: begin
					DQ_O_0       <= CONTINUE_MOD_REG[6];
					CLK_1_0      <= 1'b0;
					end
			 6'd35: CLK_1_0      <= 1'b1;
			 6'd36: begin
					DQ_O_0       <= CONTINUE_MOD_REG[7];
					CLK_1_0      <= 1'b0;
					end
			 6'd37: CLK_1_0      <= 1'b1;
			 6'd38: RST_INT_0    <= 1'b0; 
//////////////////////////WAIT 10 MS/////////////////////////////////////////
/////////////////////START CONVERT TEMP//////////////////////////////////////
		 15'd20039: begin 
					RST_INT_0    <= 1'b1;
					CLK_1_0      <= 1'b1;
					DS1620_BUSY  <= 1'b1;
					end
		 15'd20040: begin
					DQ_O_0     <= START_CONVERT_REG[0]; 
					CLK_1_0      <= 1'b0;
					end
		 15'd20041: CLK_1_0      <= 1'b1;
		 15'd20042: begin
					DQ_O_0     <= START_CONVERT_REG[1];
					CLK_1_0      <= 1'b0;
					end
		 15'd20043: CLK_1_0      <= 1'b1;
		 15'd20044: begin
					DQ_O_0     <= START_CONVERT_REG[2];
					CLK_1_0      <= 1'b0;
					end
		 15'd20045: CLK_1_0      <= 1'b1;
		 15'd20046: begin
					DQ_O_0     <= START_CONVERT_REG[3];
					CLK_1_0      <= 1'b0;
					end
		 15'd20047: CLK_1_0      <= 1'b1; 
		 15'd20048: begin
					DQ_O_0     <= START_CONVERT_REG[4];
					CLK_1_0      <= 1'b0;
					end
		 15'd20049: CLK_1_0      <= 1'b1;
		 15'd20050: begin
					DQ_O_0     <= START_CONVERT_REG[5];
					CLK_1_0      <= 1'b0;
					end
		 15'd20051: CLK_1_0      <= 1'b1;
		 15'd20052: begin
					DQ_O_0     <= START_CONVERT_REG[6];
					CLK_1_0      <= 1'b0;
					end
		 15'd20053: CLK_1_0      <= 1'b1;
		 15'd20054: begin
					DQ_O_0     <= START_CONVERT_REG[7];
					CLK_1_0      <= 1'b0;
					end
		 15'd20055:  CLK_1_0      <= 1'b1;
		 15'd20057:  RST_INT_0    <= 1'b0;                               
 //////////////////////////IDLE ~60 us//////////////////////////////////
 ////////////////////START WRITE TH REGISTER////////////////////////////
		 15'd20177: begin                                             
					RST_INT_0  <= 1'b1;
					CLK_1_0      <= 1'b1;
					end 
		 15'd20178: begin
					DQ_O_0     <= WRITE_TH_REG[0];
					CLK_1_0      <= 1'b0;
					end
		 15'd20179: CLK_1_0      <= 1'b1;
		 15'd20180: begin
					DQ_O_0     <= WRITE_TH_REG[1];
					CLK_1_0      <= 1'b0;
					end
		 15'd20181: CLK_1_0      <= 1'b1;
		 15'd20182: begin
					DQ_O_0     <= WRITE_TH_REG[2];
					CLK_1_0      <= 1'b0;
					end
		 15'd20183: CLK_1_0      <= 1'b1;
		 15'd20184: begin
					DQ_O_0     <= WRITE_TH_REG[3];
					CLK_1_0      <= 1'b0;
					end
		 15'd20185: CLK_1_0      <= 1'b1; 
		 15'd20186: begin
					DQ_O_0     <= WRITE_TH_REG[4];
					CLK_1_0      <= 1'b0;
					end
		 15'd20187: CLK_1_0      <= 1'b1;
		 15'd20188: begin
					DQ_O_0     <= WRITE_TH_REG[5];
					CLK_1_0      <= 1'b0;
					end
		 15'd20189: CLK_1_0      <= 1'b1;
		 15'd20190: begin
					DQ_O_0     <= WRITE_TH_REG[6];
					CLK_1_0      <= 1'b0;
					end
		 15'd20191: CLK_1_0      <= 1'b1;
		 15'd20192: begin
					DQ_O_0     <= WRITE_TH_REG[7];
					CLK_1_0      <= 1'b0;
					end
		 15'd20193: CLK_1_0      <= 1'b1;
		///////////////////////////////////////////////////////////////
		 15'd20195: RST_INT_0  <= 1'b1;
		 15'd20196: begin
					DQ_O_0    <= TH_REG[0];
					CLK_1_0      <= 1'b0;
					end
		 15'd20197: CLK_1_0      <= 1'b1;
		 15'd20198: begin
					DQ_O_0    <= TH_REG[1];
					CLK_1_0      <= 1'b0;
					end
		 15'd20199: CLK_1_0      <= 1'b1;
		 15'd20200: begin
					DQ_O_0    <= TH_REG[2];
					CLK_1_0      <= 1'b0;
					end
		 15'd20201: CLK_1_0      <= 1'b1;
		 15'd20202: begin
					DQ_O_0    <= TH_REG[3];
					CLK_1_0      <= 1'b0;
					end
		 15'd20203: CLK_1_0      <= 1'b1;
		 15'd20204: begin
					DQ_O_0    <= TH_REG[4];
					CLK_1_0      <= 1'b0;
					end
		 15'd20205: CLK_1_0      <= 1'b1;
		 15'd20206: begin
					DQ_O_0    <= TH_REG[5];
					CLK_1_0      <= 1'b0;
					end
		 15'd20207: CLK_1_0      <= 1'b1;
		 15'd20208: begin
					DQ_O_0    <= TH_REG[6];
					CLK_1_0      <= 1'b0;
					end
		 15'd20209: CLK_1_0      <= 1'b1;
		 15'd20210: begin
					DQ_O_0       <= TH_REG[7];
					CLK_1_0      <= 1'b0;
					end
		 15'd20211: CLK_1_0      <= 1'b1;
		 15'd20212: begin
					DQ_O_0       <= TH_REG[8];
					CLK_1_0      <= 1'b0;
					end
		 15'd20213: CLK_1_0    <= 1'b1;
		 15'd20214: RST_INT_0  <= 1'b0;
//////////////////////////WAIT 10 MS/////////////////////////////////////////
////////////////////START WRITE TL REGISTER/////////////
		16'd40217:  begin                                            
					RST_INT_0    <= 1'b1;
					CLK_1_0      <= 1'b1;
					end 
		 16'd40218: begin
					DQ_O_0       <= WRITE_TL_REG[0];
					CLK_1_0      <= 1'b0;
					end
		 16'd40219: CLK_1_0      <= 1'b1;
		 16'd40220: begin
					DQ_O_0       <= WRITE_TL_REG[1];
					CLK_1_0      <= 1'b0;
					end
		 16'd40221: CLK_1_0      <= 1'b1;
		 16'd40222: begin
					DQ_O_0       <= WRITE_TL_REG[2];
					CLK_1_0      <= 1'b0;
					end
		 16'd40223: CLK_1_0      <= 1'b1;
		 16'd40224: begin
					DQ_O_0       <= WRITE_TL_REG[3];
					CLK_1_0      <= 1'b0;
					end
		 16'd40225: CLK_1_0      <= 1'b1; 
		 16'd40226: begin
					DQ_O_0       <= WRITE_TL_REG[4];
					CLK_1_0      <= 1'b0;
					end
		 16'd40227: CLK_1_0      <= 1'b1;
		 16'd40228: begin
					DQ_O_0       <= WRITE_TL_REG[5];
					CLK_1_0      <= 1'b0;
					end
		 16'd40229: CLK_1_0      <= 1'b1;
		 16'd40230: begin
					DQ_O_0       <= WRITE_TL_REG[6];
					CLK_1_0      <= 1'b0;
					end
		 16'd40231: CLK_1_0      <= 1'b1;
		 16'd40232: begin
					DQ_O_0     <= WRITE_TL_REG[7];
					CLK_1_0      <= 1'b0;
					end
		 16'd40233: CLK_1_0      <= 1'b1;
		///////////////////////////////////////////////////////////////
		 16'd40235: RST_INT_0  <= 1'b1;
		 16'd40236: begin
					DQ_O_0    <= TL_REG[0];
					CLK_1_0      <= 1'b0;
					end
		 16'd40237: CLK_1_0      <= 1'b1;
		 16'd40238: begin
					DQ_O_0    <= TL_REG[1];
					CLK_1_0      <= 1'b0;
					end
		 16'd40239: CLK_1_0      <= 1'b1;
		 16'd40240: begin
					DQ_O_0    <= TL_REG[2];
					CLK_1_0      <= 1'b0;
					end
		 16'd40241: CLK_1_0      <= 1'b1;
		 16'd40242: begin
					DQ_O_0    <= TL_REG[3];
					CLK_1_0      <= 1'b0;
					end
		 16'd40243: CLK_1_0      <= 1'b1;
		 16'd40244: begin
					DQ_O_0    <= TL_REG[4];
					CLK_1_0      <= 1'b0;
					end
		 16'd40245: CLK_1_0      <= 1'b1;
		 16'd40246: begin
					DQ_O_0    <= TL_REG[5];
					CLK_1_0      <= 1'b0;
					end
		 16'd40247: CLK_1_0      <= 1'b1;
		 16'd40248: begin
					DQ_O_0    <= TL_REG[6];
					CLK_1_0      <= 1'b0;
					end
		 16'd40249: CLK_1_0      <= 1'b1;
		 16'd40250: begin
					DQ_O_0    <= TL_REG[7];
					CLK_1_0      <= 1'b0;
					end
		 16'd40251: CLK_1_0      <= 1'b1;
		 16'd40252: begin
					DQ_O_0    <= TL_REG[8];
					CLK_1_0      <= 1'b0;
					end
		 16'd40253: CLK_1_0      <= 1'b1;
		 16'd40254: RST_INT_0  <= 1'b0;
 //////////////////////////WAIT 10 MS/////////////////////////////////////////
 ////////////////READ CONFIG REGISTER, COMPARE VERIFICATION REGISTER//////////////////
		 16'd60257:	begin 
					RST_INT_0      <= 1'b1;
					CLK_1_0        <= 1'b1;
					DS1620_BUSY  <= 1'b1;
					end 
		 16'd60258: begin
					DQ_O_0         <= READ_CONFIG_REG[0];
					CLK_1_0        <= 1'b0;
					end
		 16'd60259: CLK_1_0        <= 1'b1;
		 16'd60260: begin
					DQ_O_0         <= READ_CONFIG_REG[1];
					CLK_1_0        <= 1'b0;
					end
		 16'd60261: CLK_1_0        <= 1'b1;
		 16'd60262: begin
					DQ_O_0         <= READ_CONFIG_REG[2];
					CLK_1_0        <= 1'b0;
					end
		 16'd60263: CLK_1_0        <= 1'b1;
		 16'd60264: begin
					DQ_O_0         <= READ_CONFIG_REG[3];
					CLK_1_0        <= 1'b0;
					end
		 16'd60265: CLK_1_0        <= 1'b1; 
		 16'd60266: begin
					DQ_O_0        <= READ_CONFIG_REG[4];
					CLK_1_0       <= 1'b0;
					end
		 16'd60267: CLK_1_0       <= 1'b1;
		 16'd60268: begin
					DQ_O_0        <= READ_CONFIG_REG[5];
					CLK_1_0       <= 1'b0;
					end
		 16'd60269: CLK_1_0       <= 1'b1;
		 16'd60270: begin
					DQ_O_0        <= READ_CONFIG_REG[6];
					CLK_1_0       <= 1'b0;
					end
		 16'd60271: CLK_1_0       <= 1'b1;
		 16'd60272: begin
					DQ_O_0        <= READ_CONFIG_REG[7];
					CLK_1_0       <= 1'b0;
					end
		 16'd60273: CLK_1_0       <= 1'b1;
		 16'd60275: RST_INT_0     <= 1'b1;
		 16'd60276: CLK_1_0       <= 1'b0;
		 16'd60277: begin
					CLK_1_0       <= 1'b1;
					CONFIG_REG_I[0]    <= DQ;////////////////////
					end
		 16'd60278: CLK_1_0       <= 1'b0;
		 16'd60279: begin
					CLK_1_0           <= 1'b1;
					CONFIG_REG_I[1]   <= DQ;
					end
		 16'd60280: CLK_1_0      <= 1'b0;			
		 16'd60281: begin
					CLK_1_0          <= 1'b1;
					CONFIG_REG_I[2]  <= DQ;
					end
		 16'd60282: CLK_1_0      <= 1'b0;
		 16'd60283: begin
					CLK_1_0          <= 1'b1;
					CONFIG_REG_I[3]  <= DQ;
					end
		 16'd60284: CLK_1_0      <= 1'b0;
		 16'd60285: begin 
					CLK_1_0      <= 1'b1;
					CONFIG_REG_I[4]    <= DQ;
					end
		 16'd60286: CLK_1_0      <= 1'b0;
		 16'd60287: begin
					CLK_1_0      <= 1'b1;
					CONFIG_REG_I[5]    <= DQ;
					end
		 16'd60288: CLK_1_0      <= 1'b0;
		 16'd60289: begin
					CLK_1_0      <= 1'b1;
					CONFIG_REG_I[6]    <= DQ;
					end
		 16'd60290: CLK_1_0      <= 1'b0;
		 16'd60291: begin
					CLK_1_0      <= 1'b1;
					CONFIG_REG_I[7]    <= DQ;
					end
		 16'd60292: CLK_1_0      <= 1'b0;
		 16'd60293: begin
					CLK_1_0      <= 1'b1;
					CONFIG_REG_I[8]    <= DQ;
					end
		 16'd60294: begin 
					RST_INT_0           <= 1'b0;
						 //END_START_INIT      <= 1'b1;
						 //DS1620_BUSY         <= 1'b0;
						 end
		 16'd60400: begin 
					 //RST_INT_0           <= 1'b0;
						 END_START_INIT      <= 1'b1;
						 DS1620_BUSY         <= 1'b0;
				    end 			 
			endcase
 end
 end
 //END INITIALIZATION DS1620. FULL TIME OF INITIALIZATION ~ 31 MS
 
 always @ (posedge CLK_32) begin //scan config_reg, if CONFIG_REG_I==CONFIG_REG, start initialization saccessuly passed
	if (((CONFIG_REG_I[0] == CONFIG_REG [0]) || (CONFIG_REG_I[1] == CONFIG_REG [1]) 
	    || (CONFIG_REG_I[7] == CONFIG_REG [7]) || (CONFIG_REG_I[4] == CONFIG_REG [4])) 
	    && END_START_INIT==1'b1 && DS1620_BUSY_STROBE) begin//DS1620_BUSY_STROBE
		START_INIT_DONE     <= 1'b1; 
	end else if (((CONFIG_REG_I[0] !== CONFIG_REG [0]) || (CONFIG_REG_I[1] !== CONFIG_REG [1]) 
	    || (CONFIG_REG_I[7] !== CONFIG_REG [7]) || (CONFIG_REG_I[4] !== CONFIG_REG [4])) || END_START_INIT==1'b0) begin
		START_INIT_DONE     <= 1'b0;
	end
 end
 
 
 ///////////////////READ DATA FROM TEMP DATA REGISTER EVERY ~0.5 S////////////////////////////////
 always  @ (posedge CLK_32, posedge RESET) begin
	if (RESET==1'b1) begin
		read_data_temp_done <= 1'b1;
		count_1             <= 20'd0;
		RST_INT_1           <= 1'b0;
		CLK_1               <= 1'b1;
	end
 else if (RELOAD_INIT_REG==1'b1 && read_data_temp_done==1'b1) begin
 //read_data_temp_done <= 1'b0;
		count_1             <= 20'd0;
		RST_INT_1           <= 1'b0;
		CLK_1               <= 1'b1;
	end
 else if ((START_INIT_DONE ==1'b1) && CLK_2_STROBE) begin
		count_1<=count_1 + 1'b1;
		case (count_1)
			 6'd1:  begin 
					RST_INT_1  <= 1'b1;
					CLK_1        <= 1'b1;
					end 
			 6'd2:  begin
					DQ_O_1     <= READ_TEMP_REG[0];
					CLK_1        <= 1'b0;
					end
			 6'd3:  CLK_1      <= 1'b1;
			 6'd4:  begin
					DQ_O_1     <= READ_TEMP_REG[1];
					CLK_1        <= 1'b0;
					end
			 6'd5:  CLK_1      <= 1'b1;
			 6'd6:  begin
					DQ_O_1     <= READ_TEMP_REG[2];
					CLK_1        <= 1'b0;
					end
			 6'd7:  CLK_1      <= 1'b1;
			 6'd8:  begin
					DQ_O_1     <= READ_TEMP_REG[3];
					CLK_1        <= 1'b0;
					end
			 6'd9:  CLK_1      <= 1'b1; 
			 6'd10: begin
					DQ_O_1     <= READ_TEMP_REG[4];
					CLK_1        <= 1'b0;
					end
			 6'd11: CLK_1      <= 1'b1;
			 6'd12: begin
					DQ_O_1     <= READ_TEMP_REG[5];
					CLK_1      <= 1'b0;
					end
			 6'd13: CLK_1      <= 1'b1;
			 6'd14: begin
					DQ_O_1     <= READ_TEMP_REG[6];
					CLK_1      <= 1'b0;
					end
			 6'd15: CLK_1      <= 1'b1;
			 6'd16: begin
					DQ_O_1     <= READ_TEMP_REG[7];
					CLK_1      <= 1'b0;
					end
			 6'd17: CLK_1      <= 1'b1;
			 6'd21: RST_INT_1  <= 1'b1;
			 6'd22: CLK_1      <= 1'b0;
			 6'd23: begin
					CLK_1      <= 1'b1;
					DQ_I_REG_1[0]    <= DQ;//DQ
					end
			 6'd24: CLK_1      <= 1'b0;
			 6'd25: begin
					CLK_1      <= 1'b1;
					DQ_I_REG_1[1]    <= DQ;
					end
			 6'd26: CLK_1      <= 1'b0;			
			 6'd27: begin
					CLK_1      <= 1'b1;
					DQ_I_REG_1[2]    <= DQ;
					end
			 6'd28: CLK_1      <= 1'b0;
			 6'd29: begin
					CLK_1      <= 1'b1;
					DQ_I_REG_1[3]    <= DQ;
					end
			 6'd30: CLK_1      <= 1'b0;
			 6'd31: begin 
					CLK_1      <= 1'b1;
					DQ_I_REG_1[4]    <= DQ;
					end
			 6'd32: CLK_1      <= 1'b0;
			 6'd33: begin
					CLK_1      <= 1'b1;
					DQ_I_REG_1[5]    <= DQ;
					end
			 6'd34: CLK_1      <= 1'b0;
			 6'd35: begin
					CLK_1      <= 1'b1;
					DQ_I_REG_1[6]    <= DQ;
					end
			 6'd36: CLK_1      <= 1'b0;
			 6'd37: begin
					CLK_1      <= 1'b1;
					DQ_I_REG_1[7]    <= DQ;
					end
			 6'd38: CLK_1      <= 1'b0;
			 6'd39: begin
					CLK_1      <= 1'b1;
					DQ_I_REG_1[8]    <= DQ;
					end
			 6'd40: begin 
					RST_INT_1           <= 1'b0;
					//read_data_temp_done <= 1'b1;
					end
			 6'd50: read_data_temp_done <= 1'b1;
			 20'd1048575:  read_data_temp_done <= 1'b0;
			 endcase
		end
 end
 
always @  (posedge CLK_32) begin
	read_data_temp_done_reg_0 <= read_data_temp_done;
	read_data_temp_done_reg_1 <= read_data_temp_done_reg_0;
end
assign read_data_temp_done_strobe = read_data_temp_done && ~read_data_temp_done_reg_1;
 
always @  (posedge CLK_32) begin
	if (ack_access_reg_1==1'b0 && READ_DATA_TEMP_SUCCESSFUL ==1'b1) begin
		READ_DATA_TEMP_SUCCESSFUL <=1'b0;
		//DQ_TEMP <= 16'b0;
		RELOAD_INIT<=1'b0;
    end else if (RESET ==1'b1) begin
    DQ_TEMP <= 16'b0;  
		READ_DATA_TEMP_SUCCESSFUL <=1'b0;
		RELOAD_INIT<=1'b0;
	//end else if (We_slave_i_lbus_reg==1 && ack_access_reg_1==1'b1 && Adr_slave_i_lbus_reg[15:13]==DS1620_SET && DS1620_BUSY==1'b1) begin//START RELOAD INITIALIZATION DS1620, IF DS1620 IS BUSY, COMMAND IGNORED
	end else if (We_slave_i_lbus_reg==0 && ack_access_reg_1==1'b1 && Adr_slave_i_lbus_reg[11:8]==4'b1111 && DS1620_BUSY==1'b1) begin
		READ_DATA_TEMP_SUCCESSFUL <=1'b1;
	//end else if (We_slave_i_lbus_reg==1 && ack_access_reg_1==1'b1 && Adr_slave_i_lbus_reg[15:13]==DS1620_SET && DS1620_BUSY==1'b0) begin//IF BUSY = 0, STARTS DS1620 INITIALIZATION
	end else if (We_slave_i_lbus_reg==0 && ack_access_reg_1==1'b1 && Adr_slave_i_lbus_reg[11:8]==4'b1111 && DS1620_BUSY==1'b0) begin
		READ_DATA_TEMP_SUCCESSFUL <=1'b1;
		RELOAD_INIT<=1'b1;
   end else if (read_data_temp_done_strobe == 1'b1 && ~(We_slave_i_lbus_reg==0 && ack_access_reg_1==1'b1 && Adr_slave_i_lbus_reg[15:13]==DS1620_SET)) begin
		DQ_I_REG_0<=DQ_I_REG_1;
   end else if (We_slave_i_lbus_reg==0 && ack_access_reg_1==1'b1 && Adr_slave_i_lbus_reg[15:13]==DS1620_SET) begin
		DQ_TEMP <= {5'b0, DS1620_BUSY, START_INIT_DONE, DQ_I_REG_0[8:0]};
		READ_DATA_TEMP_SUCCESSFUL <=1'b1;
	  //end else if (We_slave_i_lbus_reg==0 && ack_access_reg_1==1'b1 && Adr_slave_i_lbus_reg[15:13]==DS1620_READ_STAT_REG) begin
	  //end else if (We_slave_i_lbus_reg==0 && ack_access_reg_1==1'b1 && Adr_slave_i_lbus_reg[15:13]==DS1620_READ_STAT_REG) begin
     //DQ_TEMP <= {DS1620_BUSY, 7'b0, START_INIT_DONE}; //CONFIG_REG_FOR_CPU
	  //DQ_TEMP <= {DS1620_BUSY, 5'b0, CONFIG_REG_I[8:1], 1'b0};
	  //READ_DATA_TEMP_SUCCESSFUL <=1'b1;
	end
 end
 
always @ (posedge CLK_32) begin
	RELOAD_INIT_REG_1 <= RELOAD_INIT;
	RELOAD_INIT_REG_0 <= RELOAD_INIT_REG_1;
end
  
assign RELOAD_INIT_STROBE = RELOAD_INIT && ~RELOAD_INIT_REG_0;
 
always @ (posedge CLK_32) begin
	if (RESET==1'b1 || DS1620_BUSY_STROBE) begin
		RELOAD_INIT_REG <= 1'b0;
	end else if (RELOAD_INIT_STROBE==1'b1) begin
		RELOAD_INIT_REG<=1'b1;
	end
end
  
always @ (posedge CLK_32) begin
	DS1620_BUSY_REG_1 <= DS1620_BUSY;
	DS1620_BUSY_REG_0 <= DS1620_BUSY_REG_1;
end
  
assign DS1620_BUSY_STROBE = ~DS1620_BUSY && DS1620_BUSY_REG_0;
  
  //TERMOSTAT
always @ (posedge CLK_32) begin
	if (RESET) begin
		TERMOSTAT_REG <= 1'b0;
	end else if ((DQ_I_REG_1[7:1] >= TH_REG[7:1]) && DQ_I_REG_1[8]==1'b0) begin
		TERMOSTAT_REG <= 1'b1;
	end else if ((DQ_I_REG_1[7:1] <= TL_REG[7:1]) && DQ_I_REG_1[8]==1'b0) begin
		TERMOSTAT_REG <= 1'b0;
	end
end
  
endmodule