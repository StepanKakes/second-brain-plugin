# fathom-pull.ps1 - stahne nove cally z Fathomu do cally/ (Windows, PowerShell 5.1+).
#
# Pouziti (z korene brainu):
#   powershell -ExecutionPolicy Bypass -File <plugin>/scripts/fathom-pull.ps1
#   ... -BrainRoot "C:\cesta\k\brainu"   # kdyz nespoustis z korene
#
# Klic bere z .env v koreni brainu (FATHOM_API_KEY=...).
# Ledger .beyond/fathom-stav.json drzi recording_id uz stazenych callu.
#
# ZELEZNE PRAVIDLO: do ledgeru se zapisuje az po tom, co soubor existuje na disku.
# Opacne poradi znamena, ze pri padu call navzdy zmizi.

param(
    [string]$BrainRoot = (Get-Location).Path,
    # Fathom vraci 10 callu na stranku a parametr limit ignoruje (overeno 02.09.2026).
    # Vic se bere pres kurzor. Pri bezném behu staci jedna stranka, pri prvnim
    # nasati historie dej treba -MaxStran 20.
    [int]$MaxStran = 1
)

$ErrorActionPreference = "Stop"

function Read-DotEnv {
    param([string]$Path)
    $map = @{}
    if (-not (Test-Path $Path)) { return $map }
    foreach ($line in (Get-Content $Path)) {
        $t = $line.Trim()
        if ($t -eq "" -or $t.StartsWith("#")) { continue }
        $i = $t.IndexOf("=")
        if ($i -lt 1) { continue }
        $map[$t.Substring(0, $i).Trim()] = $t.Substring($i + 1).Trim().Trim('"')
    }
    return $map
}

function Get-Slug {
    # Diakritiku strhava .NET normalizaci, ne seznamem znaku.
    # Tenhle soubor musi zustat ciste ASCII: PowerShell 5.1 cte .ps1 v ANSI
    # a na vicebajtovych znacich si rozbije uvozovky.
    param([string]$Text)
    $norm = $Text.ToLower().Normalize([System.Text.NormalizationForm]::FormD)
    $sb = New-Object System.Text.StringBuilder
    foreach ($ch in $norm.ToCharArray()) {
        $kat = [System.Globalization.CharUnicodeInfo]::GetUnicodeCategory($ch)
        if ($kat -ne [System.Globalization.UnicodeCategory]::NonSpacingMark) {
            [void]$sb.Append($ch)
        }
    }
    $s = $sb.ToString() -replace '[^a-z0-9]+', '-'
    return $s.Trim('-')
}

$envPath = Join-Path $BrainRoot ".env"
$conf = Read-DotEnv $envPath
$key = $conf["FATHOM_API_KEY"]

if ([string]::IsNullOrWhiteSpace($key)) {
    Write-Output "[fathom] FATHOM_API_KEY neni v $envPath - preskakuji. Neni to chyba."
    exit 0
}

$callyDir = Join-Path $BrainRoot "cally"
$stateDir = Join-Path $BrainRoot ".beyond"
$statePath = Join-Path $stateDir "fathom-stav.json"

foreach ($d in @($callyDir, $stateDir)) {
    if (-not (Test-Path $d)) { New-Item -ItemType Directory -Path $d -Force | Out-Null }
}

$known = @{}
if (Test-Path $statePath) {
    try {
        $raw = Get-Content $statePath -Raw -Encoding UTF8 | ConvertFrom-Json
        foreach ($id in $raw.hotovo) { $known[[string]$id] = $true }
    } catch {
        Write-Output "[fathom] Ledger $statePath je poskozeny. Koncim, at neprepisu historii."
        Write-Output "         Oprav ho nebo smaz rucne, pak spust znovu."
        exit 1
    }
}

$zaklad = "https://api.fathom.ai/external/v1/meetings?include_transcript=true&include_summary=true&include_action_items=true"
$items = @()
$kurzor = $null
$strana = 0

do {
    $url = $zaklad
    if ($kurzor) { $url += "&cursor=" + [uri]::EscapeDataString($kurzor) }

    try {
        $resp = Invoke-RestMethod -Uri $url -Method Get -Headers @{ "X-Api-Key" = $key } -TimeoutSec 180
    } catch {
        Write-Output "[fathom] Volani API selhalo: $($_.Exception.Message)"
        if ($items.Count -eq 0) { exit 1 }
        break   # co uz mame, to zpracujeme
    }

    $items += @($resp.items)
    $kurzor = $resp.next_cursor
    $strana++
} while ($kurzor -and $strana -lt $MaxStran)

