module trig_filt(
   input wire sig_in,
   input wire clk,
   output wire sig_out
);

reg a,b;

always @(posedge clk)
begin
   b<=a;
   a<=sig_in;
end

assign sig_out = b;

endmodule