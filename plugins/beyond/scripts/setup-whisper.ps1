# setup-whisper.ps1 - zaridi lokalni prepisy (Windows).
#
# Nejdriv se podiva, jestli whisper a model uz nekde v pocitaci nejsou.
# Hleda v PATH a v mistech, kam je davaji aplikace, ktere whisper.cpp
# balicuji (Subtitle Edit, Buzz, WhisperDesktop a spol.). Kdyz neco najde,
# jen si k tomu poznamena cestu. Stahuje se az to, co se nenajde.
#
# Pouziti (z korene brainu):
#   powershell -ExecutionPolicy Bypass -File setup-whisper.ps1
#   $env:BEYOND_WHISPER_STAHNI=1; powershell ... -File setup-whisper.ps1   # preskoc hledani
#
# Vsechno konci v <brain>/.beyond/bin a <brain>/.beyond/models.
# Skript je bezpecne pustit znovu, co uz existuje, preskoci.

param(
    [string]$BrainRoot = (Get-Location).Path
)

$ErrorActionPreference = "Stop"
$ProgressPreference = "SilentlyContinue"   # bez teto radky je Invoke-WebRequest u velkych souboru radove pomalejsi

$BinDir = Join-Path $BrainRoot ".beyond\bin"
$ModelDir = Join-Path $BrainRoot ".beyond\models"
$Model = Join-Path $ModelDir "ggml-large-v3-turbo.bin"
$CestaSoubor = Join-Path $BrainRoot ".beyond\whisper-cesta.txt"
$ZdrojSoubor = Join-Path $BrainRoot ".beyond\whisper-zdroj.txt"
$Stahni = ($env:BEYOND_WHISPER_STAHNI -eq "1")

foreach ($d in @($BinDir, $ModelDir)) {
    if (-not (Test-Path $d)) { New-Item -ItemType Directory -Path $d -Force | Out-Null }
}

$chyby = @()
$prevzato = @()

