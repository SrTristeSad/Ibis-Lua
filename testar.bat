@echo off
setlocal EnableExtensions
cd /d "%~dp0"

set "LOVE_EXE="
for %%P in ("%ProgramFiles%\LOVE\love.exe" "%ProgramFiles(x86)%\LOVE\love.exe" "%LOCALAPPDATA%\Programs\LOVE\love.exe") do (
    if exist "%%~P" set "LOVE_EXE=%%~P"
)
if not defined LOVE_EXE (
    for /f "delims=" %%P in ('where love.exe 2^>nul') do (
        if not defined LOVE_EXE set "LOVE_EXE=%%P"
    )
)
if not defined LOVE_EXE (
    echo [ERRO] LÖVE nao encontrado. Instale o LÖVE 11.5 em https://love2d.org/
    echo [INFO] O projeto ainda esta em fase de pesquisa; nao ha interface fiel publicada.
    exit /b 1
)
if not exist "main.lua" (
    echo [ERRO] main.lua nao encontrado na pasta do projeto.
    exit /b 2
)
echo [INFO] Iniciando diagnostico do Ibis-Lua com "%LOVE_EXE%"...
"%LOVE_EXE%" "%CD%"
set "EXITCODE=%ERRORLEVEL%"
if not "%EXITCODE%"=="0" echo [ERRO] LÖVE terminou com codigo %EXITCODE%.
exit /b %EXITCODE%
