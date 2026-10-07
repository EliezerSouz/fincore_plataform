# ==============================================================================
# FINCORE PLATFORM - RELEASE & VERSIONING PIPELINE (Windows Desktop)
# ==============================================================================
# Executa compilação Release, empacotamento completo (FULL) e pacote delta (UPDATE),
# gerando arquivos .zip datados e mantendo o histórico oficial de versões.
# ==============================================================================

param (
    [string]$Bump = "", # 'patch', 'minor', 'major' ou vazio para manter atual
    [string]$ReleaseNotes = "",
    [switch]$CreateZip = $false # Por padrão gera apenas as pastas sem compactar .zip
)

$ErrorActionPreference = "Stop"
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

$rootDir = "f:\Eigent\fincore_platform"
$flutterDir = Join-Path $rootDir "products\fincore-food\fincore_food_flutter"
$pubspecPath = Join-Path $flutterDir "pubspec.yaml"
$appConstantsPath = Join-Path $rootDir "packages\fincore_core\lib\common\app_constants.dart"
$releasesDir = Join-Path $rootDir "releases"
$manifestPath = Join-Path $releasesDir "releases_manifest.json"
$releasesMdPath = Join-Path $releasesDir "RELEASES.md"
$toolsDir = Join-Path $rootDir "tools"

Write-Host "=================================================================" -ForegroundColor Cyan
Write-Host "   FINCORE FOOD PLATFORM - SISTEMA AUTOMATICO DE RELEASES" -ForegroundColor Cyan
Write-Host "=================================================================" -ForegroundColor Cyan
Write-Host ""

# 1. Leitura e Cálculo de Versão
if (-not (Test-Path $pubspecPath)) {
    Write-Error "Arquivo pubspec.yaml não encontrado em: $pubspecPath"
}

$pubspecContent = Get-Content $pubspecPath -Raw
if ($pubspecContent -match 'version:\s*([0-9]+)\.([0-9]+)\.([0-9]+)(\+([0-9]+))?') {
    $major = [int]$matches[1]
    $minor = [int]$matches[2]
    $patch = [int]$matches[3]
    $buildNum = if ($matches[5]) { [int]$matches[5] } else { 1 }
} else {
    Write-Error "Não foi possível identificar a versão no pubspec.yaml"
}

$oldVersion = "$major.$minor.$patch"

if ($Bump -eq "major") {
    $major++
    $minor = 0
    $patch = 0
    $buildNum++
} elseif ($Bump -eq "minor") {
    $minor++
    $patch = 0
    $buildNum++
} elseif ($Bump -eq "patch") {
    $patch++
    $buildNum++
}

$currentVersion = "$major.$minor.$patch"
$currentVersionFull = "$currentVersion+$buildNum"
$today = (Get-Date).ToString("yyyy-MM-dd")
$timestamp = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")

Write-Host "[*] Versão Atual: v$currentVersion (Build $buildNum)" -ForegroundColor Green
if ($oldVersion -ne $currentVersion) {
    Write-Host "    -> Atualizando versão de v$oldVersion para v$currentVersion..." -ForegroundColor Yellow
    # Atualiza pubspec.yaml
    $newPubspec = $pubspecContent -replace 'version:\s*[0-9]+\.[0-9]+\.[0-9]+(\+[0-9]+)?', "version: $currentVersionFull"
    Set-Content -Path $pubspecPath -Value $newPubspec -NoNewline

    # Atualiza app_constants.dart
    if (Test-Path $appConstantsPath) {
        $constantsContent = Get-Content $appConstantsPath -Raw
        $newConstants = $constantsContent -replace "static const String version = 'v[^']+';", "static const String version = 'v$currentVersion';"
        Set-Content -Path $appConstantsPath -Value $newConstants -NoNewline
    }
}

# 2. Obter Informações do Git (Hash e Último Commit)
$gitCommit = "desconhecido"
$gitMessage = ""
try {
    $gitCommit = (git rev-parse --short HEAD 2>$null)
    $gitMessage = (git log -1 --pretty=%B 2>$null).Trim()
} catch {}

if ([string]::IsNullOrWhiteSpace($ReleaseNotes)) {
    if ([Environment]::UserInteractive -and -not [Console]::IsInputRedirected) {
        try {
            $userNotes = Read-Host "Informe o motivo/resumo das alterações desta versão (pressione Enter para usar o commit)"
            if (-not [string]::IsNullOrWhiteSpace($userNotes)) {
                $ReleaseNotes = $userNotes.Trim()
            }
        } catch {}
    }
    if ([string]::IsNullOrWhiteSpace($ReleaseNotes)) {
        $ReleaseNotes = if ($gitMessage) { $gitMessage } else { "Release v$currentVersion compilado e empacotado." }
    }
}

