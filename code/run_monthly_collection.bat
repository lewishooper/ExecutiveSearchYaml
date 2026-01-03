@echo off
REM ============================================================================
REM Monthly Hospital Executive Data Collection - Windows Task Scheduler Script
REM ============================================================================
REM This batch file runs the automated monthly collection process
REM Schedule this to run on the 1st of each month at 2:00 AM
REM
REM Location: E:\ExecutiveSearchYaml\code\run_monthly_collection.bat
REM ============================================================================

REM Set the working directory
cd /d E:\ExecutiveSearchYaml\code

REM Set R script path
set RSCRIPT="C:\Program Files\R\R-4.5.1\bin\Rscript.exe"

REM Log the start time
echo ============================================================================ >> E:\ExecutiveSearchYaml\tracking\scheduler.log
echo Scheduled run started at %date% %time% >> E:\ExecutiveSearchYaml\tracking\scheduler.log
echo ============================================================================ >> E:\ExecutiveSearchYaml\tracking\scheduler.log

REM Run the R script
%RSCRIPT% --vanilla -e "source('E:/ExecutiveSearchYaml/code/monthly_executive_collection.R'); result <- run_monthly_collection(); if (!result$success) { quit(status = 1) }"

REM Check if R script succeeded
if %ERRORLEVEL% EQU 0 (
    echo Scheduled run completed successfully at %date% %time% >> E:\ExecutiveSearchYaml\tracking\scheduler.log
    echo. >> E:\ExecutiveSearchYaml\tracking\scheduler.log
    exit /b 0
) else (
    echo Scheduled run FAILED at %date% %time% >> E:\ExecutiveSearchYaml\tracking\scheduler.log
    echo. >> E:\ExecutiveSearchYaml\tracking\scheduler.log
    exit /b 1
)