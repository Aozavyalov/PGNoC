@echo off
set num=4
set h_size=2
set s1=1
set s2=2

:choose
set type=%1
if "%type%"=="help" goto help
if "%type%"=="mesh" goto set_params
if "%type%"=="circ2" goto set_params
if "%type%"=="torus" goto set_params
goto help

:set_params
set num=%2
if "%type%"=="mesh" goto h_size_set
if "%type%"=="torus" goto h_size_set
if "%type%"=="circ2" goto s1_s2_set

:h_size_set
set h_size=%3
goto run

:s1_s2_set
set s1=%3
set s2=%4
goto run

:help
echo.
echo.This script runs NoC modeling
echo.Now available mesh, circ2 and torus topologies
echo.Usage: test_NoC_modelsim.bat [help] {mesh, circ2, torus} nodes_num [h_size] [s1 s2]
exit /B

:run
rem recreate a temp folder for all the simulation files
rd /s /q sim >nul 2>&1
md sim
cd sim
rem generate routing table
python ../../rout_table_gen.py -p ../ -n %type%_rt %type% %num% -h_size %h_size% -s1 %s1% -s2 %s2%
rem start the simulation
vsim -do ../tcls/test_NoC.tcl
rem remove sim folder after finishing
cd ..
rd /s /q sim
del %type%_rt.srtf
exit /B
