
# PlanAhead Launch Script for Post-Synthesis floorplanning, created by Project Navigator

create_project -name SecretLetters -dir "C:/Workspace/SecretLetters/planAhead_run_4" -part xc3s200pq208-4
set_property design_mode GateLvl [get_property srcset [current_run -impl]]
set_property edif_top_file "C:/Workspace/SecretLetters/secret_letters.ngc" [ get_property srcset [ current_run ] ]
add_files -norecurse { {C:/Workspace/SecretLetters} }
set_property target_constrs_file "secret_letters.ucf" [current_fileset -constrset]
add_files [list {secret_letters.ucf}] -fileset [get_property constrset [current_run]]
link_design
