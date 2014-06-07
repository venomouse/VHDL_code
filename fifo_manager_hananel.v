`timescale 1ns / 1ns

module fifo_manager_hananel(
input 						clk,
input 						rst_b,

input 						push_to_fifo,				  //flag when high tells the fifo manager to put the push_record in the queue.
														  // the push_top sets it high/low. 
input       [6*8-1:0]       push_record, // the record to put in the queue
//output fifo_one_place_avail, 		// flag that signifies that only one place is left in the fifo 


output 						fifo_full, 					//  flag that signifies the the current fifo queue is full
//output     reg                    push_wait   , NOT USED IN THIS DESIGN IN THE LEVEL OF FIFO, DEFINED IN PUSH TOP

output						fifo_empty, 			//  Telling whether we have records to pop from the queue or not. used by ram_manager 
input 						pop_from_fifo,				// this flag is set to high by the ram_manager after it (the ram manager) took 
														//the current value in pop_record, it is accepted only if compare_queue is down or the fifo_min_record is valid, fifo_min_val high. this means that the fifo_manager should put the now in the pop record the next item in queue. the ram_manager sets it to low when it doesn't need to get a new item from the queue. 
output  [6*8-1:0]    	   pop_record, // contains the upper most item in the fifo queue. 

input reg 				   compare_queue,  // flag is set by ram_manager. when set to high by the ram manager, 
										//the fifo buffer goes over all of the items that have value smaller then the new min_val (after a pop occured in the ram_manager) and returns the minimum value in the FIFO //and the number of pop commands that the ram_manager has to execute (num_of_items_to_pop_for_min) in order to get all the record containing the values smaller than the current min_value (in the ram manager). fifo_manager turns it to low when a new relevant value was set to num_of_items_to_pop_for_min.

output reg [6*8-1:0] 		fifo_min_record, // the minimum value in the FIFO, when fifo_min_val in true
output reg 					fifo_min_val // is true when the minimum value in the fifo is in fifo_min_record.

);

reg [3:0]				next_push;
reg [3:0] 		  		next_pop;
reg [3:0] next_check;
//reg [3:0] addread;
//temp CHANGE to 4!
reg [9:0] addra, addrb;
wire [6*8-1:0] douta;
reg [6*8-1:0] dina, temp;
reg state, cs_a;
wire clkneg, end_fifo_comp;
assign fifo_full = (next_push + 1 == next_pop);
assign fifo_empty = (next_push == next_pop);
assign clkneg = !clk;
assign  end_fifo_comp =  ((next_check+1 == next_push)  || (next_check == next_push+15));


always @ (posedge clk)

	if (!rst_b)
	 begin
		state <= #1 0;
		next_push <= #1 0;
		next_pop <= #1 0;
		fifo_min_val <= #1 0;
		addra <= #1 0;
		cs_a <= #1 0;
		addrb <= #1 0;
	 end

	else begin
		if (push_to_fifo && !fifo_full)
		 begin
		    cs_a <= #1 1;
			dina <= #1 push_record;
			addra <= #1 next_push;
			next_push <= #1 next_push+1;
			if ((fifo_min_record[4*8-1:0] >= push_record[4*8-1:0] ) &&   !(compare_queue && state!=2))    //((fifo_min_record[6*8-1:2*8] >= push_record[6*8-1:2*8] ) &&   !(compare_queue && state!=2))
			begin
			 fifo_min_record <= #1 push_record;
			end
		 end
		else
		 begin
		 cs_a <= #1 0;
		 end
		if (pop_from_fifo && !fifo_empty && (!compare_queue || fifo_min_val))
			begin
			next_pop <= #1 next_pop+1;
			next_check <= #1 next_pop+1;
			addrb <= #1 next_pop+1;
			fifo_min_val <= #1 0;
			end

		if (compare_queue && !fifo_empty && !fifo_min_val)
		case(state)
		0: begin
		    fifo_min_record <= #1 pop_record;
		    if (next_check +1 != next_push)
		     begin
			    addrb <= #1 next_check +1;
			    next_check <= #1 next_check +1;
			    state <= #1 1; 
		     end
		    else
			 begin
			 fifo_min_val <= #1 1;
			end
		   end
		1: begin
		    if (fifo_min_record[4*8-1:0] >= pop_record[4*8-1:0]) //(fifo_min_record[6*8-1:2*8] >= pop_record[6*8-1:2*8])
				begin
				 if (push_to_fifo && !fifo_full && (pop_record[6*8-1:2*8] >= push_record[6*8-1:2*8] ))
					fifo_min_record <= #1 push_record;
			     else
					fifo_min_record <= #1 pop_record;
				end
			if (!end_fifo_comp)
		     begin
			    addrb <= #1 next_check +1;
			    next_check <= #1 next_check +1;
			    state <= #1 1; 
		     end
			else
			 begin
			 fifo_min_val <= #1 1;
			 state <= #1 0;
			 addrb <= #1 next_pop;
			 next_check <= #1 next_pop;
			 end
		   end
		endcase
		end



			
	tdp_ram_hananel tdp_ram (
    .clk(clkneg),
    .cs_a(cs_a),
    .rnw_a(1'b0),
    .a_add(addra),
    .a_data_in(dina),
    .a_data_out(douta),
    
    .cs_b(1'b1),   
    .rnw_b(1'b1),
    .b_add(addrb),
    .b_data_in(temp),
    .b_data_out(pop_record)
     );

// ram_64x1024 input_ram (
  // .clka(clk), // input clka
  // .wea(1), // input [0 : 0] wea only write on this port
  // .addra(addra), // input [9 : 0] addra
  // .dina(push_record), // input [63 : 0] dina
  // .douta(douta), // output [63 : 0] douta
  
  // .clkb(clk), // input clkb
  // .web(0), // input [0 : 0] web only read on this port
  // .addrb(addrb), // input [9 : 0] addrb
  // .dinb(temp), // input [63 : 0] dinb
  // .doutb(pop_record) // output [63 : 0] doutb
// );		
endmodule	 