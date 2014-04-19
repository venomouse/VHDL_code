`timescale 1 ns / 1 ns

module queue#(parameter depth = 1024, parameter ptr_wd = 10)(
	input     			clk									,
	input     			rst									,
	input    			push								,
	input    			pop									,
	output   			full								,
	output    			empty								,
	output reg   		min_valid							,
	output reg   		[6*8-1:0] Q_top						,
	input     			[6*8-1:0] push_record				,
	output    			[6*8-1:0] pop_record
		);
 
	wire cs_a, cs_b, rnw_a, rnw_b;
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


	tdp_ram_48w_1024_coregen ram(
						.clk			(clk			),
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

										  

endmodule // queue 
