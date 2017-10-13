/*

	Author: Aniket Badhan
	Description: Performing convolution with Sobel filter(3X3) for horizontal and vertical edges detection, as the second step in the convolution of the Canny Edge Detection algorithm
			Sobel Horizontal Filter = {-1, 0, 1; -2, 0, 2; -1, 0, 1}
			Sobel Vertical Filter = {-1, -2, -1; 0, 0, 0; 1, 2, 1}
*/

`timescale 1ns/1ps

module Convolution_Step2(
	input clk,
	input reset,
	input startConv,
	input [7:0] bufferInput [0:83],
	output reg convDone,
	output reg [12:0] bufferOutputHor [0:25],
	output reg [12:0] bufferOutputVer [0:25]
);

	reg [5:0] outputCounter;
	reg [7:0] counter1;

	reg [10:0] tempSum1;
	reg [10:0] tempSum2;
	reg [10:0] tempSum3;
	reg [12:0] tempSum4;
	reg [10:0] tempSum5;
	reg [10:0] tempSum6;
	reg [12:0] tempSum7;

	reg [3:0] prevRowsCompleted;
	reg [3:0] currentRowsCompleted;
	
	enum reg [1:0]{
		RESET,
		S_CONV,
		S_ConvDone
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
							tempSum1 = 0;
							tempSum2 = 0;
							tempSum3 = 0;
							tempSum4 = 0;
							tempSum5 = 0;
							tempSum6 = 0;
							tempSum7 = 0;
							if(reset == 1'b1 && startConv == 1'b1) begin
								NS = S_CONV;
							end
							else begin
								NS = RESET;
							end
						end
			S_CONV		:	begin
							tempSum1 = ({2'b0, bufferInput[counter1]})*(-1) + ({2'b0, bufferInput[counter1 + 8'd2]});
							tempSum2 = ({2'b0, bufferInput[counter1+8'd28]})*(-2) + ({2'b0, bufferInput[counter1 + 8'd30]})*2;
							tempSum3 = ({2'b0, bufferInput[counter1+8'd56]})*(-1) + ({2'b0, bufferInput[counter1 + 8'd58]});
							tempSum4 = {{2{tempSum1[10]}},tempSum1} + {{2{tempSum2[10]}},tempSum2} + {{2{tempSum3[10]}},tempSum3}; 			//Sobel Horizontal Edge Detector
								
							tempSum5 = ({2'b0, bufferInput[counter1]})*(-1) + ({2'b0, bufferInput[counter1+8'd1]})*(-2) + ({2'b0, bufferInput[counter1+8'd2]})*(-1);
							tempSum6 = ({2'b0, bufferInput[counter1+8'd56]}) + ({2'b0, bufferInput[counter1 + 8'd57]} << 1) + ({2'b0, bufferInput[counter1 + 8'd58]});
							tempSum7 = {{2{tempSum5[10]}},tempSum5} + {{2{tempSum6[10]}},tempSum6}; 										//Sobel Vertical Edge Detector
							
							if(outputCounter < 28) begin
								NS = S_CONV;
							end
							else begin
								NS = S_ConvDone;
							end
						end
			S_ConvDone	:	begin
							tempSum1 = 0;
							tempSum2 = 0;
							tempSum3 = 0;
							tempSum4 = 0;
							tempSum5 = 0;
							tempSum6 = 0;
							tempSum7 = 0;
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
								if(counter1 == 0 || (counter1 + 8'd3) < currentRowsCompleted*8'd28) begin
									counter1 <= counter1 + 1'b1;
									prevRowsCompleted <= prevRowsCompleted + 1'b0;
								end
								else begin
									prevRowsCompleted <= prevRowsCompleted + 1'b1;
									counter1 <= prevRowsCompleted*8'd28;
								end
								bufferOutputHor[outputCounter] <= tempSum4;
								bufferOutputVer[outputCounter] <= tempSum7;
								outputCounter <= outputCounter + 1'b1;
							end
				S_ConvDone	:	begin
								convDone <= 1'b1;
							end
			endcase
		end
	end
	
endmodule
