@echo off
chcp 65001 > nul

echo =================================================================
echo    FINCORE FOOD PLATFORM - GERADOR DE PACOTE DE RELEASE
echo =================================================================
echo.
echo [*] Fechando instancias ativas do sistema...
taskkill /f /im fincore_food_flutter.exe 2>nul

echo [*] Limpando build anterior...
cd /d "f:\Eigent\fincore_platform\products\fincore-food\fincore_food_flutter"

call flutter clean
if exist "build" rmdir /s /q "build"

echo.
echo [*] Atualizando dependencias e preparando o ambiente C++...
call flutter pub get

if exist "f:\Eigent\fincore_platform\tools\pdfium-win-x64.tgz" (
    echo [*] Injetando binarios nativos do Pdfium para Windows...
    powershell -Command "New-Item -ItemType Directory -Force -Path 'build\windows\x64\pdfium-src', 'build\windows\x64\pdfium-download\pdfium-download-prefix\src'; Copy-Item -Force 'f:\Eigent\fincore_platform\tools\pdfium-win-x64.tgz' 'build\windows\x64\pdfium-download\pdfium-download-prefix\src\pdfium-win-x64.tgz'; tar -xzf 'f:\Eigent\fincore_platform\tools\pdfium-win-x64.tgz' -C 'build\windows\x64\pdfium-src'" > nul 2>&1
)

echo.
echo [*] Compilando executavel Release para Windows...
call flutter build windows --release
if %ERRORLEVEL% NEQ 0 (
    echo.
    echo [ERRO] Falha ao compilar o executavel de Release.
    exit /b %ERRORLEVEL%
)

echo.
echo [OK] Compilacao concluida com sucesso.
echo [*] Gerando pasta de distribuicao 'fincore_food'...

set "DIST_DIR=f:\Eigent\fincore_platform\fincore_food"
set "BUILD_RELEASE=f:\Eigent\fincore_platform\products\fincore-food\fincore_food_flutter\build\windows\x64\runner\Release"

taskkill /f /im fincore_food_flutter.exe 2>nul
ping -n 3 127.0.0.1 > nul

if exist "%DIST_DIR%" rmdir /s /q "%DIST_DIR%"
mkdir "%DIST_DIR%"

xcopy "%BUILD_RELEASE%\*" "%DIST_DIR%\" /E /H /C /I /Y > nul

if exist "f:\Eigent\fincore_platform\products\fincore-food\fincore_food_flutter\.env" (
    copy /y "f:\Eigent\fincore_platform\products\fincore-food\fincore_food_flutter\.env" "%DIST_DIR%\.env" > nul
)

echo [*] Embutindo DLLs de C++ Runtime do Windows (MSVCP140 / VCRUNTIME140)...
powershell -Command "Copy-Item C:\Windows\System32\msvcp140*.dll, C:\Windows\System32\vcruntime140*.dll -Destination '%DIST_DIR%' -ErrorAction SilentlyContinue"

echo ================================================================= > "%DIST_DIR%\COMO_RODAR_EM_OUTRO_PC.txt"
echo   FINCORE FOOD PLATFORM - INSTRUCOES DE INSTALACAO EM OUTRO PC >> "%DIST_DIR%\COMO_RODAR_EM_OUTRO_PC.txt"
echo ================================================================= >> "%DIST_DIR%\COMO_RODAR_EM_OUTRO_PC.txt"
echo. >> "%DIST_DIR%\COMO_RODAR_EM_OUTRO_PC.txt"
echo 1. Copie a pasta 'fincore_food' inteira para o pendrive ou outro computador. >> "%DIST_DIR%\COMO_RODAR_EM_OUTRO_PC.txt"
echo 2. As DLLs do Windows (MSVCP140 e VCRUNTIME140) ja estao embutidas na pasta. >> "%DIST_DIR%\COMO_RODAR_EM_OUTRO_PC.txt"
echo 3. Execute o arquivo 'fincore_food_flutter.exe'. >> "%DIST_DIR%\COMO_RODAR_EM_OUTRO_PC.txt"
echo 4. O banco local (DATA) e os logs (LOG) serao gerados dentro da propria pasta. >> "%DIST_DIR%\COMO_RODAR_EM_OUTRO_PC.txt"
echo 5. Na primeira execucao, o arquivo .env sera criptografado automaticamente com DPAPI (.env.dpapi) para seguranca das credenciais. >> "%DIST_DIR%\COMO_RODAR_EM_OUTRO_PC.txt"

echo.
echo =================================================================
echo [SUCESSO] PACOTE PRONTO PARA TRANSFERENCIA!
echo Localizacao do pacote: %DIST_DIR%
echo.
echo Copie a pasta 'fincore_food' inteira para um Pen Drive/Rede!
echo =================================================================
echo.
