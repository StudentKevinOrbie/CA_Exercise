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
                  alu_operand_2, forward1, forward2;
wire zero_flag_EXE_MEM;
wire MEM_branch;
wire MEM_jump;
wire [4:0] regfile_waddr_MEM_WB;
wire WB_reg_write;
wire [31:0] instruction_IF_ID;

// For hazard detection unit stall
wire EXE_ctrl_mux_ctrl;
wire IF_ID_pipe_enable;
wire PC_write_enable;

wire signed [31:0] immediate_extended;

assign immediate_extended = $signed(instruction_IF_ID[15:0]);

// -------------------------------------------------------------------------------------------------
// ---------------------------------------------- IF -----------------------------------------------
// -------------------------------------------------------------------------------------------------

pc #(
   .DATA_W(32)
) program_counter (
   .clk       (clk       ),
   .arst_n    (arst_n    ),
   .branch_pc (branch_pc ),
   .jump_pc   (jump_pc   ),
   .zero_flag (zero_flag_EXE_MEM ),
   .branch    (MEM_branch    ),
   .jump      (MEM_jump      ),
   .current_pc(current_pc),
   .enable    (PC_write_enable & enable),
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

// =================================== pipe regs IF - ID ===================================
// RegName = [signal_name]_pipe_[prevStage]_[followingStage]
// OutName = [signal_name]_[followingStage]_[nextStage]

reg_arstn_en #(.DATA_W(32)) instruction_pipe_IF_ID(
      .clk   (clk       ),
      .arst_n(arst_n    ),
      .din   (instruction),
      .en    (IF_ID_pipe_enable & enable),
      .dout  (instruction_IF_ID)
);

wire [31:0] updated_pc_IF_ID;
reg_arstn_en #(.DATA_W(32)) updated_pc_pipe_IF_ID(
      .clk   (clk       ),
      .arst_n(arst_n    ),
      .din   (updated_pc),
      .en    (IF_ID_pipe_enable & enable),
      .dout  (updated_pc_IF_ID)
);

// -------------------------------------------------------------------------------------------------
// ---------------------------------------------- ID -----------------------------------------------
// -------------------------------------------------------------------------------------------------
control_unit control_unit(
   .opcode   (instruction_IF_ID[31:26]),
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


register_file #(
   .DATA_W(32)
) register_file(
   .clk      (clk               ),
   .arst_n   (arst_n            ),
   .reg_write(WB_reg_write      ),
   .raddr_1  (instruction_IF_ID[25:21]),
   .raddr_2  (instruction_IF_ID[20:16]),
   .waddr    (regfile_waddr_MEM_WB    ),
   .wdata    (regfile_wdata     ),
   .rdata_1  (regfile_data_1    ),
   .rdata_2  (regfile_data_2    )
);

hazard_detection_unit #(
   .DATA_W(32)
) hazard_detection_unit(
      .MEM_ctrl_ID_EXE_mem_read (MEM_ctrl_ID_EXE[2]        ),
      .instruction_ID_EXE_Rt    (instruction_ID_EXE[20:16] ),
      .instruction_IF_ID_Rs     (instruction_IF_ID[25:21]  ),
      .instruction_IF_ID_Rt     (instruction_IF_ID[20:16]  ),
      .EXE_ctrl_mux_ctrl        (EXE_ctrl_mux_ctrl         ),
      .IF_ID_pipe_enable        (IF_ID_pipe_enable         ), 
      .PC_write_enable          (PC_write_enable           ) 
);

// =================================== pipe regs ID - EXE ===================================
wire [31:0] regfile_data_1_ID_EXE;
reg_arstn_en #(.DATA_W(32)) regfile_data_1_pipe_ID_EXE(
      .clk   (clk       ),
      .arst_n(arst_n    ),
      .din   (regfile_data_1),
      .en    (enable    ),
      .dout  (regfile_data_1_ID_EXE)
);

wire [31:0] regfile_data_2_ID_EXE;
reg_arstn_en #(.DATA_W(32)) regfile_data_2_pipe_ID_EXE(
      .clk   (clk       ),
      .arst_n(arst_n    ),
      .din   (regfile_data_2),
      .en    (enable    ),
      .dout  (regfile_data_2_ID_EXE)
);

