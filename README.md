# APB_master_synthoSphere
RTL implementation and synthesis of AMBA APB Master Protocol using opensource tools - iverilog and yosys. The APB(Advanced Peripheral Bus) protocol,is widely used in system-on-chip (SoC) designs to enable the controlled transfer of data between the processor and peripherals.APB is low bandwidth and low performance bus. So, the components requiring lower bandwidth like the peripheral devices such as UART, Keypad, Timer and PIO (Peripheral Input Output) devices are connected to the APB.This RTL involves the implementation of the APB master bridge,and the slave is implemented through the testbench to check the functionality of the master.

## APB master Specification
1.  **Bus Signals:**
   - `PCLK` (Peripheral Clock): The clock signal that drives the bus operations.
   - `PSEL` (Peripheral Select): Indicates the selected peripheral for the current transaction.
   - `PENABLE` (Peripheral Enable): Indicates an active transfer when asserted.
   - `PWRITE` (Peripheral Write): Indicates a write operation when asserted, otherwise it's a read operation.
   - `PADDR` (Peripheral Address): Specifies the address of the selected peripheral register.
   - `PWDATA` (Peripheral Write Data): Carries the data to be written to the peripheral register.
   - `PRDATA` (Peripheral Read Data): Carries the data read from the peripheral register.
2. **Single slave/peripheral design.**
3. **Data width 8 bits and Address width 8 bits.**
4. **Start of data transmission is indicated when PENABLE changes from low to high. End of transmission is indicated by PREADY changes from high to low.**
5. **Transfer Phases:**
   - This APB transfer consists of a read phase followed by a write phase.
   - In the read phase, data is read from the peripheral register into `PRDATA`.
   - For simplicity in the design, the `PADDR` signal is kept constant during transfers.
   - In the write phase, the data from the read phase is fed into `PWDATA` and a write operation is indicated by asserting `PWRITE`.


APB Master Interface:

![APB Master Interface](https://github.com/sujan-hn/APB_master_synthoSphere/assets/129975786/18a5a0c0-13c4-4414-aca2-4785d1d3234a)


APB Transfer FSM:

![image](https://github.com/sujan-hn/APB_master_synthoSphere/assets/129975786/2ffa7739-cff7-4311-99f0-401750878d6d)


Top Module file: apb_master.v 
Testbench file: apb_test.v

## apb_mas.v
```verilog
 module apb_master (
  input      pclk,
  input      preset_n, 	
 
  input  [1:0]		transfer,	// 2'b00 - No_transfer, 2'b01 - READ_transfer, 2'b11 - WRITE_transfer
  input  [7:0]	prdata_i,
  input		pready_i,
  output 	        psel_o,
  output  		penable_o,
  output [7:0]	paddr_o,
  output 		pwrite_o,
  output [7:0] 	pwdata_o
  
);
  
parameter[1:0]ST_IDLE=2'b00, ST_SETUP=2'b01, ST_ACCESS=2'b10 ;
  
  reg [1:0] state_q; 		
  reg [1:0] nxt_state;	       
 
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
   
  assign paddr_o = {8{apb_state_access}} & 8'hAB;
  
  //PWRITE control
  always @(posedge pclk or negedge preset_n)
    if (~preset_n)
      pwrite_q <= 1'b0;
  	else
      pwrite_q <= nxt_pwrite;
  
  assign pwrite_o = pwrite_q;
  
  // Reading from address 0xAB and  Send that value back during the write operation to address 0xAB
  assign pwdata_o = {8{apb_state_access}} & (rdata_q);
  
  
  always @(posedge pclk or negedge preset_n)
    if (~preset_n)
      rdata_q <= 8'h0;
  	else
      rdata_q <= nxt_rdata;
  
endmodule
```

## apb_tb.v
```verilog
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
  count = count +1;
  
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
```


## RTL Simulation Results:
#### READ transfer
![image](https://github.com/sujan-hn/APB_master_synthoSphere/assets/129975786/49ae1919-7098-4721-8ab8-c74c516c8f25)
##### The PSEL is first asserted then the next pclk cycle the penable is asserted by the Master, when the slave is ready for the read transaction, the slave asserts the pready signal, and then the data is sampled.(Here the sampled data is 05).

#### WRITE transfer
![image](https://github.com/sujan-hn/APB_master_synthoSphere/assets/129975786/83d90713-2f76-4758-86fe-41b6f9585eca)
##### The PSEL is first asserted then the next pclk cycle the penable is asserted by the Master, when the slave is ready for the write transaction, the slave asserts the pready signal, and then the PWDATA is changed.(Here, the read data is again fed back to the pwdata bus(value = 05)).


## Synthesis output
#### The logic of the code was implemented using the following components

![image](https://github.com/sujan-hn/APB_master_synthoSphere/assets/129975786/64eab8cb-9899-4f09-9e52-5f19b5ecbb39)


![image](https://github.com/sujan-hn/APB_master_synthoSphere/assets/129975786/d1468ed3-101e-4da1-84dd-e62503855b2e)



#### The gate level netlist generated connections 


![image](https://github.com/sujan-hn/APB_master_synthoSphere/assets/129975786/8c5f793b-3beb-4c01-8a1b-101627b237e9)

## GLS Simulation:
#### The functionality of the PWM generator with variable duty cycle is retained post-synthesis. Hence the deisgn does not have Simulation-Synthesis Mismatch


###### Read_tx
![image](https://github.com/sujan-hn/APB_master_synthoSphere/assets/129975786/299913c7-4881-43e5-b422-1f9f57af4876)

###### Write_tx
![image](https://github.com/sujan-hn/APB_master_synthoSphere/assets/129975786/3878bc9b-9407-4e70-bfd0-e47fdc57e9a0)



### The functionality of the Master can also be compared to AMBA's APB specification 

###### Read_Tx
![image](https://github.com/sujan-hn/APB_master_synthoSphere/assets/129975786/c5c328c3-5027-47ca-802e-44ae06c1d91c)



###### Write_Tx
![image](https://github.com/sujan-hn/APB_master_synthoSphere/assets/129975786/a18247ef-6101-4cd1-952f-c92ee933ee3d)






































