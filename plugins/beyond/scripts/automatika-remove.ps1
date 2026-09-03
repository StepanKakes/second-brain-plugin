# automatika-remove.ps1 - zrusi nocni beh (Windows).
# Pouziti: powershell -ExecutionPolicy Bypass -File automatika-remove.ps1

$ErrorActionPreference = "Continue"
foreach ($n in @("Beyond Brain - rano", "Beyond Brain - vecer")) {
    try {
        Unregister-ScheduledTask -TaskName $n -Confirm:$false -ErrorAction Stop
        Write-Output "[automatika] Zruseno: $n"
    } catch {
        Write-Output "[automatika] Neexistuje (nebo uz je zrusene): $n"
    }
}
Write-Output "Hotovo. SessionStart hook bezi dal, ten se nevypina."
