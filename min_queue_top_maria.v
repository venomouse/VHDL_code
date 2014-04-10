`timescale 1ns / 1ns

module min_queue_top_hananel  #(parameter q_depth=1024, parameter ptr_wd=10) (
	input                             clk                           , // 
	input                             rst_b                         , // 
		     
		     // push interface		     
	input                             push                          , //  write record cmd, accepted when full and push_wait are low
	input             [6*8-1:0]       push_record                   , //  new record data,
	output     reg                    full                          , //  no more space to hold records
	output     reg                    push_wait                     , //  indicate that no more space left in the input fifo,
				// it is recomended to put an input fifo of few entries,
				// the aim of this fifo is to accept a burst of pushes that are 
				// not accompanied with pops, in this case, we can accept few push 
				// back to back w/o waiting for every record to reach its place.
				// of course student must manage the min_valid output, the idea
				// is to try not to stop the push side, if there is no pops that 
				// need the Q to be stable ...

		     
		     // pop interface
	input                             pop                           , //  read record command, accepted when min_valid is true.
	output            [6*8-1:0]       pop_record                    , //  the record satisfy the min condition when min_valid is true.
	output     reg                    empty                         , //  queue is abselutly empty
	output     reg                    min_valid                       //  high when pop_record is the min key record for this cycle.
		     );

	//synchronize all inputs 
	 
	//ensure the the pop and push signal sent to ram and fifo are lasting one cycle
	
	
	//check if the push command is legal 
	
	//check if the pop command is legal by 
	//cheking whether min_valid is true
    
   
   //initializations
   // push_top
   // ram_manager
   // fifo_manager
  
   
endmodule // min_queue_top


// module pop_top(
	// input clk,
	// input rst_b, // 
	// input                             pop                           , //  read record command, accepted when min_valid is true.
	// output            [6*8-1:0]       pop_record                    , //  the record satisfy the min condition when min_valid is true.
	// input     reg                    min_valid                       // while min_valid is low we won't pop record from the 
    // input min_record,
	// output compare_queue,
    // input to_pull_queue,
    // input has_min_queue,
// );

// endmodule // pop_top

module push_top (
	input                             clk                           , // The clock signal from outside
	input                             rst_b                         , // 
		     
		     // push interface		     
	input                             push                          , //  write record cmd, accepted when full and push_wait are low
	input             [6*8-1:0]       push_record                   , //  new record data,
	output     reg                    full                          , //  no more space to hold records
	output     reg                    push_wait                     , //  indicate that no more space left in the input fifo, or push_top is busy
	input fifo_one_place_avail, 		// flag that signifies that only one place is left in the fifo
	input fifo_full, 					//  flag that signifies the the current fifo queue is full	

	input     reg                    min_valid ,
	input            [6*8-1:0]       min_record                    , //  the record satisfying the min condition when min_valid is true.
	output							record_to_push, 		// the record to be pushed
	output    					    push_to_fifo,			//boolean - whether the record is pushed to fifo
	output     						push_to_ram,			//boolean - whether the record is pushed to ram 
			 );

endmodule  // push_top
			 
			 
			 
			 
module FIFO_manager (
input clk,
input rst_b,

input push_to_fifo,				  //flag when high tells the fifo manager to put the push_record in the queue. the push_top sets it high/low. 
input             [6*8-1:0]       push_record, // the record to put in the queue
output fifo_one_place_avail, 		// flag that signifies that only one place is left in the fifo 
output fifo_full, 					//  flag that signifies the the current fifo queue is full
//output     reg                    push_wait   , NOT USED IN THIS DESIGN IN THE LEVEL OF FIFO, DEFINED IN PUSH TOP
output	empty, 						//  Telling whether we have records to pop from the queue or not. used by ram_manager 
input pop_from_fifo,				// this flag is set to high by the ram_manager after it (the ram manager) took the current value in pop_record. this means that the fifo_manager should put the now in the pop record the next item in queue. the ram_manager sets it to low when it doesn't need to get a new item from the queue. 
output  [6*8-1:0]       pop_record, // contains the upper most item in the fifo queue. 

inout compare_queue,  // flag is set by ram_manager and by the fifo_manager. when set to high by the ram manager the fifo buffer goes over all of the items that have value smaller then the new min_val (after a pop occured in the ram_manager) and returns the number of pop commands that the ram_manager has to execute (num_of_items_to_pop_for_min) in order to get all the record containing the values smaller than the current min_value (in the ram manager). fifo_manager turns it to low when a new relevant value was set to num_of_items_to_pop_for_min.
input min_record, // set by ram_manager contains the current min_record (this is the record to which the items in the queue will compared to when the compare_queue flag is high). 
output [2:0] num_of_items_to_pop_for_min, // is the number of items to be pulled from the queue to get all the contained value smaller than min_value, when the value is higher than 0 fifo_manager decrease it's value at each pop_from_fifo command that is executed.
);

reg [9:0] next_push;
reg [9:0] next_pop;
//reg [9:0] addread;
reg empty;
reg state;
reg countdat;
assign full = countdat==1024;
assign empty = countdat==0;

always @ (posedge clk)
if (!rst_b)
begin
state <= #1 0;
empty <= #1 1;
next_push <= #1 0;
next_pop <= #1 0;
full <= #1 0;
push_wait <= #1 0;
to_pull_queue <= #1 0;
has_min_queue <= #1 0;
wea <= #1 0;
countdat <= #1 0;
addra <= #1 0;
end
else begin
    if (push_queue)
	begin
	wea <= #1 1;
	addra <= #1 next_push;
	next_push <= #1 next_push+1;
	push_queue <= #1 0;
	countdat <= #1 countdat +1;
	end
	if (pop_queue)
	begin
	pop_record <= #1 doutb;
	next_pop <= #1 next_pop+1;
	countdat <= #1 countdat -1;
	pop_queue <= #1 0;
	end
    case(state)
	0: if (compare)
	begin
	if (!push_queue)
	begin
	wea <= #1 0;
	has_min_queue <= #1 0;
	state <= #1 1;
	checkindex <= #1 next_pop;
	end
	end
	
end




// ram_64x1024 input_ram (
  // .clka(clk), // input clka
  // .wea(wea), // input [0 : 0] wea
  // .addra(addra), // input [9 : 0] addra
  // .dina(push_record), // input [63 : 0] dina
  // .douta(douta), // output [63 : 0] douta
  // .clkb(clk), // input clkb
  // .web(web), // input [0 : 0] web
  // .addrb(next_pop), // input [9 : 0] addrb
  // .dinb(dinb), // input [63 : 0] dinb
  // .doutb(doutb) // output [63 : 0] doutb
// );			 
	 		 
endmodule // queue_in	

module ram_manager (
	input 		clk,
	input 		rst_b,
    output 		pop_from_fifo,				// when low signals the fifo_manager NOT to refresh the current fifo_pop_record. when high signals the fifo_manager to refresh the fifo_pop_record, which results with fifo_manager deleting the item at top of the queue and insert into pop_record the next item. the ram_manager will take care that the pop_from_fifo will be set to high for only 1 clock cycle. the reason it takes the pop_record, in the fifo_manager, one cycle to be refreshed after the pop_from_fifo was set to high. 
	inout 		compare_queue,  // flag is set by ram_manager and by the fifo_manager. when set to high by the ram manager the fifo buffer goes over all of the items that have value smaller then the new min_val (after a pop occured in the ram_manager) and returns the number of pop commands that the ram_manager has to ask from the fifo manager (num_of_items_to_pop_for_min) in order to get all the records containing the values smaller than the current min_value (in the ram manager). fifo_manager turns it to low when a new relevant value was set to num_of_items_to_pop_for_min.
	input [2:0] num_of_items_to_pop_for_min, // is the number of items to be pulled from the fifo queue to get all the contained value smaller than min_value, when the value is higher than 0 fifo_manager decrease its value at each pop_from_fifo command that is executed.
	input [6*8-1:0] record_to_push  , // containing the record pushed into RAM
	input push_to_ram, // when high signals the ram manager that it should store the record to push. 
	input pop_from_ram, // when high in parallel turn min_valid to low (means that we don't have a valid min_record, the assumption is that the outside code allready took the value in min_record when it was valid) and start the process of min_record updating to containg the record with the next minimal key value 
	output [6*8-1:0] min_record, //Contains the record with the min key val WHEN MIN_VALID IS HIGH!!! 
	output  min_valid, //High when min_record contains the record with min key value
);
			 
reg curr_min_record_address; // the address in the ram of the current min value record. 
reg curr_writing_address; // the address in the ram to which we will write the next record 


//ram_manager logic 

	always @(posedge)
	
		if(!rst_b)
			//init all of the inner variables
			begin
			
			end
		else
			begin
				//check if we have something to push to the ram
				if(push_to_ram)
					begin
						//do insertion sort. setting the min_valid to false
						min_valid <= #1 0; // when this is set to low, the push_wait in the top_module will be set to high signalling no more pushing
						
						// inner signal telling the ram manager to perform insertion of the value in record_to_push
						sort_ram <= #1 1; 
					end
				
				if(sort_ram)
					begin
						//here look where to put the record_to_push
						
						//... SORT LOGIC and insertion
						
						//if found and inserted
						if(sort_ram_finished)
							begin
								min_valid <= #1 1; // we can now pop from the queue the min record is valid
							end
					end
			end

endmodule		 
			 
			 
			 
			 
			 
			 