# 3. Fechar instâncias ativas do executável antes de compilar
Write-Host "[*] Fechando instâncias do fincore_food_flutter.exe em execução..." -ForegroundColor Yellow
Get-Process "fincore_food_flutter" -ErrorAction SilentlyContinue | Stop-Process -Force -ErrorAction SilentlyContinue
Start-Sleep -Seconds 1

# 4. Compilação Release
Write-Host "[*] Preparando dependências e compilando Flutter Windows Release..." -ForegroundColor Yellow
Set-Location $flutterDir

# Injeta binários nativos do Pdfium se disponível
$pdfiumTgz = Join-Path $toolsDir "pdfium-win-x64.tgz"
if (Test-Path $pdfiumTgz) {
    $pdfiumSrc = "build\windows\x64\pdfium-src"
    $pdfiumPrefix = "build\windows\x64\pdfium-download\pdfium-download-prefix\src"
    New-Item -ItemType Directory -Force -Path $pdfiumSrc, $pdfiumPrefix | Out-Null
    Copy-Item -Force $pdfiumTgz (Join-Path $pdfiumPrefix "pdfium-win-x64.tgz")
    tar -xzf $pdfiumTgz -C $pdfiumSrc 2>$null
}

# Garante que os arquivos nativos de C++ do Flutter Engine estejam presentes em ephemeral
try {
    $flutterCmd = Get-Command flutter -ErrorAction SilentlyContinue
    if ($flutterCmd) {
        $flutterBin = Split-Path $flutterCmd.Source
        $engineArtifacts = Join-Path $flutterBin "cache\artifacts\engine\windows-x64"
        $ephemeralDir = Join-Path $flutterDir "windows\flutter\ephemeral"
        $targetWrapper = Join-Path $ephemeralDir "cpp_client_wrapper"

        if (Test-Path (Join-Path $engineArtifacts "cpp_client_wrapper")) {
            New-Item -ItemType Directory -Force -Path $targetWrapper | Out-Null
            Copy-Item -Path (Join-Path $engineArtifacts "cpp_client_wrapper\*") -Destination $targetWrapper -Recurse -Force -ErrorAction SilentlyContinue
            Copy-Item -Path (Join-Path $engineArtifacts "flutter_*.h") -Destination $ephemeralDir -Force -ErrorAction SilentlyContinue
        }
    }
} catch {
    Write-Host "    [AVISO] Falha ao verificar artifacts do Flutter SDK: $_" -ForegroundColor DarkGray
}

flutter build windows --release
if ($LASTEXITCODE -ne 0) {
    Write-Error "Falha na compilação do Flutter Release (código $LASTEXITCODE)."
}
Write-Host "[OK] Compilação Release finalizada com sucesso." -ForegroundColor Green

# 5. Estruturação dos Pacotes
$buildReleaseDir = Join-Path $flutterDir "build\windows\x64\runner\Release"
if (-not (Test-Path $buildReleaseDir)) {
    Write-Error "Diretório de build release não encontrado: $buildReleaseDir"
}

New-Item -ItemType Directory -Force -Path $releasesDir | Out-Null

$releaseFolder = Join-Path $releasesDir "v${currentVersion}_${today}"
if (Test-Path $releaseFolder) {
    Remove-Item -Path $releaseFolder -Recurse -Force
}
New-Item -ItemType Directory -Force -Path $releaseFolder | Out-Null

$fullPackageDir = Join-Path $releaseFolder "fincore_food"
$updatePackageDir = Join-Path $releaseFolder "fincore_food_update"

New-Item -ItemType Directory -Force -Path $fullPackageDir | Out-Null
New-Item -ItemType Directory -Force -Path $updatePackageDir | Out-Null

Write-Host "[*] Montando arquivos do pacote FULL..." -ForegroundColor Yellow
Copy-Item -Path "$buildReleaseDir\*" -Destination $fullPackageDir -Recurse -Force

# Copia .env padrão se existir
$envPath = Join-Path $flutterDir ".env"
if (Test-Path $envPath) {
    Copy-Item -Force $envPath (Join-Path $fullPackageDir ".env")
}

# Embutir DLLs de C++ Runtime do Windows
$sys32 = "$env:windir\System32"
Copy-Item "$sys32\msvcp140*.dll" -Destination $fullPackageDir -Force -ErrorAction SilentlyContinue
Copy-Item "$sys32\vcruntime140*.dll" -Destination $fullPackageDir -Force -ErrorAction SilentlyContinue

# Instruções de Instalação e Atualização na pasta principal de releases e no pacote full
$instrucoesGeral = @"
=================================================================
  FINCORE FOOD PLATFORM - v$currentVersion ($today)
  GUIA DE INSTALACAO E ATUALIZACAO
=================================================================

