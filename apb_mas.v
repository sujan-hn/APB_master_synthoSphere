module apb_master (
  input      pclk,
  input      preset_n, 	
 
  input  [1:0]		transfer,	// 2'b00 - No_tarnfer, 2'b01 - READ_transfer, 2'b11 - WRITE_transfer
  input  [7:0]	prdata_i,
  input		pready_i,
  output 	        psel_o,
  output  		penable_o,
  output [7:0]	paddr_o,
  output 		pwrite_o,
  output [7:0] 	pwdata_o
  
);
  
parameter[1:0]ST_IDLE=2'b00, ST_SETUP=2'b01, ST_ACCESS=2'b10 ;
  
  reg [1:0] state_q; 		// Current state
  reg [1:0] nxt_state;	       // Next state
  
  wire apb_state_setup;
  wire apb_state_access;
  
  reg nxt_pwrite;
  reg pwrite_q;
  
  reg [7:0] nxt_rdata;
  reg [7:0] rdata_q;
  
  always @(posedge pclk or negedge preset_n)
    if (~preset_n)
      state_q <= ST_IDLE;
  	else
      state_q <= nxt_state;
  
  always @(state_q,pready_i,transfer) begin
    nxt_pwrite = pwrite_q;
    nxt_rdata = rdata_q;
    case (state_q)
      ST_IDLE:
        if (transfer[0]) begin
          nxt_state = ST_SETUP;
          nxt_pwrite = transfer[1];
        end else begin
          nxt_state = ST_IDLE;
        end
      ST_SETUP: 
      nxt_state = ST_ACCESS;
      
      ST_ACCESS:
        if (pready_i) begin
          if (~pwrite_q)
          nxt_rdata = prdata_i;
          nxt_state = ST_IDLE;
        end else
          nxt_state = ST_ACCESS;
      default: nxt_state = ST_IDLE;
    endcase
  end
  
  assign apb_state_access = (state_q == ST_ACCESS);
  assign apb_state_setup = (state_q == ST_SETUP);
  
  assign psel_o = apb_state_setup | apb_state_access;
  assign penable_o = apb_state_access;
  
  // 
  assign paddr_o = {8{apb_state_access}} & 8'hAB;
  
  // APB PWRITE control
  always @(posedge pclk or negedge preset_n)
    if (~preset_n)
      pwrite_q <= 1'b0;
  	else
      pwrite_q <= nxt_pwrite;
  
  assign pwrite_o = pwrite_q;
  
  // APB PWDATA data signal
  // ADDER
  // Read a value from the slave at address 0xABCD
  // Increment that value
  // Send that value back during the write operation to address 0xABCD
  assign pwdata_o = {32{apb_state_access}} & (rdata_q);
  
  
  always @(posedge pclk or negedge preset_n)
    if (~preset_n)
      rdata_q <= 8'h0;
  	else
      rdata_q <= nxt_rdata;
  
endmodule
