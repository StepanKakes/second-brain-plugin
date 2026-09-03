#!/usr/bin/env bash
# automatika-install.sh — zaregistruje vybrane ulohy do launchd (macOS).
#
# Nic neni pevne dane. Co si uzivatel vybere, to se naplanuje, a to na cas,
# ktery si rekne. Neuvedena uloha se nenainstaluje, a kdyz uz z drivejska
# existuje, zrusi se. Skript je tim padem i zpusob, jak volbu zmenit.
#
# Pouziti (z korene brainu):
#   bash automatika-install.sh [cesta-k-brainu] [volby]
#
# Volby:
#   --cally HH:MM         denne stahne nove cally z Fathomu
#                         (cisty skript, zadny model, zadna cena)
#   --destilace HH:MM     denne zpracuje _inbox/ a zdestiluje _raw/
#                         (jede pres `claude -p`, stoji tokeny)
#   --tyden DEN,HH:MM     tydenni prehled pres /beyond:tyden
#                         (taky pres model; DEN = po ut st ct pa so ne)
#   --nic                 zrusi vsechno, nic nenaplanuje
#
# Priklad:
#   bash automatika-install.sh ~/muj-brain --cally 7:12 --destilace 21:12
#   bash automatika-install.sh ~/muj-brain --cally 6:47 --tyden ne,18:12
#
# Vypnuti: automatika-remove.sh

set -euo pipefail

BRAIN=""
CAS_CALLY=""
CAS_DESTILACE=""
TYDEN=""
NIC=0

while [ $# -gt 0 ]; do
  case "$1" in
    --cally)     CAS_CALLY="${2:-}"; shift 2 ;;
    --destilace) CAS_DESTILACE="${2:-}"; shift 2 ;;
    --tyden)     TYDEN="${2:-}"; shift 2 ;;
    --nic)       NIC=1; shift ;;
    -*)          echo "[automatika] Neznama volba: $1"; exit 1 ;;
    *)           [ -z "$BRAIN" ] && BRAIN="$1"; shift ;;
  esac
done

BRAIN="${BRAIN:-$PWD}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
AGENTS="$HOME/Library/LaunchAgents"
LOGDIR="$BRAIN/.beyond"
LOG="$LOGDIR/automatika.log"

mkdir -p "$AGENTS" "$LOGDIR"

# Rozlozi "7:12" na hodinu a minutu a overi, ze to jsou realne hodiny.
HODINA=""; MINUTA=""
rozloz_cas() {
  local cas="$1" popis="$2"
  if ! printf '%s' "$cas" | grep -qE '^[0-9]{1,2}:[0-9]{2}$'; then
    echo "[automatika] $popis: '$cas' neni cas ve tvaru HH:MM."; exit 1
  fi
  HODINA="$(printf '%s' "$cas" | cut -d: -f1 | sed 's/^0//')"
  MINUTA="$(printf '%s' "$cas" | cut -d: -f2 | sed 's/^0//')"
  HODINA="${HODINA:-0}"; MINUTA="${MINUTA:-0}"
  if [ "$HODINA" -gt 23 ] || [ "$MINUTA" -gt 59 ]; then
    echo "[automatika] $popis: '$cas' je mimo rozsah."; exit 1
  fi
}

# launchd bere nedeli jako 0, pondeli jako 1.
cislo_dne() {
  case "$1" in
    po|Po|PO) echo 1 ;; ut|Ut|UT) echo 2 ;; st|St|ST) echo 3 ;;
    ct|Ct|CT) echo 4 ;; pa|Pa|PA) echo 5 ;; so|So|SO) echo 6 ;;
    ne|Ne|NE) echo 0 ;;
    *) echo "" ;;
  esac
}

zrus() {
  local label="$1"
  if [ -f "$AGENTS/$label.plist" ]; then
    launchctl unload "$AGENTS/$label.plist" >/dev/null 2>&1 || true
    rm -f "$AGENTS/$label.plist"
    return 0
  fi
  return 1
}

napis_plist() {
  local label="$1" hodina="$2" minuta="$3" den="$4" prikaz="$5"
  local kalendar="    <key>Hour</key><integer>$hodina</integer>
    <key>Minute</key><integer>$minuta</integer>"
  if [ -n "$den" ]; then
    kalendar="$kalendar
    <key>Weekday</key><integer>$den</integer>"
  fi

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
$kalendar
  </dict>
  <key>StandardOutPath</key><string>$LOG</string>
  <key>StandardErrorPath</key><string>$LOG</string>
</dict>
</plist>
PLIST
  launchctl unload "$AGENTS/$label.plist" >/dev/null 2>&1 || true
  launchctl load "$AGENTS/$label.plist"
}

# Stare labely z verze, ktera mela casy natvrdo. Uklidime je vzdycky,
# jinak by uzivateli bezely dve automatiky vedle sebe.
for stary in cz.growbeyond.brain.rano cz.growbeyond.brain.vecer; do
  zrus "$stary" && echo "[automatika] Uklizena stara uloha: $stary"
