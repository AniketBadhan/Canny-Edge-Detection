# Canny-Edge-Detection
RTL Code for Canny Edge Detection Algorithm. 

This project is a part of the main project, Hardware acceleration of Canny Edge Detecion Algorithm.

This code implements the first 2 steps of Canny Edge Detection Algorithm, i.e., convolution with Guassian filter and Sobel filter.
The reason for implementing the first 2 steps on hardware was to use hardware parallelism for acceleration.
Convolution operation is time consuming and has scope for parellelism, and hence, implemented on hardware (Altera Cyclone 5 FPGA). 
