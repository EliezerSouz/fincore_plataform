@echo off
chcp 65001 > nul

echo =================================================================
echo    FINCORE FOOD PLATFORM - INICIADOR DE RELEASE E EMPACOTAMENTO
echo =================================================================
echo.

set "SCRIPT_PATH=%~dp0tools\build_and_package.ps1"

if "%1"=="" (
    echo Selecione o tipo de versão:
    echo   [1] Manter versão atual
    echo   [2] Incrementar PATCH (correções de bugs e ajustes, ex: 1.3.1 -^> 1.3.2)
    echo   [3] Incrementar MINOR (novas telas e funcionalidades, ex: 1.3.1 -^> 1.4.0)
    echo   [4] Incrementar MAJOR (grandes reestruturações, ex: 1.3.1 -^> 2.0.0)
    echo.
    set /p ESCOLHA="Escolha uma opção [1-4] (padrão: 1): "
    
    echo.
    set /p MOTIVO="Descreva o motivo / novidades desta versão (Changelog): "
    
    if "%ESCOLHA%"=="2" (
        powershell -NoProfile -ExecutionPolicy Bypass -File "%SCRIPT_PATH%" -Bump patch -ReleaseNotes "%MOTIVO%"
    ) else if "%ESCOLHA%"=="3" (
        powershell -NoProfile -ExecutionPolicy Bypass -File "%SCRIPT_PATH%" -Bump minor -ReleaseNotes "%MOTIVO%"
    ) else if "%ESCOLHA%"=="4" (
        powershell -NoProfile -ExecutionPolicy Bypass -File "%SCRIPT_PATH%" -Bump major -ReleaseNotes "%MOTIVO%"
    ) else (
        powershell -NoProfile -ExecutionPolicy Bypass -File "%SCRIPT_PATH%" -ReleaseNotes "%MOTIVO%"
    )
) else (
    powershell -NoProfile -ExecutionPolicy Bypass -File "%SCRIPT_PATH%" %*
)

echo.
pause