done

if [ "$NIC" = "1" ]; then
  for label in cz.growbeyond.brain.cally cz.growbeyond.brain.destilace cz.growbeyond.brain.tyden; do
    zrus "$label" && echo "[automatika] Zruseno: $label"
  done
  echo
  echo "Nic naplanovaneho neni. SessionStart hook bezi dal, ten se nevypina."
  exit 0
fi

MA_CLAUDE=0
command -v claude >/dev/null 2>&1 && MA_CLAUDE=1

NAPLANOVANO=()

# --- Cally z Fathomu ---
if [ -n "$CAS_CALLY" ]; then
  rozloz_cas "$CAS_CALLY" "--cally"
  napis_plist "cz.growbeyond.brain.cally" "$HODINA" "$MINUTA" "" \
    "bash '$SCRIPT_DIR/fathom-pull.sh' '$BRAIN'"
  echo "[automatika] $CAS_CALLY denne — stahovani callu z Fathomu."
  NAPLANOVANO+=("$CAS_CALLY denne: cally z Fathomu (zadarmo)")
else
  zrus "cz.growbeyond.brain.cally" && echo "[automatika] Zruseno: stahovani callu."
fi

# --- Destilace ---
if [ -n "$CAS_DESTILACE" ]; then
  if [ "$MA_CLAUDE" = "0" ]; then
    echo "[automatika] 'claude' neni v PATH, destilaci nezaregistruju."
    echo "             Spoustej ji rucne pres /beyond:destilace."
  else
    rozloz_cas "$CAS_DESTILACE" "--destilace"
    PROMPT="Jsi v Beyond brainu. Zpracuj _inbox/ pres skill sync a pak zdestiluj nove soubory z _raw/ pres skill destilace. Na konec zapis kratke shrnuti do .beyond/posledni-beh.md. Nic neposilej ven, nic nepublikuj."
    napis_plist "cz.growbeyond.brain.destilace" "$HODINA" "$MINUTA" "" \
      "cd '$BRAIN' && claude -p \"$PROMPT\""
    echo "[automatika] $CAS_DESTILACE denne — zpracovani inboxu a destilace."
    NAPLANOVANO+=("$CAS_DESTILACE denne: inbox a destilace (stoji tokeny)")
  fi
else
  zrus "cz.growbeyond.brain.destilace" && echo "[automatika] Zruseno: destilace."
fi

# --- Tydenni prehled ---
if [ -n "$TYDEN" ]; then
  DEN_ZKRATKA="$(printf '%s' "$TYDEN" | cut -d, -f1)"
  CAS_TYDEN="$(printf '%s' "$TYDEN" | cut -d, -f2)"
  DEN_CISLO="$(cislo_dne "$DEN_ZKRATKA")"
  if [ -z "$DEN_CISLO" ]; then
    echo "[automatika] --tyden: '$DEN_ZKRATKA' neni den. Pouzij po ut st ct pa so ne."; exit 1
  fi
  if [ "$MA_CLAUDE" = "0" ]; then
    echo "[automatika] 'claude' neni v PATH, tydenni prehled nezaregistruju."
  else
    rozloz_cas "$CAS_TYDEN" "--tyden"
    PROMPT_TYDEN="Jsi v Beyond brainu. Udelej tydenni prehled pres skill tyden a zapis ho do workspace nebo tam, kam ho skill uklada. Nic neposilej ven, nic nepublikuj."
    napis_plist "cz.growbeyond.brain.tyden" "$HODINA" "$MINUTA" "$DEN_CISLO" \
      "cd '$BRAIN' && claude -p \"$PROMPT_TYDEN\""
    echo "[automatika] $DEN_ZKRATKA $CAS_TYDEN — tydenni prehled."
    NAPLANOVANO+=("$DEN_ZKRATKA $CAS_TYDEN: tydenni prehled (stoji tokeny)")
  fi
else
  zrus "cz.growbeyond.brain.tyden" && echo "[automatika] Zruseno: tydenni prehled."
fi

echo
if [ ${#NAPLANOVANO[@]} -eq 0 ]; then
  echo "Nic se nenaplanovalo."
else
  echo "Naplanovano:"
  for n in "${NAPLANOVANO[@]}"; do echo "  - $n"; done
fi
echo
echo "Bezi to jen kdyz je pocitac zapnuty a jsi prihlaseny. Kdyz zrovna spi,"
echo "macOS uspanou ulohu spusti po probuzeni. Vypnuty pocitac nestihne nic."
echo "Ulohy, ktere jedou pres model, stoji tokeny na tvem uctu."
echo "Zmena: pust tenhle skript znovu s jinymi volbami."
echo "Vypnuti: bash '$SCRIPT_DIR/automatika-remove.sh'"
echo "Log: $LOG"
