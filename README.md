# APB_master_synthoSphere
RTL implementation and synthesis of the APB Master Protocol using opensource tools-iverilog and yosys. The APB protocol, known for its simplicity and efficiency, is widely used in system-on-chip (SoC) designs to enable the controlled transfer of data between the processor and peripherals.APB is low bandwidth and low performance bus. So, the components requiring lower bandwidth like the peripheral devices such as UART, Keypad, Timer and PIO (Peripheral Input Output) devices are connected to the APB.This RTL involves the implementation of the APB master bridge,and the slave is implemented through the testbench to check the functionality of the master.

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
   -  - For simplicity in the design, the `PADDR` signal is kept constant during transfers.
   - In the write phase, the data from the read phase is fed into `PWDATA` and a write operation is indicated by asserting `PWRITE`.




