//Module: CPU
//Function: CPU is the top design of the processor
//Inputs:
//	clk: main clock
//	arst_n: reset 
// 	enable: Starts the execution
//	addr_ext: Address for reading/writing content to Instruction Memory
//	wen_ext: Write enable for Instruction Memory
// 	ren_ext: Read enable for Instruction Memory
//	wdata_ext: Write word for Instruction Memory
//	addr_ext_2: Address for reading/writing content to Data Memory
//	wen_ext_2: Write enable for Data Memory
// 	ren_ext_2: Read enable for Data Memory
//	wdata_ext_2: Write word for Data Memory
//Outputs:
//	rdata_ext: Read data from Instruction Memory
//	rdata_ext_2: Read data from Data Memory



module cpu(
		input  wire			  clk,
		input  wire         arst_n,
		input  wire         enable,
		input  wire	[31:0]  addr_ext,
		input  wire         wen_ext,
		input  wire         ren_ext,
		input  wire [31:0]  wdata_ext,
		input  wire	[31:0]  addr_ext_2,
		input  wire         wen_ext_2,
		input  wire         ren_ext_2,
		input  wire [31:0]  wdata_ext_2,
		
		output wire	[31:0]  rdata_ext,
		output wire	[31:0]  rdata_ext_2

   );

wire              zero_flag;
wire [      31:0] branch_pc,updated_pc,current_pc,jump_pc,
                  instruction;
wire [       1:0] alu_op;
wire [       3:0] alu_control;
wire              reg_dst,branch,mem_read,mem_2_reg,
                  mem_write,alu_src, reg_write, jump;
wire [       4:0] regfile_waddr;
wire [      31:0] regfile_wdata, dram_data,alu_out,
                  regfile_data_1,regfile_data_2,
                  alu_operand_2;

wire signed [31:0] immediate_extended;

assign immediate_extended = $signed(instruction[15:0]);

// ---------------------------------------------- IF ----------------------------------------------
pc #(
   .DATA_W(32)
) program_counter (
   .clk       (clk       ),
   .arst_n    (arst_n    ),
   .branch_pc (branch_pc ),
   .jump_pc   (jump_pc   ),
   .zero_flag (zero_flag ),
   .branch    (branch    ),
   .jump      (jump      ),
   .current_pc(current_pc),
   .enable    (enable    ),
   .updated_pc(updated_pc)
);


sram #(
   .ADDR_W(9 ),
   .DATA_W(32)
) instruction_memory(
   .clk      (clk           ),
   .addr     (current_pc    ),
   .wen      (1'b0          ),
   .ren      (1'b1          ),
   .wdata    (32'b0         ),
   .rdata    (instruction   ),   
   .addr_ext (addr_ext      ),
   .wen_ext  (wen_ext       ), 
   .ren_ext  (ren_ext       ),
   .wdata_ext(wdata_ext     ),
   .rdata_ext(rdata_ext     )
);

// RegName = [signal_name]_pipe_[prevStage]_[followingStage]
// OutName = [signal_name]_[followingStage]_[nextStage]
reg_arstn_en #(.DATA_W(32)) instruction_pipe_IF_ID(
      .clk   (clk       ),
      .arst_n(arst_n    ),
      .din   (instruction),
      .en    (enable    ),
      .dout  (instruction_IF_ID)
);

reg_arstn_en #(.DATA_W(32)) updated_pc_pipe_IF_ID(
      .clk   (clk       ),
      .arst_n(arst_n    ),
      .din   (updated_pc),
      .en    (enable    ),
      .dout  (updated_pc_IF_ID)
);


// ---------------------------------------------- ID ----------------------------------------------
control_unit control_unit(
   .opcode   (instruction[31:26]),
   .reg_dst  (reg_dst           ),
   .branch   (branch            ),
   .mem_read (mem_read          ),
   .mem_2_reg(mem_2_reg         ),
   .alu_op   (alu_op            ),
   .mem_write(mem_write         ),
   .alu_src  (alu_src           ),
   .reg_write(reg_write         ),
   .jump     (jump              )
);


mux_2 #(
   .DATA_W(5)
) regfile_dest_mux (
   .input_a (instruction[15:11]),
   .input_b (instruction[20:16]),
   .select_a(reg_dst          ),
   .mux_out (regfile_waddr     )
);

