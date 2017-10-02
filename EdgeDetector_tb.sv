`timescale 1ns/1ps

module EdgeDetector_tb();
	
	//Inputs
	reg clk;
	reg reset;
	reg chipSelect;
	reg [31:0] readMem;
	
	//Outputs
	wire [15:0] writeMem;
	wire finalConvDone;
	
	//Internal Signals
	reg [15:0] Conv2Output[0:1351];
	reg [7:0] image [0:1023];
	int i = 0;
	int j = 0;
	
	EdgeDetector E1(
		.clk(clk),
		.reset(reset),
		.chipSelect(chipSelect),
		.readMem(readMem),
		.writeMem(writeMem),
		.finalConvDone(finalConvDone)
	);
	
	initial $readmemb("Image.txt", image, 0, 1023);
	
	initial begin
		clk = 1;
		reset = 0;
		chipSelect = 0;
		#2;
		reset = 1;
		chipSelect = 1;
	end
	
	always @ (posedge clk) begin
		if(reset && chipSelect) begin
			if(i < 1024) begin
				readMem <= {image[i+3],image[i+2],image[i+1],image[i]};
				i = i + 4;
			end
			else begin
				wait(finalConvDone==1);
				if(finalConvDone) begin
					if(j < 1352) begin
						Conv2Output[j] <= writeMem;  
						j++;
					end
					//wait(finalConvDone==1);
					else begin
						chipSelect = 0;
					end
				end
			end
			
		end
	end
	
	always #1 clk = ~clk;
	
	
endmodule
