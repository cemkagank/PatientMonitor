@echo off
REM Windows Batch Script for Development Startup
REM This script launches the PowerShell script

echo === Patient Monitoring App - Development Startup ===
echo.

REM Check if PowerShell is available
powershell -ExecutionPolicy Bypass -File "%~dp0start-dev.ps1"

pause

