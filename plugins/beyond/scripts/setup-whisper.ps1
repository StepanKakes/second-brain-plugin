# setup-whisper.ps1 - stahne whisper.cpp, model a pomocne binarky do brainu (Windows).
#
# Pouziti (z korene brainu):
#   powershell -ExecutionPolicy Bypass -File setup-whisper.ps1
#
# Vsechno konci v <brain>/.beyond/bin a <brain>/.beyond/models.
# Jednorazove ~1,7 GB. Skript je bezpecne pustit znovu, co uz existuje, preskoci.

param(
    [string]$BrainRoot = (Get-Location).Path
)

$ErrorActionPreference = "Stop"
$ProgressPreference = "SilentlyContinue"   # bez teto radky je Invoke-WebRequest u velkych souboru radove pomalejsi

$BinDir = Join-Path $BrainRoot ".beyond\bin"
$ModelDir = Join-Path $BrainRoot ".beyond\models"
$Model = Join-Path $ModelDir "ggml-large-v3-turbo.bin"

foreach ($d in @($BinDir, $ModelDir)) {
    if (-not (Test-Path $d)) { New-Item -ItemType Directory -Path $d -Force | Out-Null }
}

function Stahni {
    param([string]$Url, [string]$Cil, [string]$Popis)
    if (Test-Path $Cil) {
        Write-Output "[setup] $Popis uz je, preskakuji."
        return $true
    }
    Write-Output "[setup] Stahuji $Popis ..."
    try {
        Invoke-WebRequest -Uri $Url -OutFile $Cil -UseBasicParsing -TimeoutSec 1800
        return $true
    } catch {
        Write-Output "[setup] NEPOVEDLO SE: $Popis"
        Write-Output "        $($_.Exception.Message)"
        Write-Output "        Zdroj: $Url"
        if (Test-Path $Cil) { Remove-Item $Cil -Force -ErrorAction SilentlyContinue }
        return $false
    }
}

$chyby = @()

# 1. Model (~1,6 GB)
$modelUrl = "https://huggingface.co/ggerganov/whisper.cpp/resolve/main/ggml-large-v3-turbo.bin?download=true"
if (-not (Stahni $modelUrl $Model "model large-v3-turbo (~1,6 GB)")) {
    $chyby += "model - stahni rucne z https://huggingface.co/ggerganov/whisper.cpp a uloz jako $Model"
}

# 2. whisper.cpp
$whisperExe = Get-ChildItem -Path $BinDir -Recurse -Filter "whisper-cli.exe" -ErrorAction SilentlyContinue | Select-Object -First 1
if (-not $whisperExe) {
    $zip = Join-Path $env:TEMP "whisper-bin-x64.zip"
    $whisperUrl = "https://github.com/ggml-org/whisper.cpp/releases/latest/download/whisper-bin-x64.zip"
    if (Stahni $whisperUrl $zip "whisper.cpp") {
        try {
            Expand-Archive -Path $zip -DestinationPath (Join-Path $BinDir "whisper") -Force
            Remove-Item $zip -Force -ErrorAction SilentlyContinue
        } catch {
            $chyby += "whisper.cpp - rozbaleni selhalo, zkus rucne z https://github.com/ggml-org/whisper.cpp/releases"
        }
    } else {
        $chyby += "whisper.cpp - stahni rucne z https://github.com/ggml-org/whisper.cpp/releases (asset whisper-bin-x64.zip) a rozbal do $BinDir\whisper"
    }
} else {
    Write-Output "[setup] whisper.cpp uz je, preskakuji."
}

# 3. ffmpeg
$ffmpeg = Get-ChildItem -Path $BinDir -Recurse -Filter "ffmpeg.exe" -ErrorAction SilentlyContinue | Select-Object -First 1
if (-not $ffmpeg -and -not (Get-Command ffmpeg -ErrorAction SilentlyContinue)) {
    if (Get-Command winget -ErrorAction SilentlyContinue) {
        Write-Output "[setup] Instaluji ffmpeg pres winget ..."
        winget install --id Gyan.FFmpeg -e --accept-source-agreements --accept-package-agreements --silent | Out-Null
        if (-not (Get-Command ffmpeg -ErrorAction SilentlyContinue)) {
            $chyby += "ffmpeg - winget dobehl, ale ffmpeg neni v PATH. Otevri nove okno terminalu a zkus znovu."
        }
    } else {
        $chyby += "ffmpeg - nainstaluj z https://www.gyan.dev/ffmpeg/builds/ a dej ffmpeg.exe do $BinDir"
    }
} else {
    Write-Output "[setup] ffmpeg uz je, preskakuji."
}

# 4. yt-dlp (volitelne, na odkazy)
$ytdlp = Join-Path $BinDir "yt-dlp.exe"
if (-not (Test-Path $ytdlp)) {
    Stahni "https://github.com/yt-dlp/yt-dlp/releases/latest/download/yt-dlp.exe" $ytdlp "yt-dlp (volitelne)" | Out-Null
}

Write-Output ""
if ($chyby.Count -eq 0) {
    Write-Output "[setup] Hotovo. Prepisy jedou lokalne a zadarmo."
} else {
    Write-Output "[setup] Cast se nepovedla. Bez toho prepisy nepojedou, ale zbytek brainu ano:"
    foreach ($c in $chyby) { Write-Output "  - $c" }
}
