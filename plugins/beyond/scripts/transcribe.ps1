# transcribe.ps1 - prepis audia, videa nebo odkazu pres lokalni whisper.cpp (Windows).
#
# Pouziti:
#   powershell -ExecutionPolicy Bypass -File transcribe.ps1 "C:\cesta\hlasovka.m4a"
#   ... "https://youtu.be/xxxx"                 # stahne pres yt-dlp
#   ... "https://instagram.com/reel/xxx" -Cookies "C:\cookies.txt"
#   ... -Jazyk en                                # vychozi cs
#
# Vystup: cisty text na stdout. Nic nikam neuklada, o to se stara skill sync.
# Nastroje hleda v .beyond/bin/ v koreni brainu (nainstaluje je setup-whisper.ps1).

param(
    [Parameter(Mandatory = $true, Position = 0)][string]$Zdroj,
    [string]$BrainRoot = (Get-Location).Path,
    [string]$Jazyk = "cs",
    [string]$Cookies
)

$ErrorActionPreference = "Stop"

$BinDir = Join-Path $BrainRoot ".beyond\bin"
$Model = Join-Path $BrainRoot ".beyond\models\ggml-large-v3-turbo.bin"

$Ffmpeg = Get-ChildItem -Path $BinDir -Recurse -Filter "ffmpeg.exe" -ErrorAction SilentlyContinue |
    Select-Object -First 1 -ExpandProperty FullName
if (-not $Ffmpeg) { $Ffmpeg = (Get-Command ffmpeg -ErrorAction SilentlyContinue).Source }

$Whisper = Get-ChildItem -Path $BinDir -Recurse -Filter "whisper-cli.exe" -ErrorAction SilentlyContinue |
    Select-Object -First 1 -ExpandProperty FullName

$YtDlp = Get-ChildItem -Path $BinDir -Recurse -Filter "yt-dlp.exe" -ErrorAction SilentlyContinue |
    Select-Object -First 1 -ExpandProperty FullName

foreach ($pair in @(@("ffmpeg", $Ffmpeg), @("whisper-cli", $Whisper), @("model", $Model))) {
    if (-not $pair[1] -or -not (Test-Path $pair[1])) {
        Write-Output "CHYBI: $($pair[0]). Spust nejdriv setup-whisper.ps1."
        exit 1
    }
}

$Temp = $env:TEMP
$Stazene = $null
$Wav = Join-Path $Temp "beyond-$([Guid]::NewGuid()).wav"
$Vstup = $Zdroj

try {
    if ($Zdroj -match '^https?://') {
        if (-not $YtDlp) {
            Write-Output "CHYBI: yt-dlp. Odkazy bez nej neprepisu. Spust setup-whisper.ps1."
            exit 1
        }
        $Stazene = Join-Path $Temp "beyond-$([Guid]::NewGuid()).%(ext)s"
        $args = @("-f", "bestaudio/best", "-o", $Stazene, "--no-playlist", "--quiet")
        if ($Cookies) { $args += @("--cookies", $Cookies) }
        $args += $Zdroj
        & $YtDlp @args
        if ($LASTEXITCODE -ne 0) {
            Write-Output "CHYBA: stazeni odkazu selhalo. U Instagramu byva duvod chybejici nebo vyprsele cookies."
            exit 1
        }
        $Vstup = Get-ChildItem -Path $Temp -Filter "beyond-*" |
            Sort-Object LastWriteTime -Descending | Select-Object -First 1 -ExpandProperty FullName
    }

    if (-not (Test-Path $Vstup)) {
        Write-Output "CHYBA: soubor $Vstup neexistuje."
        exit 1
    }

    & $Ffmpeg -y -loglevel error -i $Vstup -ar 16000 -ac 1 -c:a pcm_s16le $Wav
    if ($LASTEXITCODE -ne 0) {
        Write-Output "CHYBA: ffmpeg nedokazal z tohohle souboru vytahnout zvuk."
        exit 1
    }

    $vystup = & $Whisper -m $Model -l $Jazyk -t 8 -np -nt $Wav 2>$null
    if ($LASTEXITCODE -ne 0) {
        Write-Output "CHYBA: whisper spadl."
        exit 1
    }

    ($vystup | ForEach-Object { $_.Trim() } | Where-Object { $_ }) -join "`n"
}
finally {
    if (Test-Path $Wav) { Remove-Item $Wav -Force -ErrorAction SilentlyContinue }
    if ($Stazene) {
        Get-ChildItem -Path $Temp -Filter "beyond-*" -ErrorAction SilentlyContinue |
            Where-Object { $_.Extension -ne ".wav" } |
            Remove-Item -Force -ErrorAction SilentlyContinue
    }
}
