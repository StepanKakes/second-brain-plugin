# automatika-install.ps1 - zaregistruje vybrane ulohy do Task Scheduleru (Windows).
#
# Nic neni pevne dane. Co si uzivatel vybere, to se naplanuje, a to na cas,
# ktery si rekne. Neuvedena uloha se nenainstaluje, a kdyz uz z drivejska
# existuje, zrusi se. Skript je tim padem i zpusob, jak volbu zmenit.
#
# Pouziti (z korene brainu):
#   powershell -ExecutionPolicy Bypass -File automatika-install.ps1 -Cally "7:12" -Destilace "21:12"
#   powershell -ExecutionPolicy Bypass -File automatika-install.ps1 -Cally "6:47" -Tyden "ne,18:12"
#   powershell -ExecutionPolicy Bypass -File automatika-install.ps1 -Nic
#
# -Cally HH:MM      denne stahne nove cally z Fathomu (cisty skript, zadna cena)
# -Destilace HH:MM  denne zpracuje _inbox/ a zdestiluje _raw/ (pres model, stoji tokeny)
# -Tyden DEN,HH:MM  tydenni prehled (pres model; DEN = po ut st ct pa so ne)
# -Nic              zrusi vsechno, nic nenaplanuje
#
# Vypnuti: automatika-remove.ps1

param(
    [string]$BrainRoot = (Get-Location).Path,
    [string]$Cally,
    [string]$Destilace,
    [string]$Tyden,
    [switch]$Nic
)

$ErrorActionPreference = "Stop"

$ScriptDir = $PSScriptRoot
$Pull = Join-Path $ScriptDir "fathom-pull.ps1"
$LogDir = Join-Path $BrainRoot ".beyond"
$Log = Join-Path $LogDir "automatika.log"
if (-not (Test-Path $LogDir)) { New-Item -ItemType Directory -Path $LogDir -Force | Out-Null }

$JmenoCally = "Beyond Brain - cally"
$JmenoDestilace = "Beyond Brain - destilace"
$JmenoTyden = "Beyond Brain - tyden"

function Zrus-Ulohu {
    param([string]$Jmeno, [switch]$Ticho)
    try {
        Unregister-ScheduledTask -TaskName $Jmeno -Confirm:$false -ErrorAction Stop
        if (-not $Ticho) { Write-Output "[automatika] Zruseno: $Jmeno" }
        return $true
    } catch {
        return $false
    }
}

function Rozloz-Cas {
    param([string]$Cas, [string]$Popis)
    if ($Cas -notmatch '^\d{1,2}:\d{2}$') {
        Write-Output "[automatika] $Popis : '$Cas' neni cas ve tvaru HH:MM."
        exit 1
    }
    $casti = $Cas.Split(":")
    $h = [int]$casti[0]; $m = [int]$casti[1]
    if ($h -gt 23 -or $m -gt 59) {
        Write-Output "[automatika] $Popis : '$Cas' je mimo rozsah."
        exit 1
    }
    return (Get-Date -Hour $h -Minute $m -Second 0)
}

function Den-Na-Anglicky {
    param([string]$Zkratka)
    switch ($Zkratka.ToLower()) {
        "po" { return "Monday" }
        "ut" { return "Tuesday" }
        "st" { return "Wednesday" }
        "ct" { return "Thursday" }
        "pa" { return "Friday" }
        "so" { return "Saturday" }
        "ne" { return "Sunday" }
        default { return $null }
    }
}

# Stare ulohy z verze, ktera mela casy natvrdo. Uklidime je vzdycky,
# jinak by uzivateli bezely dve automatiky vedle sebe.
foreach ($stary in @("Beyond Brain - rano", "Beyond Brain - vecer")) {
    if (Zrus-Ulohu -Jmeno $stary -Ticho) { Write-Output "[automatika] Uklizena stara uloha: $stary" }
}

if ($Nic) {
    foreach ($j in @($JmenoCally, $JmenoDestilace, $JmenoTyden)) { Zrus-Ulohu -Jmeno $j | Out-Null }
    Write-Output ""
    Write-Output "Nic naplanovaneho neni. SessionStart hook bezi dal, ten se nevypina."
    exit 0
}

$nastaveni = New-ScheduledTaskSettingsSet -StartWhenAvailable -DontStopOnIdleEnd -ExecutionTimeLimit (New-TimeSpan -Minutes 30)
$claude = Get-Command claude -ErrorAction SilentlyContinue
$naplanovano = @()

