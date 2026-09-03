# automatika-install.ps1 - zaregistruje nocni beh do Task Scheduleru (Windows).
#
# Pouziti (z korene brainu):
#   powershell -ExecutionPolicy Bypass -File automatika-install.ps1
#
# Rano 7:12  - stazeni callu z Fathomu (cisty skript, zadny model, zadna cena).
# Vecer 21:12 - zpracovani inboxu a destilace pres `claude -p` (stoji tokeny).
#
# Vypnuti: automatika-remove.ps1

param(
    [string]$BrainRoot = (Get-Location).Path
)

$ErrorActionPreference = "Stop"

$ScriptDir = $PSScriptRoot
$Pull = Join-Path $ScriptDir "fathom-pull.ps1"
$LogDir = Join-Path $BrainRoot ".beyond"
if (-not (Test-Path $LogDir)) { New-Item -ItemType Directory -Path $LogDir -Force | Out-Null }

if (-not (Test-Path $Pull)) {
    Write-Output "[automatika] Nenasel jsem fathom-pull.ps1 vedle sebe. Koncim."
    exit 1
}

# --- Rano: stazeni callu ---
$akceRano = New-ScheduledTaskAction `
    -Execute "powershell.exe" `
    -Argument "-NoProfile -ExecutionPolicy Bypass -File `"$Pull`" -BrainRoot `"$BrainRoot`"" `
    -WorkingDirectory $BrainRoot

$spoustecRano = New-ScheduledTaskTrigger -Daily -At 7:12am
$nastaveni = New-ScheduledTaskSettingsSet -StartWhenAvailable -DontStopOnIdleEnd -ExecutionTimeLimit (New-TimeSpan -Minutes 30)

Register-ScheduledTask -TaskName "Beyond Brain - rano" -Action $akceRano -Trigger $spoustecRano `
    -Settings $nastaveni -Description "Stahne nove cally z Fathomu do brainu." -Force | Out-Null
Write-Output "[automatika] Rano 7:12 - stahovani callu zaregistrovano."

# --- Vecer: destilace ---
$claude = Get-Command claude -ErrorAction SilentlyContinue
if (-not $claude) {
    Write-Output "[automatika] `claude` neni v PATH, takze vecerni destilaci nezaregistruju."
    Write-Output "             Rano stahovani bezi. Destilaci spoustej rucne pres /beyond:destilace."
    exit 0
}

$prompt = "Jsi v Beyond brainu. Zpracuj _inbox/ pres skill sync a pak zdestiluj nove soubory z _raw/ pres skill destilace. Na konec zapis kratke shrnuti do .beyond/posledni-beh.md. Nic neposilej ven, nic nepublikuj."
$log = Join-Path $LogDir "automatika.log"

$akceVecer = New-ScheduledTaskAction `
    -Execute $claude.Source `
    -Argument "-p `"$prompt`"" `
    -WorkingDirectory $BrainRoot

$spoustecVecer = New-ScheduledTaskTrigger -Daily -At 9:12pm

Register-ScheduledTask -TaskName "Beyond Brain - vecer" -Action $akceVecer -Trigger $spoustecVecer `
    -Settings $nastaveni -Description "Zpracuje inbox a zdestiluje nove prepisy." -Force | Out-Null

Write-Output "[automatika] Vecer 21:12 - destilace zaregistrovana."
Write-Output ""
Write-Output "Bezi to jen kdyz je pocitac zapnuty a jsi prihlaseny."
Write-Output "Vecerni destilace jede pres model, takze stoji tokeny na tvem uctu."
Write-Output "Vypnout: powershell -File `"$(Join-Path $ScriptDir 'automatika-remove.ps1')`""
Write-Output "Log: $log"
