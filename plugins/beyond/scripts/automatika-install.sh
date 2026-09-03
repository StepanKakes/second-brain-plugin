#!/usr/bin/env bash
# automatika-install.sh — zaregistruje nocni beh do launchd (macOS).
#
# Pouziti (z korene brainu):
#   bash automatika-install.sh [cesta-k-brainu]
#
# Rano 7:12  — stazeni callu z Fathomu (cisty skript, zadny model, zadna cena).
# Vecer 21:12 — zpracovani inboxu a destilace pres `claude -p` (stoji tokeny).
#
# Vypnuti: automatika-remove.sh

set -euo pipefail

BRAIN="${1:-$PWD}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
AGENTS="$HOME/Library/LaunchAgents"
LOGDIR="$BRAIN/.beyond"

mkdir -p "$AGENTS" "$LOGDIR"

napis_plist() {
  local label="$1" hodina="$2" minuta="$3" prikaz="$4"
  cat > "$AGENTS/$label.plist" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>Label</key><string>$label</string>
  <key>ProgramArguments</key>
  <array>
    <string>/bin/bash</string>
    <string>-lc</string>
    <string>$prikaz</string>
  </array>
  <key>WorkingDirectory</key><string>$BRAIN</string>
  <key>StartCalendarInterval</key>
  <dict>
    <key>Hour</key><integer>$hodina</integer>
    <key>Minute</key><integer>$minuta</integer>
  </dict>
  <key>StandardOutPath</key><string>$LOGDIR/automatika.log</string>
  <key>StandardErrorPath</key><string>$LOGDIR/automatika.log</string>
</dict>
</plist>
PLIST
  launchctl unload "$AGENTS/$label.plist" >/dev/null 2>&1 || true
  launchctl load "$AGENTS/$label.plist"
}

napis_plist "cz.growbeyond.brain.rano" 7 12 "bash '$SCRIPT_DIR/fathom-pull.sh' '$BRAIN'"
echo "[automatika] Rano 7:12 — stahovani callu zaregistrovano."

if command -v claude >/dev/null 2>&1; then
  PROMPT="Jsi v Beyond brainu. Zpracuj _inbox/ pres skill sync a pak zdestiluj nove soubory z _raw/ pres skill destilace. Na konec zapis kratke shrnuti do .beyond/posledni-beh.md. Nic neposilej ven, nic nepublikuj."
  napis_plist "cz.growbeyond.brain.vecer" 21 12 "cd '$BRAIN' && claude -p \"$PROMPT\""
  echo "[automatika] Vecer 21:12 — destilace zaregistrovana."
else
  echo "[automatika] 'claude' neni v PATH, vecerni destilaci nezaregistruju."
  echo "             Rano stahovani bezi. Destilaci spoustej rucne pres /beyond:destilace."
fi

echo
echo "Bezi to jen kdyz je pocitac zapnuty a jsi prihlaseny."
echo "Vecerni destilace jede pres model, takze stoji tokeny na tvem uctu."
echo "Vypnout: bash '$SCRIPT_DIR/automatika-remove.sh'"
echo "Log: $LOGDIR/automatika.log"
