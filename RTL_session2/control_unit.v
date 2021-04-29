// module: Control
// Function: Generates the control signals for each one of the datapath resources

module control_unit(
      input  wire [5:0] opcode,
      output reg  [1:0] alu_op,
      output reg        reg_dst,
      output reg        branch,
      output reg        mem_read,
      output reg        mem_2_reg,
      output reg        mem_write,
      output reg        alu_src,
      output reg        reg_write,
      output reg        jump
   );

   //The opcode for these instructions can be found on the MIPS reference at the beginning of the textbook (Green cardboard page)
   parameter integer ALU_R      = 6'h0; // The MULT instruction of this type (No change needed)
   parameter integer ADDI       = 6'h8;
   parameter integer BRANCH_EQ  = 6'h4;
   parameter integer JUMP       = 6'h2;
   parameter integer LOAD_WORD  = 6'h23;
   parameter integer STORE_WORD = 6'h2B;

   parameter [1:0] ADD_OPCODE     = 2'd0;
   parameter [1:0] SUB_OPCODE     = 2'd1;
   parameter [1:0] R_TYPE_OPCODE  = 2'd2;


   //The behavior of the control unit can be found in Chapter 4, Figure 4.18

   always@(*)begin

      case(opcode)
         ALU_R:begin
            reg_dst   = 1'b1; //Select the write adress from bits [11 - 15] (R-type instr)
            alu_src   = 1'b0; //Select 2nd variable for in ALU from Reg File
            mem_2_reg = 1'b0; //Write directly from alu to Reg File
            reg_write = 1'b1; //Write to the register
            mem_read  = 1'b0; //Don't Read Mem from Data memory
            mem_write = 1'b0; //Don't Write to Data memory
            branch    = 1'b0; //Don't branch
            alu_op    = R_TYPE_OPCODE; //Select type of operation ALU
            jump      = 1'b0; //Don't jump
         end

         ADDI:begin
            reg_dst   = 1'b0; //The result has to be saved in Rt and not Rd (see MIPS)
            alu_src   = 1'b1; //The second input of the ALU has to come from the Immediate Generator
            mem_2_reg = 1'b0; //The result must go to the register bank, not the memory
            reg_write = 1'b1; //The result has to be written in the register bank
            mem_read  = 1'b0; //Nothing must be read from mem
            mem_write = 1'b0; //Nothing must be written to mem
            branch    = 1'b0; //No branch must be taken
            alu_op    = ADD_OPCODE; // addition with constant
            jump      = 1'b0; // Don't jump
         end

         BRANCH_EQ:begin
            reg_dst   = 1'b0; //select Rt (see MIPS)
            alu_src   = 1'b0; //select whether the input of the ALU comes from the registers or directly from the instruction
            mem_2_reg = 1'b0; //selects wether the data written in the registers comes from memory or bypasses it
            reg_write = 1'b0; //write in the register
            mem_read  = 1'b0; //controls/indicates that information is written in the memory
            mem_write = 1'b0; //controls/indicates that information is written in the memory
            branch    = 1'b1; //indicates whether a branch should be taken or not
            alu_op    = 2'd0; //No effect here
            jump      = 1'b0; //Don't jump 
         end

         JUMP:begin
            reg_dst   = 1'b0; //No effect here
            alu_src   = 1'b0; //No effect here
            mem_2_reg = 1'b0; //No effect here
            reg_write = 1'b0; //Don't Write to the Register File
            mem_read  = 1'b0; //Don't Read from Data memory
            mem_write = 1'b0; //Don't Write to Data memory
            branch    = 1'b0; //No effect here
            alu_op    = 2'd0; //No effect here
            jump      = 1'b1; //Indicate if you need to jump
         end

         LOAD_WORD:begin
            reg_dst   = 1'b0; //Select the Reg-adress to write to from bits [20 - 16] (I-type instr)
            alu_src   = 1'b1; //Select the immediate value from the instruction for the 2nd input of the ALU
            mem_2_reg = 1'b1; //Write data from memory to Reg file
            reg_write = 1'b1; //Write to the register
            mem_read  = 1'b1; //Read value from Data memory
            mem_write = 1'b0; //Don't Write to Data memory
            branch    = 1'b0; //Don't branch
            alu_op    = ADD_OPCODE; //Add values: MemAdress = R[rs] + Immediate
            jump      = 1'b0; //Don't jump
         end

         STORE_WORD:begin
            reg_dst   = 1'b0; //No effect here
            alu_src   = 1'b1; //Select the immediate value from the instruction for the 2nd input of the ALU
            mem_2_reg = 1'b0; //No effect here
            reg_write = 1'b0; //Don't write to Reg file
            mem_read  = 1'b0; //Don't Read value from Data memory
            mem_write = 1'b1; //Write to Data memory
            branch    = 1'b0; //Don't branch
            alu_op    = ADD_OPCODE; //Add values: MemAdress = R[rs] + Immediate
            jump      = 1'b0; //Don't jump
         end
    
	// Declare the control signals for each one of the instructions
	
         default:begin
            reg_dst   = 1'b0; 
            alu_src   = 1'b0;
            mem_2_reg = 1'b0;
            reg_write = 1'b0;
            mem_read  = 1'b0;
            mem_write = 1'b0;
            branch    = 1'b0;
            alu_op    = R_TYPE_OPCODE;
            jump      = 1'b0;
         end
      endcase
   end

endmodule



