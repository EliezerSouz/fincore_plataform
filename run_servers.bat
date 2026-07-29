@echo off
:: Configura o terminal do script principal para UTF-8
chcp 65001 > nul

echo =================================================================
echo        FINCORE PLATFORM — INICIADOR DE SERVIDORES
echo =================================================================
echo.
echo [*] Iniciando o Servidor Backend (Serverpod) em uma janela separada...
start "FINCORE Backend" powershell -NoExit -Command "cd 'f:\Eigent\fincore_platform\products\fincore-food\fincore_food_server'; echo '--- Servidor Backend FINCORE ---'; dart bin/main.dart"

echo.
echo [*] Iniciando o Servidor Frontend (Flutter) em uma janela separada...
start "FINCORE Frontend" powershell -NoExit -Command "cd 'f:\Eigent\fincore_platform\products\fincore-food\fincore_food_flutter'; echo '--- Servidor Frontend FINCORE ---'; flutter run -d windows"

echo.
echo =================================================================
echo [OK] Ambos os servidores foram abertos em janelas dedicadas!
echo Mantenha-as abertas para acompanhar os logs em tempo real.
echo =================================================================
echo.
pause