if ($items.Count -eq 0) {
    Write-Output "[fathom] API nevratilo zadne cally."
    exit 0
}

$novych = 0

foreach ($m in $items) {
    $id = [string]$m.recording_id
    if ($id -eq "" -or $known.ContainsKey($id)) { continue }

    # Pole se jmenuje recording_start_time, ne recording_start (overeno proti API 02.09.2026).
    # Kdyz se to splete, vsechny cally dostanou dnesni datum a v brainu je zmatek.
    $start = $m.recording_start_time
    if (-not $start) { $start = $m.scheduled_start_time }
    if ($start) {
        try { $dt = [datetime]::Parse($start) } catch { $dt = Get-Date }
    } else {
        $dt = Get-Date
    }
    $datum = $dt.ToString("yyyy-MM-dd")

    $title = if ([string]::IsNullOrWhiteSpace($m.title)) { "call" } else { $m.title }
    $slug = Get-Slug $title
    if ($slug -eq "") { $slug = "call" }

    $file = Join-Path $callyDir "$datum-$slug.md"
    if (Test-Path $file) { $file = Join-Path $callyDir "$datum-$slug-$id.md" }

    $lines = New-Object System.Collections.Generic.List[string]
    $lines.Add("---")
    $lines.Add("zdroj: fathom")
    $lines.Add("datum: $datum")
    $lines.Add("nazev: $title")
    $lines.Add("odkaz: $($m.share_url)")
    $lines.Add("recording_id: $id")
    $lines.Add("---")
    $lines.Add("")
    $lines.Add("# $title")
    $lines.Add("")

    $ucastnici = @()
    foreach ($inv in @($m.calendar_invitees)) {
        $jmeno = if ($inv.name) { $inv.name } else { $inv.email }
        if ($jmeno) { $ucastnici += $jmeno }
    }
    if ($ucastnici.Count -gt 0) {
        $lines.Add("**Ucastnici:** " + ($ucastnici -join ", "))
        $lines.Add("")
    }

    if ($m.default_summary -and $m.default_summary.markdown_formatted) {
        $lines.Add("## Shrnuti od Fathomu")
        $lines.Add("")
        $lines.Add([string]$m.default_summary.markdown_formatted)
        $lines.Add("")
    }

    $ai = @($m.action_items)
    if ($ai.Count -gt 0) {
        $lines.Add("## Ukoly")
        $lines.Add("")
        foreach ($a in $ai) {
            $kdo = if ($a.assignee -and $a.assignee.name) { " (" + $a.assignee.name + ")" } else { "" }
            $lines.Add("- [ ] " + $a.description + $kdo)
        }
        $lines.Add("")
    }

    $tr = @($m.transcript)
    if ($tr.Count -gt 0) {
        $lines.Add("## Prepis")
        $lines.Add("")
        foreach ($seg in $tr) {
            $kdo = if ($seg.speaker -and $seg.speaker.display_name) { $seg.speaker.display_name } else { "?" }
            $txt = [string]$seg.text
            if ($txt.Trim() -ne "") { $lines.Add("**${kdo}:** $txt") }
        }
        $lines.Add("")
    } else {
        $lines.Add("> Prepis Fathom nevratil. Nezakladam prazdny zaznam navic - az bude, doplni se pri dalsim behu.")
        $lines.Add("")
    }

    [System.IO.File]::WriteAllLines($file, $lines, (New-Object System.Text.UTF8Encoding($false)))

    # Ledger az potom, a jen kdyz soubor opravdu je.
    if (Test-Path $file) {
        $known[$id] = $true
        $novych++
        Write-Output "[fathom] + $([System.IO.Path]::GetFileName($file))"
    } else {
        Write-Output "[fathom] ! zapis selhal, $id zkusim priste"
    }
}

$out = [ordered]@{
    aktualizovano = (Get-Date).ToString("s")
    hotovo        = @($known.Keys)
}
$out | ConvertTo-Json -Depth 5 | Set-Content -Path $statePath -Encoding UTF8

if ($novych -eq 0) {
    Write-Output "[fathom] Nic noveho."
} else {
    Write-Output "[fathom] Hotovo, novych callu: $novych"
}
