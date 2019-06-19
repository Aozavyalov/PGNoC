@echo off
rem recreate a temp folder for all the simulation files
rd /s /q sim >nul 2>&1
md sim
cd sim

rem generate test file
python ../test_gen.py -p ../testfiles mesh2d

rem start the simulation
vsim -do ../tcls/mesh2d_tb.tcl
rem remove sim folder after finishing
cd ..
rd /s /q sim
