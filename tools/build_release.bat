@echo off
setlocal
cd /d "%~dp0"

echo =================================================================
echo   FINCORE FOOD PLATFORM - BUILD E RELEASE AUTOMATICO
echo =================================================================
echo.

powershell -NoProfile -ExecutionPolicy Bypass -File "tools\build_and_package.ps1" %*

if %ERRORLEVEL% NEQ 0 (
    echo.
    echo [ERRO] O processo de release falhou com codigo %ERRORLEVEL%.
    pause
    exit /b %ERRORLEVEL%
)

echo.
echo [CONCLUIDO] Release finalizada com sucesso!
endlocal
