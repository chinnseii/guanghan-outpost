@echo off
set GODOT_EXE=C:\Users\csw83\Documents\Codex\tools\Godot_v4.7-stable_win64.exe
set PROJECT_DIR=%~dp0

if not exist "%GODOT_EXE%" (
  echo Godot executable not found:
  echo %GODOT_EXE%
  pause
  exit /b 1
)

start "" "%GODOT_EXE%" --path "%PROJECT_DIR%"
