`timescale 1ns / 1ns

`define RECORD_LENGTH		48
`define NUM_OF_RECORDS      11'd1014;


`define STATE_IDLE 4'd0
`define STATE_POP 4'd1
`define STATE_AFTER_POP 4'd2


module min_queue_top  #(parameter q_depth=1024, parameter ptr_wd=10) (
	input                             clk                           , // 
	input                             rst_b                         , // 
		     
		     // push interface		     
	input                             push                          , //  write record cmd, accepted when full and push_wait are low
	input             [6*8-1:0]       push_record                   , //  new record data,
	output     reg                    full                          , //  no more space to hold records
	output     reg                    push_wait                     , //  indicate that no more space left in the input fifo,
				
		     // pop interface
	input                             pop                           , //  read record command, accepted when min_valid is true.
	output            [6*8-1:0]       pop_record                    , //  the record satisfy the min condition when min_valid is true.
	output     reg                    empty                         , //  queue is abselutly empty
	output     reg                    min_valid                       //  pop_record in the min key record for this cycle.
		     );

			 
	wire fifo_full;
	wire fifo_empty;
	wire [`RECORD_LENGTH-1:0]  fifo_pop_record;
	
	//state machine
	reg [3:0]			pop_state;
	
	//fifo interface
	wire compare_queue;
	wire fifo_min_valid;
	wire [`RECORD_LENGTH-1:0] fifo_min_record;
	reg 		push_to_fifo;
	reg 		pop_from_fifo;
	
	//temp-heap interface
	wire 	[ptr_wd-1:0]	occupied_positions;
	wire 	[ptr_wd-1:0]	free_positions;
	wire 					push_request;
	wire 					heap_min_valid;
	reg 					push_ready;
	reg  					min_valid_prev;
	reg 					push_sync; 
	wire 					pop_from_heap;
	

	
	assign compare_queue = 1'b0;
	assign pop_from_heap = pop && min_valid;
	
	always @(posedge clk)
		if (!rst_b)
			begin 
				push_wait	<= #1 0;
				min_valid_prev <= #1 0;
				pop_from_fifo <= #1 0;
			
			end
		else
			begin 
				//temp
				push_wait <=  #1 fifo_full || (compare_queue && !fifo_min_valid);
				full 	<= #1 fifo_full && free_positions == 0;
				empty <=  #1 fifo_empty && occupied_positions == 0;
				min_valid <=  #1 heap_min_valid && (fifo_empty || fifo_min_valid);
					
				if (push_request == 1)
							pop_from_fifo <= #1 1;
				else 
							pop_from_fifo <= #1 0;
							
					
				push_ready <=  #1 (heap_min_valid || occupied_positions == 0) && !fifo_empty;
				
			end

	always @(posedge clk)
		if (!rst_b)
			pop_state <= #1 0;
		else
			case (pop_state)
				`STATE_IDLE:
				`STATE_POP:
				`STATE_AFTER_POP:
			endcase
				
			

		
	fifo_manager_hananel fifo_manager (
				.clk			(clk), 
				.rst_b			(rst_b),
				.push_to_fifo	(push), 
				.push_record	(push_record), 
				.fifo_full		(fifo_full),
				.fifo_empty		(fifo_empty),
				//temp
				.pop_from_fifo	(pop_from_fifo),
				.pop_record		(fifo_pop_record),
				.compare_queue	(compare_queue),
				.fifo_min_record(fifo_min_record),
				.fifo_min_val	(fifo_min_valid)
				);

	min_queue_data uri_heap (
				.clk			(clk),
				.rst_b			(rst_b),
				.pop			(pop_from_heap),
				.pop_record		(pop_record), 
				.min_valid		(heap_min_valid),
				.push_ready		(push_ready),
				.push_request	(push_request),
				.push_record	(fifo_pop_record),
				.occupied_positions (occupied_positions),
				.free_positions		(free_positions)
				);
   
endmodule // min_queue_top

