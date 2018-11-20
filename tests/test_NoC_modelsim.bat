@echo off
set num=4
set h_size=2
set s1=1
set s2=2

:choose
echo.Enter topology type or help to get it:
set /p type=
if "%type%"=="help" goto help
if "%type%"=="mesh" goto set_params
if "%type%"=="circ2" goto set_params
if "%type%"=="torus" goto set_params
goto help

:set_params
echo.Enter nodes num
set /p num=
if "%type%"=="mesh" goto h_size_set
if "%type%"=="torus" goto h_size_set
if "%type%"=="circ2" goto s1_s2_set

:h_size_set
echo.Enter h_size
set /p h_size=
goto run

:s1_s2_set
echo.Enter s1
set /p s1=
echo.Enter s2
set /p s2=
goto run

:help
echo.
echo.This script runs NoC modeling
echo.Now available mesh, circ2 and torus topologies
exit /B

:run
rem recreate a temp folder for all the simulation files
rd /s /q sim >nul 2>&1
md sim
cd sim
rem generate routing table
python ../../rout_table_gen.py -p ../testfiles -n %type%_rt %type% %num% -h_size %h_size% -s1 %s1% -s2 %s2%
rem start the simulation
vsim -do ../tcls/test_NoC.tcl
rem remove sim folder after finishing
cd ..
rd /s /q sim
exit /B
