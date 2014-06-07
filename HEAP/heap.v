`timescale 1 ns / 1 ns


`define HEAP_MAX_DEPTH 				10
`define REC_WIDTH 					6*8 
`define KEY_WIDTH 	  				4*8
`define PL_WIDTH  					2*8
`define STATE_HEAP_IDLE            	4'd0
`define STATE_DOWN_HEAPIFY		   	4'd1
`define STATE_UP_HEAPIFY		   	4'd2				
`define STATE_COMPARE_NODES	   	   	4'd3
`define STATE_COMPARE_TWO_NODES    	4'd4



module heap_maxheapfy#(parameter heap_depth = `HEAP_NAX_DEPTH, parameter add_width = `ADD_WIDTH, parameter rec_width = `REC_WIDTH)(
	input     			clk									,
	input     			rst									,
	
	input    			push_to_heap						,  // push the record currently in the push record (commencing heapify up)
	input    			pop_from_heap						,  // pop the record from the heap (commencing heapify down)
	output    			empty								,
	output reg   		min_valid							,
	output reg   		[rec_width-1:0] heap_root			,
	input     			[rec_width-1:0] push_record			,
	output    			[rec_width-1:0] pop_record			,
		);
	
	
	reg [3:0] heap_state; 	//register containing the heap machine state

	wire cs_a, cs_b, rnw_a, rnw_b; 											// memory commands
	wire [rec_width-1 : 0] a_data_out, b_data_out, a_data_in, b_data_in;	// memory inputs and outputs
	reg  [heap_depth-1 :  0] parent_node_add,left_node_add, right_node_add;	// this wires are driven by the value of the register node_add
	reg  [add_width-1 :  0] last_node_add;									//containing the address of the last node (the available node)
	reg  [add_width-1 :  0] node_add;										//containing the address of the node 
	reg  [add_width-1 :  0] curr_node_add;              					//containing the current address of the push_record (used in the bubble process)
	

	
	// **** cs_a assigment (when is should be true) ***//
	
	// decision lines for the the states //
	
	//decision lines for memory//
	assign should_read_a (cs_a == 1'b1) && (rnw_a == 1'b1);
	assign should_read_b (cs_b == 1'b1) && (rnw_b == 1'b1);
	
	always @(posedge_clk)
		if(!rst)
			begin
				// *** init all the regs with zeros ***//
				last_node <= #1 0;
				parent_node_add <= #1 0;
				curr_node_add <= #1 0;
				node_add <= #1 0;
				wait_for_ram  <= #1 0;
				heap_state <= #1 `STATE_HEAP_IDLE; // setting the heap state to zero
			end
		else 
			// deal with reading from memory
			read_valid_a <= #1 should_read_a;
			read_valid_b <= #1 should_read_b;
			
			if(read_valid_a)
				a_data_out <= #1 a_data_out_real;
				
			if(read_valid_b)
				b_data_out <= #1 b_data_out_real;
				
			case(heap_state)  // this should translate to a mux with 5 entries
			`STATE_HEAP_IDLE:
				begin					
					//not a lot to do here beside of checking if a push command was set
					if (push_to_heap)
						begin
							
							last_node_add <= #1 last_node_add + 1; // increasing the last node available address by 1
							min_valid <= #1 0;
							heap_state <= #1 `STATE_UP_HEAPIFY; // change the state to up heapify
						end
					else if(pop_from_heap)
						begin
							//change the state to 
							last_node_add <= #last_node_add - 1;
							min_valid <= #1 0;
							heap_state <= #1 `STATE_DOWN_HEAPIFY;
						end
					else
						begin
							min_valid <= #1 1;
						end
				end
			`STATE_UP_HEAPIFY:
				begin
					
					//check if we have a parent node to compare with
					if (last_node_add == 1) 
						begin
							// *** setting the memory to write in address 
						end
					else
						begin
							if (curr_node_add != 1) 
								begin
									
								end
							else
								begin
									//the push_record_key is in the top node. we can return to idle
									heap_state <= #1 `STATE_HEAP_IDLE;
									min_valid <= #1 1;
								end
						end
					
				end
			`STATE_COMPARE_NODES:
				begin
					//checking the node_key  (later check it by the decision line)
					if (node_key > push_record_key)
						begin
							//if we are here a switch is needed. The switch is performed by setting the memory.
							
							curr_node_add <= #1 node_add;         //when we switch we have to update the curr_node_add address
							heap_state <= #  1 `STATE_UP_HEAPIFY; // changing the state back to up_heapify, where we 
						end
					else
						begin
							//no switch is needed
							heap_state <= #1 `STATE_HEAP_IDLE;
							min_valid <= # 1 1;
						end
				end
				
			`STATE_DOWN_HEAPIFY:
				begin
					//peform use the two ports to write the value to each address
					
					//go back to state_up_heapfiy
				end
			
			`STATE_COMPARE_TWO_NODES:
				begin
					//peform use the two ports to write the value to each address
					
					//go back to state_up_heapfiy
				end
			end	
			  
	tdp_ram #(rec_width,add_wd) ram(
				.clk			(!clk			), // so the command would occure in the same cycle. 
				
				.cs_a			(cs_a			),
				.rnw_a			(rnw_a			), 
				.a_add			(a_add			),
				.a_data_in		(a_data_in		),
				.a_data_out		(a_data_out		),
					 
				.cs_b			(cs_b			),
				.rnw_b			(rnw_b			),
				.b_add			(b_add			),
				.b_data_in		(b_data_in		),
				.b_data_out		(b_data_out		)
								);
								
	task adjust_pointers;
		input [log_tree_size-1:0]  new_pointer_value;
	
		begin
			pointer <= #1 new_pointer_value;
			parent_pointer <= #1 parent(new_pointer_value); 
			parent_parent_pointer  <= #1 parent(parent(new_pointer_value));
			three_parent_pointer  <= #1 parent(parent(parent(new_pointer_value))); 
			left_child_pointer <= #1 { new_pointer_value[log_tree_size-1:0], 1'b1 };
			right_child_pointer <= #1 { new_pointer_value[log_tree_size-1:0], 1'b0 } + 2;
		end
	endtask
	

	wire heapify, swap, swap_up, swap_right, swap_left;
	wire [ptr_wd-1:0] heap_idx1, heap_idx2, idx_down1, idx_down2;
	wire [ptr_wd-1:0] a_add, b_add;
	wire [6*8-1:0] a_data_out, b_data_out, a_data_in, b_data_in;
	wire [6*8-1:0] flip_value, heap_data1, heap_data2;
	reg heapify_up, heapify_down, rd_cyc, flip_head, push_to_top;
	reg [6*8-1:0] out_record, sample_value;
	reg [ptr_wd-1:0] last_idx, idx_up1, idx_up2, left_idx, right_idx;
	
	
	always @(posedge clk)
	
		if(!rst) 										// reset the queue
		 begin
			heapify_up 		<= #1 0;
			heapify_down 	<= #1 0;
			rd_cyc 			<= #1 0;
			idx_up1			<= #1 0;
			idx_up2 		<= #1 0;
			left_idx 		<= #1 0;
			right_idx 		<= #1 0;	
			last_idx 		<= #1 1;
			min_valid 		<= #1 0;
			push_to_top 	<= #1 0;
			flip_head 		<= #1 0;
			out_record 		<= #1 0;
			sample_value 	<= #1 0;
			Q_top 			<= #1 0;
		end
		
		else if(heapify_up)								// heapify_up this organize the data base.
 		 begin
			if(rd_cyc) 
			 begin
				rd_cyc 		<= #1 0;
			end
			else if(idx_up1 == 1) 
			 begin
				min_valid 	<= #1 1;
				heapify_up 	<= #1 0;
				if(swap_up) 
					Q_top 	<= #1 b_data_out;
			end
			else if(swap_up)
			 begin
				idx_up2 	<= #1 idx_up2 >> 1;
				idx_up1 	<= #1 idx_up1 >> 1;
				rd_cyc 		<= #1 1;
			end
			else 
			 begin
				min_valid 	<= #1 1;
				heapify_up 	<= #1 0;
			end
		end
			
		else if(heapify_down) 							// heapify_down this organize the data base.
		 begin
			if(flip_head) 
			 begin
				flip_head 			<= #1 0;
				out_record 			<= #1 a_data_out;
				if(push_to_top)
				 begin
					push_to_top 	<= #1 0;
					sample_value 	<= #1 push_record;
				end
				else 
					sample_value 	<= #1 b_data_out;
			end

			if(left_idx >= last_idx && right_idx >= last_idx) 
			 begin
				min_valid 			<= #1 !empty;
				heapify_down 		<= #1 0;
				if(right_idx >> 1 	== 	1) 
						Q_top 		<= #1 flip_value;
			end
			else if(rd_cyc) 
			 begin
				rd_cyc 				<= #1 0;
			end
			else if(swap_left)
			 begin
				left_idx 			<= #1 left_idx << 1;
				right_idx 			<= #1 (left_idx << 1) + 1;
				rd_cyc 				<= #1 1;
				if(left_idx[ptr_wd - 1] || right_idx[ptr_wd - 1]) 
				 begin
					heapify_down 	<= #1 0;
					min_valid 		<= #1 1;
				end
				if(right_idx >> 1 	== 	1) 
						Q_top 		<= #1 a_data_out;
			end
			else if(swap_right) 
			 begin
				left_idx 			<= #1 right_idx << 1;
				right_idx 			<= #1 (right_idx << 1) + 1;
				rd_cyc 				<= #1 1;
				if(left_idx[ptr_wd - 1] || right_idx[ptr_wd - 1]) 
				 begin
					heapify_down 	<= #1 0;
					min_valid 		<= #1 1;
				end
				if(right_idx >> 1 	== 	1) 
						Q_top 		<= #1 b_data_out;
			end
			else 
			 begin
				min_valid 			<= #1 !empty;
				heapify_down 		<= #1 0;
				right_idx 			<= #1 0 - 1;
				if(right_idx >> 1 	== 1) 
						Q_top 		<= #1 flip_value;
			end
		end
		
		else if(push && pop && !full && !empty)       	// This synchronize between push and pop. 
		 begin
			heapify_down 			<= #1 1;	// has to heapify to turn off the flip_head 
			min_valid 				<= #1 0;
			rd_cyc 					<= #1 1;
			left_idx 				<= #1 2;
			right_idx 				<= #1 3;
			flip_head 				<= #1 1;
			push_to_top				<= #1 1;
		end

		else if(push && !full) 							// This push to data base. 
		 begin
			last_idx				<= #1 last_idx + 1;
			heapify_up 				<= #1 !empty;
			min_valid				<= #1 empty;
			rd_cyc 					<= #1 1;
			idx_up1 				<= #1 last_idx >> 1;
			idx_up2 				<= #1 last_idx;
			if(empty) 
				Q_top 				<= #1 push_record;
		end
		
		else if(pop && !empty)							// This pop from data base.
		 begin
			last_idx 				<= #1 last_idx - 1;
			heapify_down			<= #1 1;	// has to heapify to turn off the flip_head 
			min_valid				<= #1 0;
			rd_cyc 					<= #1 0;
			left_idx 				<= #1 1;
			right_idx 				<= #1 0;
			flip_head 				<= #1 1;
		end
	
	assign empty 		= (last_idx == 1);
	assign full 		= (last_idx == 0);
	
	assign cs_a 		= ((pop && !empty) || heapify);
	assign cs_b 		= ((push && !full) || (pop && !empty) || heapify);
	assign rnw_a 		= heapify ? (!swap || rd_cyc) : !(push && pop);
	assign rnw_b 		= heapify ? (!swap || rd_cyc) : !push || pop;
	
	assign a_add 		= heapify ? heap_idx1 : 1;
	assign b_add 		= heapify ? heap_idx2 : ((push && !pop) ? last_idx : last_idx - 1);
	
	assign heap_idx1 	= heapify_up ? idx_up1 : idx_down1;
	assign heap_idx2 	= heapify_up ? idx_up2 : idx_down2;
	assign heapify 		= heapify_up || heapify_down;
	
	assign idx_down1 	= (rd_cyc 	 || swap_left) ? left_idx : right_idx;
	assign idx_down2 	= (rd_cyc) 	 ? right_idx : right_idx >> 1;
	
	assign a_data_in 	= heapify 	? heap_data1 : push_record;
	assign b_data_in  	= heapify 	? heap_data2 : push_record;
	
	assign pop_record 	= flip_head ? a_data_out : out_record;

	assign heap_data1 	= heapify_down ? flip_value : b_data_out;
	assign heap_data2 	= (heapify_down && swap_right) ? b_data_out : a_data_out;
	assign flip_value 	= flip_head ? ( b_data_out) : sample_value;

		  //********************** SWAP'S DEFINITION ************************//
	assign swap 		= swap_up || swap_left || swap_right;	  
	assign swap_up 		= (b_data_out[6*8-1:2*8] < a_data_out[6*8-1:2*8]) 	&& 
														heapify_up && !rd_cyc;
	assign swap_right 	= (b_data_out[6*8-1:2*8] < flip_value[6*8-1:2*8]) 	&& 
						  (b_data_out[6*8-1:2*8] < a_data_out[6*8-1:2*8]) 	&& 
							(right_idx < last_idx) && heapify_down && !rd_cyc;
	assign swap_left 	= (a_data_out[6*8-1:2*8] < flip_value[6*8-1:2*8]) 	&& 
						  ((b_data_out[6*8-1:2*8] >= a_data_out[6*8-1:2*8]) || 
							(right_idx >= last_idx))&& heapify_down && !rd_cyc;




										  

endmodule // queue 