// Through
wire [31:0] updated_pc_ID_EXE;
reg_arstn_en #(.DATA_W(32)) updated_pc_pipe_ID_EXE(
      .clk   (clk       ),
      .arst_n(arst_n    ),
      .din   (updated_pc_IF_ID),
      .en    (enable    ),
      .dout  (updated_pc_ID_EXE)
);

wire [31:0] immediate_extended_ID_EXE;
reg_arstn_en #(.DATA_W(32)) immediate_extended_pipe_ID_EXE(
      .clk   (clk       ),
      .arst_n(arst_n    ),
      .din   (immediate_extended),
      .en    (enable    ),
      .dout  (immediate_extended_ID_EXE)
);

// Through
wire [31:0] instruction_ID_EXE;
reg_arstn_en #(.DATA_W(32)) instruction_pipe_ID_EXE(
      .clk   (clk       ),
      .arst_n(arst_n    ),
      .din   (instruction_IF_ID),
      .en    (enable    ),
      .dout  (instruction_ID_EXE)
);

// ~~~~~~~~~~~~~~~~~~~~~~~~~~~ Control ~~~~~~~~~~~~~~~~~~~~~~~~~~~
wire [1:0] WB_ctrl;
wire [3:0] MEM_ctrl;
wire [3:0] EXE_ctrl;

wire [1:0] WB_ctrl_ID_EXE;
assign WB_ctrl = EXE_ctrl_mux_ctrl ? {mem_2_reg, reg_write} : {1'b0, 1'b0}; // Ctrl = 0 --> all ctrl = 0
reg_arstn_en #(.DATA_W(2)) WB_ctrl_pipe_ID_EXE(
      .clk   (clk       ),
      .arst_n(arst_n    ),
      .din   (WB_ctrl   ),
      .en    (enable    ),
      .dout  (WB_ctrl_ID_EXE)
);

wire [3:0] EXE_ctrl_ID_EXE;
assign EXE_ctrl = EXE_ctrl_mux_ctrl ? {alu_src, alu_op[1], alu_op[0], reg_dst} : {1'b0, 1'b0, 1'b0, 1'b0} ;
reg_arstn_en #(.DATA_W(4)) EXE_ctrl_pipe_ID_EXE(
      .clk   (clk       ),
      .arst_n(arst_n    ),
      .din   (EXE_ctrl   ),
      .en    (enable    ),
      .dout  (EXE_ctrl_ID_EXE)
);

wire [3:0] MEM_ctrl_ID_EXE;
assign MEM_ctrl = EXE_ctrl_mux_ctrl ? {mem_write, mem_read, branch, jump} : {1'b0, 1'b0, 1'b0, 1'b0};
reg_arstn_en #(.DATA_W(4)) MEM_ctrl_pipe_ID_EXE(
      .clk   (clk       ),
      .arst_n(arst_n    ),
      .din   (MEM_ctrl   ),
      .en    (enable    ),
      .dout  (MEM_ctrl_ID_EXE)
);

// -------------------------------------------------------------------------------------------------
// ---------------------------------------------- EXE ----------------------------------------------
// -------------------------------------------------------------------------------------------------
wire EXE_alu_src;
wire [1:0] EXE_alu_op;
wire EXE_reg_dst;
assign EXE_alu_src = EXE_ctrl_ID_EXE[3];
assign EXE_alu_op[1] = EXE_ctrl_ID_EXE[2];
assign EXE_alu_op[0] = EXE_ctrl_ID_EXE[1];
assign EXE_reg_dst = EXE_ctrl_ID_EXE[0];

wire [1:0] alu_op_1_ctrl;
wire [1:0] alu_op_2_ctrl;

forwarding_unit#(
      .DATA_W(32)
)forwarding_unit(
      .WB_ctrl_EXE_MEM       (WB_ctrl_EXE_MEM[0]       ), // Select reg_write
      .WB_ctrl_MEM_WB        (WB_ctrl_MEM_WB[0]        ), // Select reg_write
      .regfile_waddr_EXE_MEM (regfile_waddr_EXE_MEM    ),
      .regfile_waddr_MEM_WB  (regfile_waddr_MEM_WB     ),
      .instruction_ID_EXE_Rs (instruction_ID_EXE[25:21]),
      .instruction_ID_EXE_Rt (instruction_ID_EXE[20:16]),
      .alu_op_1_ctrl         (alu_op_1_ctrl            ),
      .alu_op_2_ctrl         (alu_op_2_ctrl            )
)