register_file #(
   .DATA_W(32)
) register_file(
   .clk      (clk               ),
   .arst_n   (arst_n            ),
   .reg_write(WB_reg_write      ),
   .raddr_1  (instruction[25:21]),
   .raddr_2  (instruction[20:16]),
   .waddr    (regfile_waddr     ),
   .wdata    (regfile_wdata     ),
   .rdata_1  (regfile_data_1    ),
   .rdata_2  (regfile_data_2    )
);

// ~~~~~~~~~~~~~~~~~~~~~~~~~~~ Control ~~~~~~~~~~~~~~~~~~~~~~~~~~~
wire [1:0] WB_ctrl;
wire [2:0] MEM_ctrl;
wire [3:0] EXE_ctrl;

always@(*) WB_ctrl = {mem_2_reg, reg_write};
reg_arstn_en #(.DATA_W(2)) WB_ctrl_pipe_ID_EXE(
      .clk   (clk       ),
      .arst_n(arst_n    ),
      .din   (WB_ctrl   ),
      .en    (enable    ),
      .dout  (WB_ctrl_ID_EXE)
);

always@(*) MEM_ctrl = {alu_src, alu_op, reg_dst};
reg_arstn_en #(.DATA_W(3)) MEM_ctrl_pipe_ID_EXE(
      .clk   (clk       ),
      .arst_n(arst_n    ),
      .din   (MEM_ctrl   ),
      .en    (enable    ),
      .dout  (MEM_ctrl_ID_EXE)
);

always@(*) EXE_ctrl = {mem_write, mem_read, branch, jump};
reg_arstn_en #(.DATA_W(4)) EXE_ctrl_pipe_ID_EXE(
      .clk   (clk       ),
      .arst_n(arst_n    ),
      .din   (EXE_ctrl   ),
      .en    (enable    ),
      .dout  (EXE_ctrl_ID_EXE)
);

// ---------------------------------------------- EXE ----------------------------------------------
alu_control alu_ctrl(
   .function_field (instruction[5:0]),
   .alu_op         (alu_op          ),
   .alu_control    (alu_control     )
);

mux_2 #(
   .DATA_W(32)
) alu_operand_mux (
   .input_a (immediate_extended),
   .input_b (regfile_data_2    ),
   .select_a(alu_src           ),
   .mux_out (alu_operand_2     )
);


alu#(
   .DATA_W(32)
) alu(
   .alu_in_0 (regfile_data_1),
   .alu_in_1 (alu_operand_2 ),
   .alu_ctrl (alu_control   ),
   .alu_out  (alu_out       ),
   .shft_amnt(instruction[10:6]),
   .zero_flag(zero_flag     ),
   .overflow (              )
);

// Why are the results forwarded (pipelined) to MEM stage ?
branch_unit#(
   .DATA_W(32)
)branch_unit(
   .updated_pc   (updated_pc        ),
   .instruction  (instruction       ),
   .branch_offset(immediate_extended),
   .branch_pc    (branch_pc         ),
   .jump_pc      (jump_pc         )
);

// ~~~~~~~~~~~~~~~~~~~~~~~~~~~ Registers ~~~~~~~~~~~~~~~~~~~~~~~~~~~
reg_arstn_en #(.DATA_W(32)) alu_out_pipe_EXE_MEM(
      .clk   (clk       ),
      .arst_n(arst_n    ),
      .din   (alu_out   ),
      .en    (enable    ),
      .dout  (alu_out_EXE_MEM)
);

reg_arstn_en #(.DATA_W(32)) regfile_data_2_pipe_EXE_MEM(
      .clk   (clk                  ),
      .arst_n(arst_n               ),
      .din   (regfile_data_2_ID_EXE),
      .en    (enable               ),
      .dout  (regfile_data_2_EXE_MEM)
);

