@echo off
set CMD=%1

if not defined TESTNAME set TESTNAME=tb_processor
if not defined TB_NAME set TB_NAME=test_bench_processor


if "%CMD%"=="" (
    echo Usage: run.bat [build^|run^|waveform^|all^|clean]
    exit /b 0
)

if "%CMD%"=="build" (
    echo [*] Compiling...
    copy "..\testcases\%TESTNAME%.v" "run_test.v" /Y
    iverilog -o simv -f compile.f
    if %errorlevel% neq 0 (
        echo [!] Compilation failed!
        exit /b 1
    )
    exit /b 0
)

if "%CMD%"=="run" (
    echo [*] Running simulation...
    vvp simv
    if %errorlevel% neq 0 (
        echo [!] Simulation failed!
        exit /b 1
    )
    exit /b 0
)

if "%CMD%"=="waveform" (
    echo [*] Opening waveform...
    gtkwave %TB_NAME%.vcd
    exit /b 0
)

if "%CMD%"=="all" (
    call "%~f0" build
    if %errorlevel% neq 0 exit /b 1
    call "%~f0" run
    exit /b 0
)

if "%CMD%"=="clean" (
    echo [*] Cleaning...
    del /q simv 2>nul
    del /q %TB_NAME%.vcd 2>nul
    del /q run_test.v 2>nul
    echo Done.
    exit /b 0
)

echo Unknown command: %CMD%
echo Usage: run.bat [build^|run^|waveform^|all^|clean]
exit /b 1
