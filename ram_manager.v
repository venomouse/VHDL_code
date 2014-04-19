`timescale 1ns / 1ns

`define IDLE 					4'd0
`define START_PUSH				4'd1
`define START_POP				4'd2				
`define POP_REGULAR 			4'd3
`define POP_MULTIKEY			4'd4
`define MULTIKEYS_FULL			4'd5
`define MULTIKEYS_NOT_FULL		4'd6
`define PUSH_RECORD_TO_HEAP		4'd7
`define ADD_RECORD_TO_MULTIKEY	4'd8
`define NEW_MULTIKEY			4'd9

`define RECORD_LENGTH			6*8
`define ADDRESS_LENGTH			10
`define KEY_LENGTH				32
`define KEY_START 				16
`define MAX_NUM_MULTIKEYS		4


module ram_manager (
	input 							clk,
	input 							rst_b,
	
	input 							push_to_ram, // when high signals the ram manager that it should store the record to push. 
	input [6*8-1:0] 				record_to_push  , // containing the record pushed into RAM
	
	input 							pop_from_ram, // when high in parallel turn min_valid to low (means that we don't have a valid min_record, the assumption is that the outside code allready took the value in min_record when it was valid) and start the process of min_record updating to containg the record with the next minimal key value 
	output reg [6*8-1:0] 			min_record, //Contains the record with the min key val WHEN MIN_VALID IS HIGH!!! 
	output reg 						min_valid, //High when min_record contains the record with min key value
	output 							empty
);
			 
	
	wire  eq_mk_1, eq_mk_2, eq_mk_3, eq_mk_4;
	
	reg 								sorting;
	reg [`KEY_LENGTH-1 : 0]				key_to_push;
	reg [`KEY_START -1 : 0]				value_to_push;
	reg [3:0]							state;
	reg [2:0]							num_multikeys;				//current number of active multikeys
	wire 								multikeys_full;
	
	
	reg [`KEY_LENGTH-1:0]  				multikeys[3:0];
	reg [`ADDRESS_LENGTH-1:0]			curr_write_add;
	reg [`ADDRESS_LENGTH-1:0]			curr_min_add;
	
	

	//all things dealing with memory
	
	wire 								cs_a, cs_b, rnw_a, rnw_b;
	wire [`ADDRESS_LENGTH-1:0]			a_add;
	wire [`ADDRESS_LENGTH-1:0]			b_add;
	wire [`RECORD_LENGTH-1 :0]			a_data_in;
	wire [`RECORD_LENGTH-1 :0]			a_data_out;
	wire [`RECORD_LENGTH-1 :0]			b_data_in;
	wire [`RECORD_LENGTH-1 :0]			b_data_out;
	
	
	tdp_ram #(.data_wd(`RECORD_LENGTH), .add_wd(`ADDRESS_LENGTH)) ram (
		.clk				(clk),
		.cs_a				(cs_a),
		.rnw_a				(rnw_a),
		.a_add				(a_add),
		.a_data_in			(a_data_in),
		.a_data_out			(a_data_out),
		.cs_b				(cs_b),
		.rnw_b				(rnw_b),
		.b_add				(b_add),
		.b_data_in			(b_data_in),
		.b_data_out			(b_data_out)
	);

//assignments
		assign multikeys_full 	= (num_multikeys == `MAX_NUM_MULTIKEYS);
		assign empty 			= (curr_write_add == 0);
		assign rnw_a	= 1'b0;
		assign rnw_b 	= 1'b1;
		assign cs_a		= (push_to_ram || sorting) ;
		assign cs_b 	= (pop_from_ram || sorting);
		assign a_data_in 	= record_to_push; 
		assign a_add		= curr_write_add;
		assign b_add 		= curr_min_add;
		
//ram_manager logic 

	always @(posedge clk)
	
		if(!rst_b)
			//init all of the inner variables
			begin
				sorting 		<=  #1 0; 
				min_valid 		<=	#1 1;
				min_record 		<=	#1 0;
				state 			<= 	#1 `IDLE;
				curr_write_add 	<=  #1 0;
				curr_min_add 	<=  #1 0;
				
			end
		else
			begin
				case (state)
					`IDLE:
						begin 
							if (pop_from_ram)
								begin 
								sorting 	<= #1 1;
								state 		<= #1 `START_POP;
								end
							else if (push_to_ram)
								begin 
								sorting 	<= #1 1;
								state 		<= #1 `PUSH_RECORD_TO_HEAP;
								end
						end
					
					`START_PUSH:
						begin
							min_valid		<= #1 0;
							//
							if (multikeys_full)
								begin 
									state			<= #1 `MULTIKEYS_FULL;
								end
							else
								begin
									state 			<= #1 `MULTIKEYS_NOT_FULL;
								end
						end
						
					`START_POP:
						begin
							// fetch the minimum record from ram
							// if its duplicate bit is 0, pop as regular record
							// if its duplicate bit is 1, pop as duplicate
							min_record			<= #1 b_data_out;
							curr_min_add 		<= #1 curr_min_add + 1;
							sorting 			<= #1 0;
							state 				<= #1 `IDLE;
						end
						
					`MULTIKEYS_FULL:
						begin
							
						
						end
						
					`PUSH_RECORD_TO_HEAP:
						begin
							curr_write_add 		<= #1 curr_write_add + 1;
							sorting 			<= #1 0;
							state 				<= #1 `IDLE;
						end

					
					
				endcase
			end
	

	
endmodule //ram_manager		 