1. INSTALACAO NOVA (Pasta 'fincore_food'):
   - Copie a pasta 'fincore_food' inteira para onde desejar (ex: C:\fincore_food).
   - As DLLs de runtime necessarias ja estao incluidas.
   - Execute 'fincore_food_flutter.exe'.
   - O banco local (DATA) e os logs (LOG) serao gerados automaticamente.
   - Na primeira execucao, o arquivo .env sera protegido via DPAPI (.env.dpapi).

2. ATUALIZACAO RAPIDA (Pasta 'fincore_food_update'):
   - Feche o FINCORE Food caso esteja em execucao.
   - Copie todo o conteudo da pasta 'fincore_food_update' (executavel, pasta data e DLLs)
     diretamente para a pasta onde o FINCORE Food ja esta instalado, substituindo os arquivos.
   - Seus dados de vendas (pasta DATA), configuracoes e banco local NUNCA sao afetados.
   - Abra o 'fincore_food_flutter.exe' normalmente.
=================================================================
"@

# Salva apenas na pasta principal de releases e dentro do pacote full (mantendo a pasta de versão apenas com as subpastas)
Set-Content -Path (Join-Path $releasesDir "LEIA-ME_INSTALACAO.txt") -Value $instrucoesGeral -Encoding UTF8
Set-Content -Path (Join-Path $fullPackageDir "LEIA-ME_INSTALACAO.txt") -Value $instrucoesGeral -Encoding UTF8

Write-Host "[*] Montando arquivos do pacote UPDATE (Apenas Atualização)..." -ForegroundColor Yellow
# O pacote de atualização contém APENAS o executável, pasta data e DLLs (sem scripts ou arquivos extras)
Copy-Item (Join-Path $buildReleaseDir "fincore_food_flutter.exe") -Destination $updatePackageDir -Force
Copy-Item -Path (Join-Path $buildReleaseDir "data") -Destination $updatePackageDir -Recurse -Force
Copy-Item (Join-Path $buildReleaseDir "*.dll") -Destination $updatePackageDir -Force

# Garantia absoluta: não conter nenhum script (.bat), instrução (.txt) ou arquivo extra na pasta de update
Get-ChildItem -Path $updatePackageDir -Include "*.bat", "*.txt" -Recurse -File -ErrorAction SilentlyContinue | Remove-Item -Force -ErrorAction SilentlyContinue

# Também copia para a pasta raiz fincore_food para manter compatibilidade com scripts locais
$rootDistDir = Join-Path $rootDir "fincore_food"
if (Test-Path $rootDistDir) { Remove-Item $rootDistDir -Recurse -Force }
Copy-Item -Path $fullPackageDir -Destination $rootDistDir -Recurse -Force

# Função auxiliar para medir tamanho de pastas em MB
function Get-FolderSizeMB ($folderPath) {
    if (Test-Path $folderPath) {
        $measure = Get-ChildItem -Path $folderPath -Recurse -File -ErrorAction SilentlyContinue | Measure-Object -Property Length -Sum
        if ($measure.Sum) {
            return "{0:N2} MB" -f ($measure.Sum / 1MB)
        }
    }
    return "0.00 MB"
}

$fullSizeStr = Get-FolderSizeMB $fullPackageDir
$updateSizeStr = Get-FolderSizeMB $updatePackageDir

# 6. Compactação em .ZIP (Opcional - ativada apenas se o switch -CreateZip for fornecido)
$fullZipName = "fincore_food_v${currentVersion}_${today}_FULL.zip"
$updateZipName = "fincore_food_v${currentVersion}_${today}_UPDATE.zip"
$fullZipPath = Join-Path $releasesDir $fullZipName
$updateZipPath = Join-Path $releasesDir $updateZipName
$fullZipSizeStr = $null
$updateZipSizeStr = $null

if ($CreateZip) {
    Write-Host "[*] Compactando pacote FULL: $fullZipName ..." -ForegroundColor Yellow
    if (Test-Path $fullZipPath) { Remove-Item $fullZipPath -Force }
    Compress-Archive -Path "$fullPackageDir" -DestinationPath $fullZipPath -CompressionLevel Optimal

    Write-Host "[*] Compactando pacote UPDATE: $updateZipName ..." -ForegroundColor Yellow
    if (Test-Path $updateZipPath) { Remove-Item $updateZipPath -Force }
    Compress-Archive -Path "$updatePackageDir\*" -DestinationPath $updateZipPath -CompressionLevel Optimal

    $fullZipSize = (Get-Item $fullZipPath).Length / 1MB
    $updateZipSize = (Get-Item $updateZipPath).Length / 1MB
    $fullZipSizeStr = "{0:N2} MB" -f $fullZipSize
    $updateZipSizeStr = "{0:N2} MB" -f $updateZipSize
}

