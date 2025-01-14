//Branch Unit
//Function: Calculate the next pc in the case of a control instruction (branch or jump).
//Inputs:
//instruction: Instruction currently processed. The least significant bits are used for the calcualting the target pc in the case of a jump instruction. 
//branch_offset: Offset for a branch instruction. 
//updated_pc:  Current PC + 4.
//Outputs: 
//branch_pc: Target PC in the case of a branch instruction.
//jump_pc: Target PC in the case of a jump instruction.

module forwarding_unit#(
   parameter integer DATA_W     = 16
   )(
      input  wire signed        WB_ctrl_EXE_MEM_reg_write,
      input  wire signed        WB_ctrl_MEM_WB_reg_write,
      input  wire signed [4:0]  regfile_waddr_EXE_MEM,
      input  wire signed [4:0]  regfile_waddr_MEM_WB,
      input  wire signed [4:0]  instruction_ID_EXE_Rs,
      input  wire signed [4:0]  instruction_ID_EXE_Rt,
      output reg signed [1:0]  alu_op_1_ctrl,
      output reg signed [1:0]  alu_op_2_ctrl
   );


   always@(*) begin

      // Generating muxcontrol for upper forwarding mux
      if (WB_ctrl_EXE_MEM_reg_write == 1'b1
      && (regfile_waddr_EXE_MEM == instruction_ID_EXE_Rs)) begin 
         alu_op_1_ctrl = 2'b10;
      end else if (WB_ctrl_MEM_WB_reg_write == 1'b1 
      && !(WB_ctrl_EXE_MEM_reg_write == 1'b1 && (regfile_waddr_EXE_MEM !== instruction_ID_EXE_Rs))
      && (regfile_waddr_MEM_WB == instruction_ID_EXE_Rs)) begin 
         alu_op_1_ctrl = 2'b01;
      end else begin
         alu_op_1_ctrl = 2'b00;
      end

      // Generating muxcontrol for lower forwarding mux
      if (WB_ctrl_EXE_MEM_reg_write == 1'b1
      && (regfile_waddr_EXE_MEM == instruction_ID_EXE_Rt)) begin
         alu_op_2_ctrl = 2'b10;
      end else if (WB_ctrl_MEM_WB_reg_write == 1'b1 
      && !(WB_ctrl_EXE_MEM_reg_write == 1'b1 && (regfile_waddr_EXE_MEM !== instruction_ID_EXE_Rt))
      && (regfile_waddr_MEM_WB == instruction_ID_EXE_Rt)) begin 
         alu_op_2_ctrl = 2'b01;
      end else begin
         alu_op_2_ctrl = 2'b00;
      end
   end
endmodule



