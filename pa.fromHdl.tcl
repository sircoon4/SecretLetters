
# PlanAhead Launch Script for Pre-Synthesis Floorplanning, created by Project Navigator

create_project -name SecretLetters -dir "C:/Workspace/SecretLetters/planAhead_run_1" -part xc3s200pq208-4
set_param project.pinAheadLayout yes
set srcset [get_property srcset [current_run -impl]]
set_property target_constrs_file "secret_letters.ucf" [current_fileset -constrset]
set hdlfile [add_files [list {screen_write.vhd}]]
set_property file_type VHDL $hdlfile
set_property library work $hdlfile
set hdlfile [add_files [list {screen_read.vhd}]]
set_property file_type VHDL $hdlfile
set_property library work $hdlfile
set hdlfile [add_files [list {screen_main.vhd}]]
set_property file_type VHDL $hdlfile
set_property library work $hdlfile
set hdlfile [add_files [list {screen_code_write.vhd}]]
set_property file_type VHDL $hdlfile
set_property library work $hdlfile
set hdlfile [add_files [list {screen_code_read.vhd}]]
set_property file_type VHDL $hdlfile
set_property library work $hdlfile
set hdlfile [add_files [list {display_module.vhd}]]
set_property file_type VHDL $hdlfile
set_property library work $hdlfile
set hdlfile [add_files [list {secret_letters.vhd}]]
set_property file_type VHDL $hdlfile
set_property library work $hdlfile
set_property top secret_letters $srcset
add_files [list {secret_letters.ucf}] -fileset [get_property constrset [current_run]]
open_rtl_design -part xc3s200pq208-4
