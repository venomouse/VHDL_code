`timescale 1ns / 1ns


////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////
// this is a behavioral model of true dual port ram,
// this means that we have two ports were we can do
// wr/wr rd/wr wr/rd rd/rd from two different adresses
// simultenously, when one examine the code, we can see
// that the ram is always performing rd for a port if cs_x 
// is enabled, this is the only writing style that is supported
// by ISE and is mapped to what is called true dual port ram
// however, I found that this mapping is not stable and therfore
// I decided to generate an ip_core for those rams rather than 
// infering them from pure rtl.
// the student will need additional rams for the design.
// use core_gen tool, invoke it from window, and generate 
// what ever rams needed. 
// I tried to avoid this complication, w/o sucesses.
// please examine documents ug383_spartan6_block_ram_resource.pdf 
// also examine xst_v6s6.pdf for writing style learning 


module tdp_ram_hananel
  #(
    parameter data_wd=48,
    parameter add_wd=4
    )
   (
    input wire 		     clk,
    input 		     cs_a,
    input 		     rnw_a,
    input [add_wd-1:0] 	     a_add,
    input [data_wd-1:0]      a_data_in,
    output reg [data_wd-1:0] a_data_out,
    
    input 		     cs_b,   
    input 		     rnw_b,
    input [add_wd-1:0] 	     b_add,
    input [data_wd-1:0]      b_data_in,
    output reg [data_wd-1:0] b_data_out
     );

  reg [data_wd-1:0] ram [(1<<add_wd)-1:0];



   always @(posedge clk)
     if (cs_a)
       begin
          if (!rnw_a)
            ram[a_add] <= #1 a_data_in;
          a_data_out <= #1 ram[a_add];
       end
   
   
   always @(posedge clk)
     if (cs_b)
       begin
          if (!rnw_b)
            ram[b_add] <= #1 b_data_in;
          b_data_out <= #1 ram[b_add];
       end
   



endmodule
