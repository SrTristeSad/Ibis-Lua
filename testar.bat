@echo off
setlocal EnableExtensions DisableDelayedExpansion
title Ibis-Lua - Teste visual

rem Executa a casca visual a partir da propria pasta deste .bat.
cd /d "%~dp0"
if errorlevel 1 (
    echo [ERRO] Nao foi possivel abrir a pasta do Ibis-Lua.
    pause
    exit /b 1
)
if not exist "main.lua" (
    echo [ERRO] main.lua nao encontrado. Deixe testar.bat na raiz do projeto.
    pause
    exit /b 1
)

rem LOVE_EXE pode ser definido pelo usuario para um caminho personalizado.
if defined LOVE_EXE if not exist "%LOVE_EXE%" set "LOVE_EXE="
if not defined LOVE_EXE if exist "%~dp0love.exe" set "LOVE_EXE=%~dp0love.exe"
if not defined LOVE_EXE if exist "%~dp0LOVE\love.exe" set "LOVE_EXE=%~dp0LOVE\love.exe"
if not defined LOVE_EXE if exist "%ProgramFiles%\LOVE\love.exe" set "LOVE_EXE=%ProgramFiles%\LOVE\love.exe"
if not defined LOVE_EXE if exist "%ProgramFiles(x86)%\LOVE\love.exe" set "LOVE_EXE=%ProgramFiles(x86)%\LOVE\love.exe"
if not defined LOVE_EXE if exist "%LOCALAPPDATA%\Programs\LOVE\love.exe" set "LOVE_EXE=%LOCALAPPDATA%\Programs\LOVE\love.exe"
if not defined LOVE_EXE for /f "delims=" %%F in ('where love.exe 2^>nul') do if not defined LOVE_EXE set "LOVE_EXE=%%F"

if not defined LOVE_EXE (
    echo [ERRO] LÖVE nao foi encontrado.
    echo Instale o LÖVE 11.5 em https://love2d.org/ e execute testar.bat de novo.
    echo Alternativa: coloque love.exe e as DLLs do LÖVE na pasta do projeto.
    pause
    exit /b 1
)

echo [Ibis-Lua] Executando interface visual com:
echo %LOVE_EXE%
echo.
"%LOVE_EXE%" "%CD%"
set "RESULT=%ERRORLEVEL%"
if not "%RESULT%"=="0" (
    echo.
    echo [ERRO] O LÖVE encerrou com codigo %RESULT%.
    echo Confira a mensagem de erro exibida pelo aplicativo.
    pause
)
exit /b %RESULT%
