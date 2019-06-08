@echo off
rem recreate a temp folder for all the simulation files
rd /s /q sim >nul 2>&1
md sim
cd sim

rem start the simulation
vsim -do ../tcls/queue_tb.tcl
rem remove sim folder after finishing
cd ..
rd /s /q sim