alu_control alu_ctrl(
   .function_field (instruction_ID_EXE[5:0]),
   .alu_op         (EXE_alu_op      ),
   .alu_control    (alu_control     )
);

// Has now no effect ???
mux_2 #(
   .DATA_W(32)
) alu_operand_mux (
   .input_a (immediate_extended_ID_EXE),
   .input_b (regfile_data_2_ID_EXE    ),
   .select_a(EXE_alu_src              ),
   .mux_out (alu_operand_2            )
);

mux_2 #(
   .DATA_W(5)
) regfile_dest_mux (
   .input_a (instruction_ID_EXE[15:11]),
   .input_b (instruction_ID_EXE[20:16]),
   .select_a(alu_op_1_ctrl            ),
   .mux_out (regfile_waddr            )
);

mux_forwarding#(
      .DATA_W(32)
) mux_forwarding_1 (
   .input_a (regfile_data_1_ID_EXE),
   .input_b (regfile_wdata        ),
   .input_c (alu_out_EXE_MEM      ),
   .select_a(alu_op_1_ctrl        ),
   .mux_out (forward1             )
)

mux_forwarding#(
      .DATA_W(32)
) mux_forwarding_2 (
   .input_a (alu_operand_2        ), // Changed this from regfile_data_2_ID_EXE to output of mux controlled by ALU_src
   .input_b (regfile_wdata        ),
   .input_c (alu_out_EXE_MEM      ),
   .select_a(alu_op_2_ctrl        ),
   .mux_out (forward2             )
)

alu#(
   .DATA_W(32)
) alu(
   .alu_in_0 (forward1),
   .alu_in_1 (forward2),
   .alu_ctrl (alu_control   ),
   .alu_out  (alu_out       ),
   .shft_amnt(instruction_ID_EXE[10:6]),
   .zero_flag(zero_flag     ),
   .overflow (              )
);

// Why are the results forwarded (pipelined) to MEM stage ?
branch_unit#(
   .DATA_W(32)
)branch_unit(
   .updated_pc   (updated_pc_ID_EXE        ),
   .instruction  (instruction_ID_EXE       ),
   .branch_offset(immediate_extended_ID_EXE),
   .branch_pc    (branch_pc         ),
   .jump_pc      (jump_pc         )
);


// =================================== pipe regs EXE - MEM ===================================
wire [31:0] alu_out_EXE_MEM;
reg_arstn_en #(.DATA_W(32)) alu_out_pipe_EXE_MEM(
      .clk   (clk       ),
      .arst_n(arst_n    ),
      .din   (alu_out   ),
      .en    (enable    ),
      .dout  (alu_out_EXE_MEM)
);

// Through
wire [31:0] regfile_data_2_EXE_MEM;
reg_arstn_en #(.DATA_W(32)) regfile_data_2_pipe_EXE_MEM(
      .clk   (clk                  ),
      .arst_n(arst_n               ),
      .din   (regfile_data_2_ID_EXE),
      .en    (enable               ),
      .dout  (regfile_data_2_EXE_MEM)
);

wire [31:0] branch_pc_EXE_MEM;
reg_arstn_en #(.DATA_W(32)) branch_pc_pipe_EXE_MEM(
      .clk   (clk       ),
      .arst_n(arst_n    ),
      .din   (branch_pc ),
      .en    (enable    ),
      .dout  (branch_pc_EXE_MEM)
);

wire [4:0] regfile_waddr_EXE_MEM;
reg_arstn_en #(.DATA_W(5)) regfile_waddr_pipe_EXE_MEM(
      .clk   (clk          ),
      .arst_n(arst_n       ),
      .din   (regfile_waddr),
      .en    (enable       ),
      .dout  (regfile_waddr_EXE_MEM)
);

wire [31:0] jump_pc_EXE_MEM;
reg_arstn_en #(.DATA_W(32)) jump_pc_pipe_EXE_MEM(
      .clk   (clk       ),
      .arst_n(arst_n    ),
      .din   (jump_pc   ),
      .en    (enable    ),
      .dout  (jump_pc_EXE_MEM)
);