reg_arstn_en #(.DATA_W(32)) branch_pc_pipe_EXE_MEM(
      .clk   (clk       ),
      .arst_n(arst_n    ),
      .din   (branch_pc ),
      .en    (enable    ),
      .dout  (branch_pc_EXE_MEM)
);

reg_arstn_en #(.DATA_W(32)) regfile_waddr_pipe_EXE_MEM(
      .clk   (clk          ),
      .arst_n(arst_n       ),
      .din   (regfile_waddr),
      .en    (enable       ),
      .dout  (regfile_waddr_EXE_MEM)
);

reg_arstn_en #(.DATA_W(32)) jump_pc_pipe_EXE_MEM(
      .clk   (clk       ),
      .arst_n(arst_n    ),
      .din   (jump_pc   ),
      .en    (enable    ),
      .dout  (jump_pc_EXE_MEM)
);

// ~~~~~~~~~~~~~~~~~~~~~~~~~~~ Control ~~~~~~~~~~~~~~~~~~~~~~~~~~~
reg_arstn_en #(.DATA_W(2)) WB_ctrl_pipe_EXE_MEM(
      .clk   (clk           ),
      .arst_n(arst_n        ),
      .din   (WB_ctrl_ID_EXE),
      .en    (enable        ),
      .dout  (WB_ctrl_EXE_MEM)
);

reg_arstn_en #(.DATA_W(1)) zero_flag_pipe_EXE_MEM(
      .clk   (clk       ),
      .arst_n(arst_n    ),
      .din   (zero_flag ),
      .en    (enable    ),
      .dout  (zero_flag_EXE_MEM)
);

// ---------------------------------------------- MEM ----------------------------------------------
sram #(
   .ADDR_W(10),
   .DATA_W(32)
) data_memory(
   .clk      (clk           ),
   .addr     (alu_out_EXE_MEM),
   .wen      (mem_write     ),
   .ren      (mem_read      ),
   .wdata    (regfile_data_2),
   .rdata    (dram_data     ),   
   .addr_ext (addr_ext_2    ),
   .wen_ext  (wen_ext_2     ),
   .ren_ext  (ren_ext_2     ),
   .wdata_ext(wdata_ext_2   ),
   .rdata_ext(rdata_ext_2   )
);

reg_arstn_en #(.DATA_W(32)) dram_data_pipe_MEM_WB(
      .clk   (clk       ),
      .arst_n(arst_n    ),
      .din   (dram_data ),
      .en    (enable    ),
      .dout  (dram_data_MEM_WB)
);

reg_arstn_en #(.DATA_W(32)) alu_out_pipe_MEM_WB(
      .clk   (clk            ),
      .arst_n(arst_n         ),
      .din   (alu_out_EXE_MEM),
      .en    (enable         ),
      .dout  (alu_out_MEM_WB)
);

reg_arstn_en #(.DATA_W(32)) regfile_waddr_pipe_MEM_WB(
      .clk   (clk            ),
      .arst_n(arst_n         ),
      .din   (regfile_waddr_EXE_MEM),
      .en    (enable         ),
      .dout  (regfile_waddr_MEM_WB)
);

// ~~~~~~~~~~~~~~~~~~~~~~~~~~~ Control ~~~~~~~~~~~~~~~~~~~~~~~~~~~
reg_arstn_en #(.DATA_W(2)) WB_ctrl_pipe_MEM_WB(
      .clk   (clk            ),
      .arst_n(arst_n         ),
      .din   (WB_ctrl_EXE_MEM),
      .en    (enable         ),
      .dout  (WB_ctrl_MEM_WB)
);

// ---------------------------------------------- WB ----------------------------------------------
wire WB_mem_2_reg;
wire WB_reg_write;
always@(*) {WB_mem_2_reg, WB_reg_write} = WB_ctrl_MEM_WB;

mux_2 #(
   .DATA_W(32)
) regfile_data_mux (
   .input_a  (dram_data    ),
   .input_b  (alu_out      ),
   .select_a (WB_mem_2_reg     ),
   .mux_out  (regfile_wdata)
);



endmodule