# --- Cally z Fathomu ---
if ($Cally) {
    if (-not (Test-Path $Pull)) {
        Write-Output "[automatika] Nenasel jsem fathom-pull.ps1 vedle sebe, stahovani callu nezaregistruju."
    } else {
        $kdy = Rozloz-Cas $Cally "-Cally"
        $akce = New-ScheduledTaskAction -Execute "powershell.exe" `
            -Argument "-NoProfile -ExecutionPolicy Bypass -File `"$Pull`" -BrainRoot `"$BrainRoot`"" `
            -WorkingDirectory $BrainRoot
        Register-ScheduledTask -TaskName $JmenoCally -Action $akce `
            -Trigger (New-ScheduledTaskTrigger -Daily -At $kdy) -Settings $nastaveni `
            -Description "Stahne nove cally z Fathomu do brainu." -Force | Out-Null
        Write-Output "[automatika] $Cally denne - stahovani callu z Fathomu."
        $naplanovano += "$Cally denne: cally z Fathomu (zadarmo)"
    }
} else {
    Zrus-Ulohu -Jmeno $JmenoCally | Out-Null
}

# --- Destilace ---
if ($Destilace) {
    if (-not $claude) {
        Write-Output "[automatika] 'claude' neni v PATH, destilaci nezaregistruju."
        Write-Output "             Spoustej ji rucne pres /beyond:destilace."
    } else {
        $kdy = Rozloz-Cas $Destilace "-Destilace"
        $prompt = "Jsi v Beyond brainu. Zpracuj _inbox/ pres skill sync a pak zdestiluj nove soubory z _raw/ pres skill destilace. Na konec zapis kratke shrnuti do .beyond/posledni-beh.md. Nic neposilej ven, nic nepublikuj."
        $akce = New-ScheduledTaskAction -Execute $claude.Source -Argument "-p `"$prompt`"" -WorkingDirectory $BrainRoot
        Register-ScheduledTask -TaskName $JmenoDestilace -Action $akce `
            -Trigger (New-ScheduledTaskTrigger -Daily -At $kdy) -Settings $nastaveni `
            -Description "Zpracuje inbox a zdestiluje nove prepisy." -Force | Out-Null
        Write-Output "[automatika] $Destilace denne - zpracovani inboxu a destilace."
        $naplanovano += "$Destilace denne: inbox a destilace (stoji tokeny)"
    }
} else {
    Zrus-Ulohu -Jmeno $JmenoDestilace | Out-Null
}

# --- Tydenni prehled ---
if ($Tyden) {
    $casti = $Tyden.Split(",")
    if ($casti.Count -ne 2) {
        Write-Output "[automatika] -Tyden ceka tvar DEN,HH:MM, treba ne,18:12."
        exit 1
    }
    $den = Den-Na-Anglicky $casti[0].Trim()
    if (-not $den) {
        Write-Output "[automatika] -Tyden : '$($casti[0])' neni den. Pouzij po ut st ct pa so ne."
        exit 1
    }
    if (-not $claude) {
        Write-Output "[automatika] 'claude' neni v PATH, tydenni prehled nezaregistruju."
    } else {
        $kdy = Rozloz-Cas $casti[1].Trim() "-Tyden"
        $promptTyden = "Jsi v Beyond brainu. Udelej tydenni prehled pres skill tyden a zapis ho do workspace nebo tam, kam ho skill uklada. Nic neposilej ven, nic nepublikuj."
        $akce = New-ScheduledTaskAction -Execute $claude.Source -Argument "-p `"$promptTyden`"" -WorkingDirectory $BrainRoot
        Register-ScheduledTask -TaskName $JmenoTyden -Action $akce `
            -Trigger (New-ScheduledTaskTrigger -Weekly -DaysOfWeek $den -At $kdy) -Settings $nastaveni `
            -Description "Tydenni prehled brainu." -Force | Out-Null
        Write-Output "[automatika] $($casti[0]) $($casti[1]) - tydenni prehled."
        $naplanovano += "$($casti[0]) $($casti[1]): tydenni prehled (stoji tokeny)"
    }
} else {
    Zrus-Ulohu -Jmeno $JmenoTyden | Out-Null
}

Write-Output ""
if ($naplanovano.Count -eq 0) {
    Write-Output "Nic se nenaplanovalo."
} else {
    Write-Output "Naplanovano:"
    foreach ($n in $naplanovano) { Write-Output "  - $n" }
}
Write-Output ""
Write-Output "Uloha bezi pod tvym uctem, jen kdyz jsi prihlaseny. Zmeskany beh"
Write-Output "Windows dozene, jakmile se pocitac probudi (StartWhenAvailable)."
Write-Output "Ulohy, ktere jedou pres model, stoji tokeny na tvem uctu."
Write-Output "Zmena: pust tenhle skript znovu s jinymi volbami."
Write-Output "Vypnuti: powershell -File `"$(Join-Path $ScriptDir 'automatika-remove.ps1')`""
Write-Output "Log: $Log"
