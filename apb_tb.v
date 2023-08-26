`define CLK @(posedge pclk)

module apb_slave_tb ();

 reg		pclk;
 reg 		preset_n; 
 reg  [1:0]	transfer;
 reg  [7:0]	prdata_i;
 reg		pready_i;
 wire 	        psel_o;
 wire 		penable_o;
 wire [7:0]	paddr_o;
 wire 		pwrite_o;
 wire [7:0] 	pwdata_o;
  
	

  always #5 pclk = ~pclk; 
  
  
  initial begin
    pclk = 1'b0;
  end
  
  // Instantiate the RTL
  apb_master APB_MASTER (	
 pclk,
 preset_n, 
 transfer,
 prdata_i,
 pready_i,
 psel_o,
 penable_o,
 paddr_o,
 pwrite_o,
 pwdata_o
  );
  
  // Drive stimulus
  initial begin
    preset_n = 1'b0;
    transfer = 2'b00;
    repeat (2) `CLK;
    preset_n = 1'b1;
    repeat (2) `CLK;
    
    // Initiate a read transaction
    transfer = 2'b01;
    `CLK;
    transfer = 2'b00;
    repeat (4) `CLK;
    
    // Initiate a write transaction
    transfer = 2'b11;
    `CLK;
    transfer = 2'b00;
    repeat (4) `CLK;
    $finish();
  end
  
  // APB Slave
  
  reg [3:0]count;
  
  
  always @(posedge pclk or negedge preset_n )begin
  if (~preset_n)
  count<=0;
  else
  count <= count +1;
  
  end
  
  always @ (posedge pclk or negedge preset_n) begin
    if (~preset_n)
      pready_i <= 1'b0;
    else begin
    if (psel_o && penable_o) begin
      pready_i <= 1'b1;
      prdata_i <= count;
    end 
    else begin
      pready_i <= 1'b0;
      prdata_i <= count;
    end
    end
  end
  
  // VCD Dump
  initial begin
    $dumpfile("apb.vcd");
    $dumpvars(2);
  end
  
endmodule