# 7. Atualizar Manifesto JSON
$manifestData = @()
if (Test-Path $manifestPath) {
    try {
        $manifestJson = Get-Content $manifestPath -Raw | ConvertFrom-Json
        if ($manifestJson -is [System.Collections.IEnumerable]) {
            $manifestData = @($manifestJson)
        } else {
            $manifestData = @($manifestJson)
        }
    } catch {}
}

$releaseFolderName = "v${currentVersion}_${today}"
$newReleaseEntry = [PSCustomObject]@{
    version = "v$currentVersion"
    buildNumber = $buildNum
    date = $today
    timestamp = $timestamp
    gitCommit = $gitCommit
    notes = $ReleaseNotes
    folder = $releaseFolderName
    fullPackage = "$releaseFolderName/fincore_food"
    fullSize = $fullSizeStr
    updatePackage = "$releaseFolderName/fincore_food_update"
    updateSize = $updateSizeStr
    fullZip = if ($CreateZip) { $fullZipName } else { $null }
    fullZipSize = $fullZipSizeStr
    updateZip = if ($CreateZip) { $updateZipName } else { $null }
    updateZipSize = $updateZipSizeStr
}

$manifestData = @($newReleaseEntry) + @($manifestData | Where-Object { $_.version -ne "v$currentVersion" })

$manifestJsonStr = $manifestData | ConvertTo-Json -Depth 5
[System.IO.File]::WriteAllText($manifestPath, $manifestJsonStr, [System.Text.UTF8Encoding]::new($false))

# 8. Atualizar RELEASES.md
$mdHeader = @"
# 📦 Histórico Oficial de Releases e Builds - FINCORE Platform

Este arquivo é mantido automaticamente pelo script de release (`tools/build_and_package.ps1`).

| Versão | Data | Commit | Pacote FULL | Pacote UPDATE | Notas de Release |
| :--- | :--- | :--- | :--- | :--- | :--- |
"@

$mdRows = @()
foreach ($entry in $manifestData) {
    $notesClean = $entry.notes -replace '[\r\n]+', ' '
    $fullLabel = if ($entry.fullZip) { "[$($entry.fullZip)]($($entry.fullZip)) ($($entry.fullZipSize))" } elseif ($entry.fullPackage) { "[$($entry.fullPackage)]($($entry.fullPackage)) ($($entry.fullSize))" } else { "[$($entry.folder)/fincore_food]($($entry.folder)/fincore_food)" }
    $updateLabel = if ($entry.updateZip) { "[$($entry.updateZip)]($($entry.updateZip)) ($($entry.updateZipSize))" } elseif ($entry.updatePackage) { "[$($entry.updatePackage)]($($entry.updatePackage)) ($($entry.updateSize))" } else { "[$($entry.folder)/fincore_food_update]($($entry.folder)/fincore_food_update)" }
    $mdRows += "| **$($entry.version)** (Build $($entry.buildNumber)) | $($entry.date) | ``$($entry.gitCommit)`` | $fullLabel | $updateLabel | $notesClean |"
}

$mdContent = $mdHeader + "`n" + ($mdRows -join "`n") + "`n"
[System.IO.File]::WriteAllText($releasesMdPath, $mdContent, [System.Text.UTF8Encoding]::new($false))

Write-Host ""
Write-Host "=================================================================" -ForegroundColor Green
Write-Host " [SUCESSO] RELEASE GERADA COM SUCESSO!" -ForegroundColor Green
Write-Host "=================================================================" -ForegroundColor Green
Write-Host "  Versao:      v$currentVersion (Build $buildNum)" -ForegroundColor White
Write-Host "  Data:        $today" -ForegroundColor White
Write-Host "  Commit Git:  $gitCommit" -ForegroundColor White
Write-Host "-----------------------------------------------------------------" -ForegroundColor Gray
Write-Host "  Pasta da Release: $releaseFolder" -ForegroundColor Green
Write-Host "    - FULL:         fincore_food ($fullSizeStr)" -ForegroundColor Cyan
Write-Host "    - UPDATE:       fincore_food_update ($updateSizeStr) [somente binarios]" -ForegroundColor Cyan
Write-Host "  Guia Instalacao:  $releasesDir\LEIA-ME_INSTALACAO.txt" -ForegroundColor Yellow
Write-Host "  Historico:        $releasesMdPath" -ForegroundColor Yellow
if ($CreateZip) {
    Write-Host "  Pacote FULL ZIP:   $fullZipPath ($fullZipSizeStr)" -ForegroundColor Gray
    Write-Host "  Pacote UPDATE ZIP: $updateZipPath ($updateZipSizeStr)" -ForegroundColor Gray
}
Write-Host "=================================================================" -ForegroundColor Green
Write-Host ""