function Stahni-Soubor {
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

# Overi, ze nalezena binarka fakt nabehne. Whisper z cizi aplikace miva
# vedle sebe svoje DLL, proto ho nikam nekopirujeme a spousti se z mista.
function Funguje-Whisper {
    param([string]$Cesta)
    if (-not (Test-Path $Cesta)) { return $false }
    try {
        & $Cesta --help *> $null
        return ($LASTEXITCODE -eq 0)
    } catch {
        return $false
    }
}

# Skore modelu podle nazvu. Cim vetsi model, tim lepsi prepis.
function Skore-Modelu {
    param([string]$Jmeno)
    $j = $Jmeno.ToLower()
    if ($j -match "silero|vad|encoder") { return 0 }
    if ($j -match "large-v3-turbo")     { return 90 }
    if ($j -match "large-v3")           { return 80 }
    if ($j -match "large-v2")           { return 70 }
    if ($j -match "large")              { return 60 }
    if ($j -match "medium")             { return 50 }
    if ($j -match "small")              { return 40 }
    if ($j -match "base")               { return 30 }
    if ($j -match "tiny")               { return 20 }
    return 0
}

function Hledej-Soubory {
    param([string[]]$Koreny, [string]$Maska, [int]$Hloubka = 4)
    $vysledky = @()
    foreach ($k in $Koreny) {
        if ([string]::IsNullOrWhiteSpace($k)) { continue }
        if (-not (Test-Path $k)) { continue }
        $vysledky += Get-ChildItem -Path $k -Filter $Maska -File -Recurse -Depth $Hloubka -ErrorAction SilentlyContinue
    }
    return $vysledky
}

# ---------------------------------------------------------------------------
# 1. whisper.cpp
# ---------------------------------------------------------------------------

$whisperExe = Get-ChildItem -Path $BinDir -Recurse -Filter "whisper-cli.exe" -ErrorAction SilentlyContinue |
    Select-Object -First 1 -ExpandProperty FullName

if ($whisperExe) {
    Write-Output "[setup] whisper.cpp uz je v brainu, preskakuji."
} elseif ($Stahni) {
    Write-Output "[setup] BEYOND_WHISPER_STAHNI=1, hledani preskakuji."
} else {
    $kandidati = @()

    foreach ($jmeno in @("whisper-cli", "whisper-cpp", "whisper")) {
        $cmd = Get-Command $jmeno -ErrorAction SilentlyContinue
        if ($cmd) { $kandidati += $cmd.Source }
    }

    $koreny = @(
        $env:LOCALAPPDATA,
        $env:APPDATA,
        $env:ProgramFiles,
        ${env:ProgramFiles(x86)}
    )
    foreach ($maska in @("whisper-cli.exe", "whisper-cpp.exe", "main.exe")) {
        $kandidati += (Hledej-Soubory -Koreny $koreny -Maska $maska -Hloubka 4 |
            Select-Object -ExpandProperty FullName)
    }

    $nalezeno = $null
    foreach ($k in ($kandidati | Select-Object -Unique)) {
        if (Funguje-Whisper $k) { $nalezeno = $k; break }
    }

    if ($nalezeno) {
        Write-Output "[setup] Whisper uz v pocitaci je, beru ho odsud:"
        Write-Output "        $nalezeno"
        Set-Content -Path $CestaSoubor -Value $nalezeno -Encoding UTF8
        $prevzato += "whisper-cli -> $nalezeno"
    } else {
        $zip = Join-Path $env:TEMP "whisper-bin-x64.zip"
        $whisperUrl = "https://github.com/ggml-org/whisper.cpp/releases/latest/download/whisper-bin-x64.zip"
        if (Stahni-Soubor $whisperUrl $zip "whisper.cpp") {
            try {
                Expand-Archive -Path $zip -DestinationPath (Join-Path $BinDir "whisper") -Force
                Remove-Item $zip -Force -ErrorAction SilentlyContinue
            } catch {
                $chyby += "whisper.cpp - rozbaleni selhalo, zkus rucne z https://github.com/ggml-org/whisper.cpp/releases"
            }
        } else {
            $chyby += "whisper.cpp - stahni rucne z https://github.com/ggml-org/whisper.cpp/releases (asset whisper-bin-x64.zip) a rozbal do $BinDir\whisper"
        }
    }
}

# ---------------------------------------------------------------------------
# 2. Model
# ---------------------------------------------------------------------------

$modelVBrainu = Get-ChildItem -Path $ModelDir -Filter "ggml-*.bin" -File -ErrorAction SilentlyContinue |
    Where-Object { (Skore-Modelu $_.Name) -gt 0 } |
    Select-Object -First 1

if ($modelVBrainu) {
    Write-Output "[setup] Model uz je v brainu, preskakuji."
} elseif ($Stahni) {
    Write-Output "[setup] BEYOND_WHISPER_STAHNI=1, hledani modelu preskakuji."
} else {
    $koreny = @(
        $env:LOCALAPPDATA,
        $env:APPDATA,
        (Join-Path $env:USERPROFILE ".cache"),
        (Join-Path $env:USERPROFILE "whisper.cpp")
    )
    $nejlepsi = Hledej-Soubory -Koreny $koreny -Maska "ggml-*.bin" -Hloubka 4 |
        Where-Object { $_.Length -gt 41943040 } |
        Sort-Object -Property @{ Expression = { Skore-Modelu $_.Name } } -Descending |
        Select-Object -First 1

    if ($nejlepsi -and (Skore-Modelu $nejlepsi.Name) -gt 0) {
        $cil = Join-Path $ModelDir $nejlepsi.Name
        $velikost = "{0:N1} GB" -f ($nejlepsi.Length / 1GB)
        Write-Output "[setup] Model uz v pocitaci je, beru ho odsud:"
        Write-Output "        $($nejlepsi.FullName) ($velikost)"
        # Tvrdy odkaz nezabere misto navic. Kdyz je model na jinem disku, kopirujeme.
        $hotovo = $false
        try {
            New-Item -ItemType HardLink -Path $cil -Target $nejlepsi.FullName -ErrorAction Stop | Out-Null
            $hotovo = $true
        } catch {
            try {
                Copy-Item -Path $nejlepsi.FullName -Destination $cil -ErrorAction Stop
                Write-Output "        (tvrdy odkaz neprosel, model se zkopiroval)"
                $hotovo = $true
            } catch {
                $chyby += "model - nasel jsem $($nejlepsi.FullName), ale nepovedlo se ho dostat do $ModelDir"
            }
        }
        if ($hotovo) {
            $prevzato += "$($nejlepsi.Name) -> $($nejlepsi.FullName)"
            if ((Skore-Modelu $nejlepsi.Name) -lt 60) {
                Write-Output "[setup] Pozor: je to mensi model nez large. Prepisy pojedou, ale budou"
                Write-Output "        o neco horsi. Vetsi si vynutis pres BEYOND_WHISPER_STAHNI=1."
            }
        }
    } else {
        $modelUrl = "https://huggingface.co/ggerganov/whisper.cpp/resolve/main/ggml-large-v3-turbo.bin?download=true"
        if (-not (Stahni-Soubor $modelUrl $Model "model large-v3-turbo (~1,6 GB)")) {
            $chyby += "model - stahni rucne z https://huggingface.co/ggerganov/whisper.cpp a uloz jako $Model"
        }
    }
}

# ---------------------------------------------------------------------------
# 3. ffmpeg
# ---------------------------------------------------------------------------

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

# ---------------------------------------------------------------------------
# 4. yt-dlp (volitelne, na odkazy)
# ---------------------------------------------------------------------------

$ytdlp = Join-Path $BinDir "yt-dlp.exe"
if (-not (Test-Path $ytdlp) -and -not (Get-Command yt-dlp -ErrorAction SilentlyContinue)) {
    Stahni-Soubor "https://github.com/yt-dlp/yt-dlp/releases/latest/download/yt-dlp.exe" $ytdlp "yt-dlp (volitelne)" | Out-Null
}

# ---------------------------------------------------------------------------
# Zaver
# ---------------------------------------------------------------------------

if ($prevzato.Count -gt 0) {
    $hlavicka = @(
        "# Odkud brain bere whisper",
        "#",
        "# Zapsal setup-whisper.ps1 $(Get-Date -Format 'dd.MM.yyyy'). Brain si nic velkeho",
        "# nestahoval, ukazuje na uz nainstalovane veci jinde v pocitaci. Kdyz tu",
        "# aplikaci odinstalujes, prepisy prestanou fungovat a staci pustit znovu:",
        "#   powershell -ExecutionPolicy Bypass -File .beyond\setup-whisper.ps1",
        "# Vlastni kopii si vynutis pres `$env:BEYOND_WHISPER_STAHNI=1.",
        ""
    )
    Set-Content -Path $ZdrojSoubor -Value ($hlavicka + $prevzato) -Encoding UTF8
}

Write-Output ""
if ($chyby.Count -eq 0) {
    if ($prevzato.Count -gt 0) {
        Write-Output "[setup] Hotovo. Prepisy jedou lokalne a zadarmo, nic velkeho se nestahovalo."
        Write-Output "        Prehled prevzatych veci je v .beyond\whisper-zdroj.txt."
    } else {
        Write-Output "[setup] Hotovo. Prepisy jedou lokalne a zadarmo."
    }
} else {
    Write-Output "[setup] Cast se nepovedla. Bez toho prepisy nepojedou, ale zbytek brainu ano:"
    foreach ($c in $chyby) { Write-Output "  - $c" }
}
