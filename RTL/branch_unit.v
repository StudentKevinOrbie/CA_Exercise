module branch_unit#(
   parameter integer DATA_W     = 16
   )(
      input  wire signed [DATA_W-1:0]  updated_pc,
      input  wire signed [DATA_W-1:0]  instruction,
      input  wire signed [DATA_W-1:0]  branch_offset,
      output reg  signed [DATA_W-1:0]  branch_pc,
      output reg  signed [DATA_W-1:0]  jump_pc
   );

   reg signed [DATA_W-1:0] shifted_offset;
   reg signed [DATA_W-1:0] shifted_instruction;

 
   always@(*) shifted_offset      = branch_offset<<2;
   always@(*) shifted_instruction = instruction<<2;
   always@(*) branch_pc           = shifted_offset+updated_pc;
   always@(*) jump_pc             = {updated_pc[31:28],shifted_instruction[27:0]};
  
endmodule