// ~~~~~~~~~~~~~~~~~~~~~~~~~~~ Control ~~~~~~~~~~~~~~~~~~~~~~~~~~~
// Through
wire [1:0] WB_ctrl_EXE_MEM;
reg_arstn_en #(.DATA_W(2)) WB_ctrl_pipe_EXE_MEM(
      .clk   (clk           ),
      .arst_n(arst_n        ),
      .din   (WB_ctrl_ID_EXE),
      .en    (enable        ),
      .dout  (WB_ctrl_EXE_MEM)
);

// Through
wire [3:0] MEM_ctrl_EXE_MEM;
reg_arstn_en #(.DATA_W(4)) MEM_ctrl_pipe_EXE_MEM(
      .clk   (clk           ),
      .arst_n(arst_n        ),
      .din   (MEM_ctrl_ID_EXE),
      .en    (enable        ),
      .dout  (MEM_ctrl_EXE_MEM)
);


reg_arstn_en #(.DATA_W(1)) zero_flag_pipe_EXE_MEM(
      .clk   (clk       ),
      .arst_n(arst_n    ),
      .din   (zero_flag ),
      .en    (enable    ),
      .dout  (zero_flag_EXE_MEM)
);

// -------------------------------------------------------------------------------------------------
// ---------------------------------------------- MEM ----------------------------------------------
// -------------------------------------------------------------------------------------------------
wire MEM_mem_write;
wire MEM_mem_read;
assign {MEM_mem_write, MEM_mem_read, MEM_branch, MEM_jump} = MEM_ctrl_EXE_MEM;

sram #(
   .ADDR_W(10),
   .DATA_W(32)
) data_memory(
   .clk      (clk            ),
   .addr     (alu_out_EXE_MEM),
   .wen      (MEM_mem_write  ),
   .ren      (MEM_mem_read   ),
   .wdata    (regfile_data_2_EXE_MEM),
   .rdata    (dram_data      ),   
   .addr_ext (addr_ext_2     ),
   .wen_ext  (wen_ext_2      ),
   .ren_ext  (ren_ext_2      ),
   .wdata_ext(wdata_ext_2    ),
   .rdata_ext(rdata_ext_2    )
);

// =================================== pipe regs MEM - WB ===================================
wire [31:0] dram_data_MEM_WB;
reg_arstn_en #(.DATA_W(32)) dram_data_pipe_MEM_WB(
      .clk   (clk       ),
      .arst_n(arst_n    ),
      .din   (dram_data ),
      .en    (enable    ),
      .dout  (dram_data_MEM_WB)
);

// Through
wire [31:0] alu_out_MEM_WB;
reg_arstn_en #(.DATA_W(32)) alu_out_pipe_MEM_WB(
      .clk   (clk            ),
      .arst_n(arst_n         ),
      .din   (alu_out_EXE_MEM),
      .en    (enable         ),
      .dout  (alu_out_MEM_WB)
);

// Through
reg_arstn_en #(.DATA_W(5)) regfile_waddr_pipe_MEM_WB(
      .clk   (clk            ),
      .arst_n(arst_n         ),
      .din   (regfile_waddr_EXE_MEM),
      .en    (enable         ),
      .dout  (regfile_waddr_MEM_WB)
);

// ~~~~~~~~~~~~~~~~~~~~~~~~~~~ Control ~~~~~~~~~~~~~~~~~~~~~~~~~~~
// Through
wire [1:0] WB_ctrl_MEM_WB;
reg_arstn_en #(.DATA_W(2)) WB_ctrl_pipe_MEM_WB(
      .clk   (clk            ),
      .arst_n(arst_n         ),
      .din   (WB_ctrl_EXE_MEM),
      .en    (enable         ),
      .dout  (WB_ctrl_MEM_WB)
);

// -------------------------------------------------------------------------------------------------
// ---------------------------------------------- WB -----------------------------------------------
// -------------------------------------------------------------------------------------------------
wire WB_mem_2_reg;
assign {WB_mem_2_reg, WB_reg_write} = WB_ctrl_MEM_WB;

mux_2 #(
   .DATA_W(32)
) regfile_data_mux (
   .input_a  (dram_data_MEM_WB    ),
   .input_b  (alu_out_MEM_WB      ),
   .select_a (WB_mem_2_reg        ),
   .mux_out  (regfile_wdata)
);

endmodule


