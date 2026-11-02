@echo off
setlocal EnableExtensions
cd /d "%~dp0"
set "LOVE_EXE="
if exist "%~dp0love.exe" set "LOVE_EXE=%~dp0love.exe"
if not defined LOVE_EXE if exist "%ProgramFiles%\LOVE\love.exe" set "LOVE_EXE=%ProgramFiles%\LOVE\love.exe"
if not defined LOVE_EXE if exist "%ProgramFiles(x86)%\LOVE\love.exe" set "LOVE_EXE=%ProgramFiles(x86)%\LOVE\love.exe"
if not defined LOVE_EXE for /f "delims=" %%I in ('where love.exe 2^>nul') do if not defined LOVE_EXE set "LOVE_EXE=%%I"
if not defined LOVE_EXE (
  echo [ERRO] LÖVE 11.5 nao encontrado.
  echo Instale LÖVE em https://love2d.org/ ou coloque love.exe nesta pasta.
  echo Depois execute testar.bat novamente.
  pause
  exit /b 1
)
echo [Ibis-Lua] Usando: "%LOVE_EXE%"
echo [Ibis-Lua] Projeto: "%CD%"
"%LOVE_EXE%" "%CD%"
set "EXITCODE=%ERRORLEVEL%"
if not "%EXITCODE%"=="0" (
  echo [ERRO] LÖVE terminou com codigo %EXITCODE%.
  pause
)
exit /b %EXITCODE%
