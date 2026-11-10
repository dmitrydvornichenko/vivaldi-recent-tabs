@echo off
rem Windows: double-click to install. Run "install.cmd /u" to uninstall.
if /i "%~1"=="/u" (
  powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0install.ps1" -Uninstall
) else (
  powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0install.ps1"
)
pause
