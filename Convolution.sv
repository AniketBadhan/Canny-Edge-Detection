/*

	Author: Aniket Badhan
	Description: Performing convolution with guassian filter of 5X5, as the first step in the convolution of the Canny Edge Detection algorithm

*/


`timescale 1ns/1ps

module Convolution(
	input clk,
	input reset,
	input startConv,
	input [7:0] bufferInput [0:159],
	output reg convDone,
	output reg [7:0] bufferOutput [0:27]
);


	reg [4:0] outputCounter;
	reg [7:0] counter1;
	reg [16:0] tempSum;
	reg [16:0] tempSum1;
	reg [16:0] tempSum2;
	reg [16:0] tempSum3;
	reg [16:0] tempSum4;
	reg [16:0] tempSum5;
	reg [7:0] tempOutput;
	reg [4:0] filterCounter;
	reg [3:0] prevRowsCompleted;
	reg [3:0] currentRowsCompleted;
	reg [3:0] filter_matrix [0:24] = '{4'd2, 4'd4, 4'd5, 4'd4, 4'd2, 4'd4, 4'd9, 4'd12, 4'd9, 4'd4, 4'd5, 4'd 12, 4'd15, 4'd12, 4'd5, 4'd4, 4'd9, 4'd12, 4'd9, 4'd4, 4'd2, 4'd4, 4'd5, 4'd4, 4'd2};
	//filter_matrix: the guassian 5X5 matrix
	
	enum reg [1:0]{
		RESET,
		S_CONV,
		S_ConvDone1,
		S_ConvDone2
	}CS, NS;
	
	//Next State logic for the FSM
	always_ff @ (posedge clk, negedge reset) begin
		if(!reset) begin
			CS <= RESET;
		end
		else begin
			CS <= NS;
		end
	end
	
	//Combination logic always block of the FSM
	always_comb begin
		NS = RESET;
		case(CS) 
			RESET		:	begin
							tempSum = 0;
							tempOutput = 0;
							tempSum1 = 0;
							tempSum2 = 0;
							tempSum3 = 0;
							tempSum4 = 0;
							tempSum5 = 0;
							if(reset == 1'b1 && startConv == 1'b1) begin
								NS = S_CONV;
							end
							else begin
								NS = RESET;
							end
						end
			S_CONV		:	begin
							tempSum1 = bufferInput[counter1]*filter_matrix[0] + bufferInput[counter1+8'd1]*filter_matrix[1] + bufferInput[counter1+8'd2]*filter_matrix[2] + bufferInput[counter1+8'd3]*filter_matrix[3] + bufferInput[counter1+8'd4]*filter_matrix[4];
							tempSum2 = bufferInput[counter1+8'd32]*filter_matrix[5] + bufferInput[counter1+8'd33]*filter_matrix[6] + bufferInput[counter1+8'd34]*filter_matrix[7] + bufferInput[counter1+8'd35]*filter_matrix[8] + bufferInput[counter1+8'd36]*filter_matrix[9];
							tempSum3 = bufferInput[counter1+8'd64]*filter_matrix[10] + bufferInput[counter1+8'd65]*filter_matrix[11] + bufferInput[counter1+8'd66]*filter_matrix[12] + bufferInput[counter1+8'd67]*filter_matrix[13] + bufferInput[counter1+8'd68]*filter_matrix[14];
							tempSum4 = bufferInput[counter1+8'd96]*filter_matrix[15] + bufferInput[counter1+8'd97]*filter_matrix[16] + bufferInput[counter1+8'd98]*filter_matrix[17] + bufferInput[counter1+8'd99]*filter_matrix[18] + bufferInput[counter1+8'd100]*filter_matrix[19];
							tempSum5 = bufferInput[counter1+8'd128]*filter_matrix[20] + bufferInput[counter1+8'd129]*filter_matrix[21] + bufferInput[counter1+8'd130]*filter_matrix[22] + bufferInput[counter1+8'd131]*filter_matrix[23] + bufferInput[counter1+8'd132]*filter_matrix[24];
							tempSum = tempSum1+tempSum2+tempSum3+tempSum4+tempSum5;
							tempOutput = (tempSum >> 9) + (tempSum >> 8);
							if(outputCounter < 29) begin
								NS = S_CONV;
							end
							else begin
								NS = S_ConvDone1;
							end
						end
			S_ConvDone1	:	begin
							tempSum1 = 0;
							tempSum2 = 0;
							tempSum3 = 0;
							tempSum4 = 0;
							tempSum5 = 0;
							tempOutput = 0;
							tempSum = 0;
							NS = S_ConvDone2;
						end
			S_ConvDone2	:	begin
							tempSum1 = 0;
							tempSum2 = 0;
							tempSum3 = 0;
							tempSum4 = 0;
							tempSum5 = 0;
							tempOutput = 0;
							tempSum = 0;
							NS = RESET;
						end
											
		endcase
	end
	
	//Registerd output always block for the FSM
	always_ff @ (posedge clk, negedge reset) begin
		if(!reset) begin
			convDone <= 1'b0;
		end
		else begin
			case(CS)
				RESET		:	begin
								counter1 <= 0;
								outputCounter <= 0;
								currentRowsCompleted <= 0;
								prevRowsCompleted <= 0;
								convDone <= 1'b0;
							end
				S_CONV		:	begin
								convDone <= 1'b0;
								currentRowsCompleted <= prevRowsCompleted + 1'b1;
								if(counter1 == 0 || (counter1 + 8'd5) < currentRowsCompleted*6'd32) begin
									counter1++;
									prevRowsCompleted <= prevRowsCompleted + 1'b0;
								end
								else begin
									prevRowsCompleted <= prevRowsCompleted + 1'b1;
									counter1 <= prevRowsCompleted*6'd32;
								end
								bufferOutput[outputCounter] <= tempOutput;
								outputCounter <= outputCounter + 1'b1;
							end
				S_ConvDone1	:	begin
								convDone <= 1'b1;
							end
				S_ConvDone2	:	begin
								convDone <= 1'b1;
							end
			endcase
		end
	end
	
endmodule
