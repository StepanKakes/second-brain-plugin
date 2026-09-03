# automatika-remove.ps1 - zrusi vsechny naplanovane ulohy brainu (Windows).
# Pouziti: powershell -ExecutionPolicy Bypass -File automatika-remove.ps1
#
# Rusi i stare nazvy z verze, ktera mela casy natvrdo.

$ErrorActionPreference = "Continue"
$neco = $false

foreach ($n in @(
    "Beyond Brain - cally",
    "Beyond Brain - destilace",
    "Beyond Brain - tyden",
    "Beyond Brain - rano",
    "Beyond Brain - vecer"
)) {
    try {
        Unregister-ScheduledTask -TaskName $n -Confirm:$false -ErrorAction Stop
        Write-Output "[automatika] Zruseno: $n"
        $neco = $true
    } catch { }
}

if (-not $neco) { Write-Output "[automatika] Nic naplanovaneho nebylo." }
Write-Output "Hotovo. SessionStart hook bezi dal, ten se nevypina."
