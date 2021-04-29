module hazard_detection_unit#(
   parameter integer DATA_W     = 16
   )(
      input  wire signed        MEM_ctrl_ID_EXE_mem_read,  // ID/EX MemRead
      input  wire signed [4:0]  instruction_ID_EXE_Rt,     // ID/EX Rt
      input  wire signed [4:0]  instruction_IF_ID_Rs,      // IF/ID Rs
      input  wire signed [4:0]  instruction_IF_ID_Rt,      // IF/ID Rt
      output wire signed        EXE_ctrl_mux_ctrl,         // (0 = set to 0)
      output wire signed        IF_ID_pipe_enable,         // IF/IDWrite (0 = stall)
      output wire signed        PC_write_enable            // PCwrite    (0 = stall)
   );

   // Lw writes in R
   assign EXE_ctrl_mux_ctrl = (MEM_ctrl_ID_EXE_mem_read == 1'b1) && ((instruction_ID_EXE_Rt == instruction_IF_ID_Rs) || (instruction_ID_EXE_Rt == instruction_IF_ID_Rt))? 1'b0:1'b1;
   assign IF_ID_pipe_enable = (MEM_ctrl_ID_EXE_mem_read == 1'b1) && ((instruction_ID_EXE_Rt == instruction_IF_ID_Rs) || (instruction_ID_EXE_Rt == instruction_IF_ID_Rt))? 1'b0:1'b1;
   assign PC_write_enable = (MEM_ctrl_ID_EXE_mem_read == 1'b1) && ((instruction_ID_EXE_Rt == instruction_IF_ID_Rs) || (instruction_ID_EXE_Rt == instruction_IF_ID_Rt))? 1'b0:1'b1;
   
   //always@(*)begin
      // (check if prev load instruction) && (check if next intruction uses loaded data)
      //if((MEM_ctrl_ID_EXE_mem_read == 1'b1) && ((instruction_ID_EXE_Rt == instruction_IF_ID_Rs) || (instruction_ID_EXE_Rt == instruction_IF_ID_Rt))) begin
         //EXE_ctrl_mux_ctrl = 1'b0;
         //IF_ID_pipe_enable = 1'b0;
         //PC_write_enable   = 1'b0;
      //end else begin
         //EXE_ctrl_mux_ctrl = 1'b1;
         //IF_ID_pipe_enable = 1'b1;
         //PC_write_enable   = 1'b1;
      //end
   //end


endmodule
