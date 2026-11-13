# 只建项，不执行综合、实现或下载。器件取自原工程 XPR。
set repo_root [file normalize [file join [file dirname [info script]] ..]]
set project_dir [file join $repo_root build vivado]
if {[file exists [file join $project_dir fpga_dds.xpr]]} {
    error "工程已存在，请直接打开 build/vivado/fpga_dds.xpr；脚本不会覆盖它。"
}
create_project fpga_dds $project_dir -part xc7a35tcsg324-1
set_property target_language Verilog [current_project]
add_files [glob [file join $repo_root rtl *.v]]
add_files [file join $repo_root data sin_wave_256x8.mem]
set_property top top [get_filesets sources_1]
add_files -fileset constrs_1 [file join $repo_root constraints ego1_pins.xdc]
add_files -fileset sim_1 [file join $repo_root sim tb_DDS_10MHz.v]
set_property top tb_DDS_10MHz [get_filesets sim_1]
update_compile_order -fileset sources_1
update_compile_order -fileset sim_1
puts "已创建工程；原 XDC 不含完整时序约束。请核对器件、扩展板和接线后再继续。"
