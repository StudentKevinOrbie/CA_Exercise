//Branch Unit
//Function: Calculate the next pc in the case of a control instruction (branch or jump).
//Inputs:
//instruction: Instruction currently processed. The least significant bits are used for the calcualting the target pc in the case of a jump instruction. 
//branch_offset: Offset for a branch instruction. 
//updated_pc:  Current PC + 4.
//Outputs: 
//branch_pc: Target PC in the case of a branch instruction.
//jump_pc: Target PC in the case of a jump instruction.

module branch_unit#(
   parameter integer DATA_W     = 16
   )(
      input  wire signed [DATA_W-1:0]  WB_ctrl_EXE_MEM,
      input  wire signed [DATA_W-1:0]  WB_ctrl_MEM_WB,
      input  wire signed [DATA_W-1:0]  regfile_waddr_EXE_MEM,
      input  wire signed [DATA_W-1:0]  regfile_waddr_MEM_WB,
      input  wire signed [DATA_W-1:0]  instruction_ID_EXE_Rs,
      input  wire signed [DATA_W-1:0]  instruction_ID_EXE_Rt,
      output wire signed [1:0]         alu_op_1_ctrl,
      output wire signed [1:0]         alu_op_2_ctrl
   );


 
   always@(*) shifted_offset      = branch_offset<<2;
   always@(*) shifted_instruction = instruction<<2;
   always@(*) branch_pc           = shifted_offset+updated_pc;
   always@(*) jump_pc             = {updated_pc[31:28],shifted_instruction[27:0]};
  
endmodule



