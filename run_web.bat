@echo off
chcp 65001 > nul

echo =================================================================
echo    FINCORE PLATFORM - INICIADOR NAVEGADOR (Flutter Web)
echo =================================================================
echo.
echo [*] Verificando Docker Desktop...
docker info > nul 2>&1
if %ERRORLEVEL% NEQ 0 goto :NODOCKER

echo [OK] Docker Desktop detectado.
echo [*] Iniciando PostgreSQL local...
cd /d "f:\Eigent\fincore_platform"
docker compose up -d postgres
echo [OK] PostgreSQL local rodando na porta 8090.
echo.
goto :RUNAPP

:NODOCKER
echo [AVISO] Docker Desktop nao detectado ou nao esta rodando.
echo         O banco PostgreSQL via Docker nao sera iniciado.
echo.

:RUNAPP
echo =================================================================
echo [*] Iniciando o App FINCORE Food no Navegador (Chrome)...
echo =================================================================
echo.

powershell -NoExit -Command "cd 'f:\Eigent\fincore_platform\products\fincore-food\fincore_food_flutter'; Write-Host '--- FINCORE Food App (Web Chrome) ---' -ForegroundColor Green; flutter run -d chrome"

pause
