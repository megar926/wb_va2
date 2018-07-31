`timescale 10ns / 100ps

module test_wb(
Dat_master_io_lbus);

parameter                         WB_DATA_WIDTH                 =16; //
parameter                         WB_ADDR_WIDTH                 =16; //

logic clk = 0;
logic reset = 0;
logic ack_status_ok = 0;

    //masters bus
inout           [WB_DATA_WIDTH-1:0]       Dat_master_io_lbus;  // input data buses from masters
logic           [WB_ADDR_WIDTH-1:0]       Adr_master_o_lbus; // input address buses from masters
logic           [WB_DATA_WIDTH-1:0]       Dat_master_i_lbus; // input data buses from masters
logic                                     Lock_master_o_lbus; // input data buses from masters
logic                                     Ack_master_i_lbus; // input data buses from masters
logic                                     Req_master_o_lbus;
logic                                     We_master_o_lbus;
logic                                     Err_master_i_lbus;
logic                                     Stb_master_o_lbus;

//internal regs
reg [WB_DATA_WIDTH-1:0] Dat_master_o_lbus;

uvv_mko_top test_wb(
.CLK_32 (clk),
.RESET_MKO (reset),
.Adr_slave_i_lbus (Adr_master_o_lbus),
.Dat_slave_io_lbus(Dat_master_io_lbus),
.We_slave_i_lbus (We_master_o_lbus),
.Ack_slave_o_lbus (Ack_master_i_lbus),
.Stb_slave_i_lbus (Stb_master_o_lbus),
.MKO_READYD_N (5'b11111)
);

always #5 clk <= ~clk;

assign Dat_master_io_lbus= (We_master_o_lbus==1)?Dat_master_o_lbus:16'bz;

task SINGLE_WRITE_WB(input [WB_DATA_WIDTH-1:0] DAT, input [WB_ADDR_WIDTH-1:0] ADR);
begin
  @ (posedge clk)
ack_status_ok=0;
//forever
@ (posedge clk, posedge ack_status_ok) begin
if (ack_status_ok==1'b0) begin
Dat_master_o_lbus <= DAT;
Adr_master_o_lbus <= ADR;
We_master_o_lbus  <= 1'b1;
Stb_master_o_lbus <= 1'b1;
end
wait (ack_status_ok==1'b1);
Stb_master_o_lbus <= 1'b0;
disable SINGLE_WRITE_WB; 
end
end
endtask

task SINGLE_READ_WB(input [WB_DATA_WIDTH-1:0] DAT, input [WB_ADDR_WIDTH-1:0] ADR);
begin
//reg ack_status_ok;
wait (clk==1'b1);
ack_status_ok=0;
forever
@ (posedge clk, posedge ack_status_ok) begin
if (ack_status_ok==1'b0) begin
Adr_master_o_lbus <= ADR;
We_master_o_lbus  <= 1'b0;
Stb_master_o_lbus <= 1'b1;
end else if (ack_status_ok==1'b1) begin
Adr_master_o_lbus <= 16'b0;
We_master_o_lbus  <= 1'b0;
Stb_master_o_lbus <= 1'b0;
end
end
end
endtask


always @ (posedge clk) begin
  if (Ack_master_i_lbus==1)
  ack_status_ok<=1'b1;
else 
  ack_status_ok<=1'b0;
end

initial
begin: MAIN
  Stb_master_o_lbus <= 1'b0;
  We_master_o_lbus  <= 1'b0;
  Adr_master_o_lbus <= 16'h0000;
  Dat_master_o_lbus <= 16'h0000;
  #1000
  reset = 1;
  #20
  reset = 0;
  #20
  reset = 1;
  SINGLE_WRITE_WB (16'h0001, 16'hA000);//set reset to 1
  wait ( ack_status_ok==1'b1 );
  SINGLE_WRITE_WB (16'h0002, 16'hA001);//set rdat
  wait ( ack_status_ok==1'b1 );
  SINGLE_WRITE_WB (16'h0003, 16'hA003);//set rdat
  wait ( ack_status_ok==1'b1 );
  SINGLE_WRITE_WB (16'h0003, 16'hA002);//set rdat
  wait ( ack_status_ok==1'b1 );
  SINGLE_WRITE_WB (16'h0003, 16'hA004);//set rdat
  wait ( ack_status_ok==1'b1 );
  #2000
  reset = 0;
  #20
  reset = 1;
  @ (posedge clk)
  SINGLE_WRITE_WB (16'h8001, 16'hA000);//set reset to 1
  wait ( ack_status_ok==1'b1 );
  SINGLE_WRITE_WB (16'h8002, 16'hA001);//set rdat
  wait ( ack_status_ok==1'b1 );
  SINGLE_WRITE_WB (16'h8003, 16'hA003);//set rdat
  wait ( ack_status_ok==1'b1 );
  SINGLE_WRITE_WB (16'h8003, 16'hA002);//set rdat
  wait ( ack_status_ok==1'b1 );
  SINGLE_WRITE_WB (16'h8003, 16'hA004);//set rdat
  wait ( ack_status_ok==1'b1 );
  
  $stop;
end
endmodule