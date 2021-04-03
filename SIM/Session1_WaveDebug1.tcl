
# NC-Sim Command File
# TOOL:	ncsim(64)	15.20-s058
#
#
# You can restore this configuration with:
#
#      ncverilog +sv -f files_verilog.f +nc64bit +nctimescale+1ns/10ps +access+rwc -ALLOWREDEFINITION -linedebug +gui +tcl+Session1_WaveDebug1.tcl
#

set tcl_prompt1 {puts -nonewline "ncsim> "}
set tcl_prompt2 {puts -nonewline "> "}
set vlog_format %h
set vhdl_format %v
set real_precision 6
set display_unit auto
set time_unit module
set heap_garbage_size -200
set heap_garbage_time 0
set assert_report_level note
set assert_stop_level error
set autoscope yes
set assert_1164_warnings yes
set pack_assert_off {}
set severity_pack_assert_off {note warning}
set assert_output_stop_level failed
set tcl_debug_level 0
set relax_path_name 1
set vhdl_vcdmap XX01ZX01X
set intovf_severity_level ERROR
set probe_screen_format 0
set rangecnst_severity_level ERROR
set textio_severity_level ERROR
set vital_timing_checks_on 1
set vlog_code_show_force 0
set assert_count_attempts 1
set tcl_all64 false
set tcl_runerror_exit false
set assert_report_incompletes 0
set show_force 1
set force_reset_by_reinvoke 0
set tcl_relaxed_literal 0
set probe_exclude_patterns {}
set probe_packed_limit 4k
set probe_unpacked_limit 16k
set assert_internal_msg no
set svseed 1
set assert_reporting_mode 0
alias . run
alias iprof profile
alias quit exit
database -open -vcd -into vcd_dump.vcd _vcd_dump.vcd1 -timescale fs
database -open -evcd -into vcd_dump.vcd _vcd_dump.vcd -timescale fs
database -open -shm -into waves.shm waves -default
probe -create -database waves cpu_tb.dut.clk
probe -create -database waves cpu_tb.dut.instruction cpu_tb.dut.updated_pc cpu_tb.dut.current_pc cpu_tb.dut.instruction_IF_ID cpu_tb.dut.updated_pc_IF_ID cpu_tb.dut.EXE_ctrl cpu_tb.dut.MEM_ctrl cpu_tb.dut.WB_ctrl cpu_tb.dut.regfile_data_1 cpu_tb.dut.regfile_data_2 cpu_tb.dut.immediate_extended
probe -create -database waves cpu_tb.dut.EXE_alu_src cpu_tb.dut.EXE_alu_op cpu_tb.dut.EXE_reg_dst cpu_tb.dut.WB_ctrl_ID_EXE cpu_tb.dut.MEM_ctrl_ID_EXE cpu_tb.dut.alu_out cpu_tb.dut.regfile_waddr
probe -create -database waves cpu_tb.dut.MEM_jump cpu_tb.dut.MEM_mem_read cpu_tb.dut.MEM_mem_write cpu_tb.dut.MEM_branch cpu_tb.dut.WB_ctrl_EXE_MEM
probe -create -database waves cpu_tb.dut.dram_data cpu_tb.dut.alu_out_EXE_MEM cpu_tb.dut.regfile_data_2_EXE_MEM cpu_tb.dut.regfile_waddr_EXE_MEM cpu_tb.dut.WB_mem_2_reg cpu_tb.dut.WB_reg_write cpu_tb.dut.alu_out_MEM_WB cpu_tb.dut.dram_data_MEM_WB
probe -create -database waves cpu_tb.dut.instruction_ID_EXE cpu_tb.dut.immediate_extended_ID_EXE cpu_tb.dut.updated_pc_ID_EXE cpu_tb.dut.regfile_data_2_ID_EXE cpu_tb.dut.regfile_data_1_ID_EXE

simvision -input Session1_WaveDebug1.tcl.svcf
