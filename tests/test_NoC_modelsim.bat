@echo off
rem recreate a temp folder for all the simulation files
rd /s /q sim >nul 2>&1
md sim
cd sim
rem generate routing table
python ../../rout_table_gen.py -p ../testfiles -n torus_rt -h_size 3 torus 9
rem start the simulation
vsim -do ../tcls/test_NoC.tcl
rem remove sim folder after finishing
cd ..
rd /s /q sim
