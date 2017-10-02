/*
	Author: Aniket Badhan
	Description: Accepting the pixel values as input from the testbench (4 bytes at a time), performing convolution with guassian filter in step 1
				 and sobel vertical and horizontal filters. Output send in form of 2 bytes after both the steps are completed
				 
*/

`timescale 1ns/1ps

module EdgeDetector(
	input clk,
	input reset,
	input chipSelect,
	input [31:0] readMem,
	output reg [15:0] writeMem,
	output reg finalConvDone
);

	logic [7:0] inputConv1 [0:159];							//Input to first convolution step, size 5X32
	logic [7:0] inputConv2 [0:83];							//Input to second convolution step, size 3X28
	
	logic [7:0] shiftBuffer [0:1023];						//Storing the Image from the Memory, size of image 32X32
	logic [7:0] bufferOutputConv1 [0:783];						//Storing Output from First Convolution Step
	logic [12:0] bufferOutputConv2 [0:675];						//Storing Output from Second Convolution (a) Step
	logic [12:0] bufferOutputConv3 [0:675]; 					//Storing Output from Second Convolution (b) Step
	
	logic [16:0] readCounter = 0;							//to read the data in to the shift buffer (original image)
	
	logic [7:0] outputConv1 [0:27];							//output from First Convolution step
	logic [12:0] outputConv2 [0:25];						//output from Second Convolution (a) step
	logic [12:0] outputConv3 [0:25];						//output from Second Convolution (b) step
	
	logic convDone1;								//Signalling 1 iteration of Convolution Step 1 done
	logic convDone2;								//Signalling 1 iteration of Convolution Step 2(a) done
	logic convDone3;								//Signalling 1 iteration of Convolution Step 2(b) done
	
	logic startConv1;
	logic startConv2;
	
	logic [8:0] inputCounter1;
	logic [8:0] inputCounter2;
	
	logic [9:0] rowsCompleted1 = 0;
	logic [9:0] rowsCompleted2 = 0;
	
	logic [15:0] counter1 = 0;
	logic [15:0] counter2 = 0;
	
	logic [15:0] outputCounter1 = 0;
	logic [15:0] outputCounter2 = 0;
	
	shortint i = 0;
	shortint j = 0;
		
	enum logic [3:0]{
		S_RESET,
		S_MEMREAD,
		S_CREATEINPUT1,
		S_CONV1,
		S_WAIT1,
		S_CREATEINPUT2,
		S_CONV2,
		S_WAIT2,
		S_SENDOUTPUT1,
		S_SENDOUTPUT2
	} CS, NS;
	
	Convolution C1(
		.clk(clk),
		.reset(reset),
		.startConv(startConv1),
		.bufferInput(inputConv1),
		.convDone(convDone1),
		.bufferOutput(outputConv1)
	);
	
	Convolution_Step2 C2(
		.clk(clk),
		.reset(reset),
		.startConv(startConv2),
		.bufferInput(inputConv2),
		.convDone(convDone2),
		.bufferOutputHor(outputConv2),
		.bufferOutputVer(outputConv3)
		
	);
	
	//Next State Logic
	always_ff @ (posedge clk, negedge reset) begin
		if(!reset) begin
			CS <= S_RESET;
		end
		else begin
			CS <= NS;
		end
	end	
	
	//Combinational Logic
	always_comb begin
		startConv1 = 0;
		startConv2 = 0;
		case(CS)
			S_RESET		:	begin
							if(chipSelect == 1'b1) begin			
								NS = S_MEMREAD;
							end
							else begin
								NS = S_RESET;
							end
						end
			S_MEMREAD	:	begin															//Data is read from the memory in to the buffer in this state
							if(readCounter < 1024) begin
								NS = S_MEMREAD;
							end
							else begin
								NS = S_CREATEINPUT1;
							end
						end
			S_CREATEINPUT1  :	begin															//input buffer of 5X32 is created for convolution in first step.
							if(inputCounter1 < 160) begin
								NS = S_CREATEINPUT1;
								startConv1 = 0;
							end
							else begin
								NS = S_CONV1;
								startConv1 = 1;
							end
						end
			S_CONV1		:	begin															// Convolution with the Guassian Filter is performed in this state
							if(!convDone1) begin
								NS = S_CONV1;
							end
							else begin
								if(rowsCompleted1 > 28 && convDone1) begin
									NS = S_CREATEINPUT2;
									startConv1 = 0;
								end
								else begin
									NS = S_WAIT1;
									startConv1 = 0;
									end
							end
						end
			S_WAIT1		:	begin
							NS = S_CREATEINPUT1;
							startConv1 = 0;
							end
			S_CREATEINPUT2  :	begin															//input buffer of 3X28 is created for convolution in second step.
							if(inputCounter2 < 84) begin
								NS = S_CREATEINPUT2;
								startConv2 = 0;
							end
							else begin
								NS = S_CONV2;
								startConv2 = 1;
							end
						end
			S_CONV2		:	begin															//Convolution with the Horizontal and Vertical Sobel Filter is performed in this state
							if(!convDone2) begin
								NS = S_CONV2;
							end	
							else begin	
								if(rowsCompleted2 > 26 && convDone2) begin
									NS = S_SENDOUTPUT1;
									startConv2 = 0;
								end
								else begin
									NS = S_WAIT2;
									startConv2 = 0;
								end
							end
						end
			S_WAIT2		:	begin
							NS = S_CREATEINPUT2;
							startConv2 = 0;
						end
			S_SENDOUTPUT1	:	begin															//values from convolution with horizontal sobel filter is sent through the output
							if(outputCounter1 < 676) begin
								NS = S_SENDOUTPUT1;
							end
							else begin
								NS = S_SENDOUTPUT2;
							end
						end
			S_SENDOUTPUT2	:	begin															//values from convolution with vertical sobel filter is sent through the output
							if(outputCounter2 < 676) begin
								NS = S_SENDOUTPUT2;
							end
							else begin
								NS = S_RESET;
							end
						end
		endcase
	end
	
	//Registered operations
	always_ff @ (posedge clk, negedge reset) begin
		if (!reset) begin
			finalConvDone <= 0;
		end
		else begin
			case(NS)
				S_RESET		:	begin
								inputCounter1 <= 0;
								inputCounter2 <= 0;
								finalConvDone <= 0;
							end
				S_MEMREAD	:	begin																		//reading the input pixel values
								shiftBuffer[readCounter] <= readMem[7:0];								//input is 4 byes, each pixel values is 1 byte and hence stored in 4 consecutive locations in the input buffer
								shiftBuffer[readCounter+1'd1] <= readMem[15:8];
								shiftBuffer[readCounter+2'd2] <= readMem[23:16];
								shiftBuffer[readCounter+2'd3] <= readMem[31:24];
								readCounter <= readCounter + 3'd4;
							end
				S_CREATEINPUT1	:	begin
								inputConv1[inputCounter1] <= shiftBuffer[rowsCompleted1*10'd32+inputCounter1];
								inputCounter1 <= inputCounter1 + 1'b1;
							end
				S_CONV1		:	begin
								inputCounter1 <= 0;
							end
				S_WAIT1		:	begin						

							end
				S_CREATEINPUT2	:	begin
								inputConv2[inputCounter2] <= bufferOutputConv1[rowsCompleted2*10'd28+inputCounter2];
								inputCounter2 <= inputCounter2 + 1'b1;
							end
				S_CONV2		:	begin
								inputCounter2 <= 0;
							end
				S_WAIT2		:	begin

							end
				S_SENDOUTPUT1	:	begin
								finalConvDone <= 1'b1;
								writeMem <= {{3{bufferOutputConv2[outputCounter1][12]}}, bufferOutputConv2[outputCounter1]};
								outputCounter1 <= outputCounter1 + 1'b1;
							end
				S_SENDOUTPUT2	:	begin
								writeMem <= {{3{bufferOutputConv3[outputCounter2][12]}}, bufferOutputConv3[outputCounter2]};
								outputCounter2 <= outputCounter2 + 1'b1;
							end
			endcase
		end
	end

	//Storing the outputs from convolution steps 1 and 2 into output buffers
	always_ff @ (posedge clk) begin
		if((convDone1 && (rowsCompleted1 < 29)) || (i < 29) && (i > 0)) begin
			bufferOutputConv1[counter1+i] <= outputConv1[i];
			i++;
		end
		else begin
			if(i == 29) begin
				counter1 <= counter1 + 8'd28;
				rowsCompleted1 <= rowsCompleted1 + 1'b1;
				i = 0;
			end
			else begin
				counter1 <= counter1;
				rowsCompleted1 <= rowsCompleted1;
			end
		end
		if((convDone2 && (rowsCompleted2 < 27)) || (j < 27) && (j > 0)) begin
			bufferOutputConv2[counter2+j] <= outputConv2[j];
			bufferOutputConv3[counter2+j] <= outputConv3[j];
			j++;
		end
		else begin
			if(j == 27) begin
				counter2 <= counter2 + 8'd26;
				rowsCompleted2 <= rowsCompleted2 + 1'b1;
				j = 0;
			end
			else begin
				counter2 <= counter2;
				rowsCompleted2 <= rowsCompleted2;
			end
		end
	end
	
endmodule
