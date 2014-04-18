`timescale 1ns / 1ns

`define IDLE 					4'd0
`define START_PUSH				4'd1
`define START_POP				4'd2				
`define POP_REGULAR 			4'd3
`define POP_MULTIKEY			4'd4
`define MULTIKEYS_FULL			4'd5
`define MULTIKEYS_NOT_FULL		4'd6
`define ADD_RECORD_TO_HEAP		4'd7
`define ADD_RECORD_TO_MULTIKEY	4'd8
`define NEW_MULTIKEY			4'd9

`define RECORD_LENGTH			6*8
`define KEY_LENGTH				32
`define KEY_START 				16
`define MAX_NUM_MULTIKEYS		4


module ram_manager (
	input 							clk,
	input 							rst_b,
	
	input 							push_to_ram, // when high signals the ram manager that it should store the record to push. 
	input [6*8-1:0] 				record_to_push  , // containing the record pushed into RAM
	
	input 							pop_from_ram, // when high in parallel turn min_valid to low (means that we don't have a valid min_record, the assumption is that the outside code allready took the value in min_record when it was valid) and start the process of min_record updating to containg the record with the next minimal key value 
	output 							[6*8-1:0] min_record, //Contains the record with the min key val WHEN MIN_VALID IS HIGH!!! 
	output  						min_valid, //High when min_record contains the record with min key value
);
			 
	
	wire  eq_mk_1, eq_mk_2, eq_mk_3, eq_mk_4;
	
	reg [`RECORD_LENGTH-1:`KEY_START]	key_to_push;
	reg [`KEY_START -1 : 0]				value_to_push;
	reg [3:0]							state;
	reg [3:0]							num_multikeys;				//current number of active multikeys
	reg 								multikeys_full;
	
	
	reg [`KEY_LENGTH-1:0]  multikey_1, multikey_2, multikey_3,multikey_4; 
	
	
	
	assign multikeys_full = (num_multikeys == `MAX_NUM_MULTIKEYS);

//ram_manager logic 

	always @(posedge)
	
		if(!rst_b)
			//init all of the inner variables
			begin
				min_valid 		<=	#1 0;
				min_record 		<=	#1 0;
				state 			<= 	#1 `IDLE;
				
			end
		else
			case (state)
				`IDLE:
					begin 
						if (pop_from_ram)
							state 		<= #1 `START_POP;
						else if (push_to_ram)
							state 		<= #1 `START_PUSH;
					end
				
				`START_PUSH:
					begin
						min_valid		<= #1 0;
						//
						if (multikeys_full)
							state			<= #1 `MULTIKEYS_FULL;
						else
							state 			<= #1 `MULTIKEYS_NOT_FULL;
					end
					
				`START_POP:
					begin
						// fetch the minimum record from ram
						// if its duplicate bit is 0, pop as regular record
						// if its duplicate bit is 1, pop as duplicate
					end
					
				`MULTIKEYS_FULL:
					begin
						
					
					end

				`
				
			end
			
	

	
endmodule //ram_manager		 