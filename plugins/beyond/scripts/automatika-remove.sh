#!/usr/bin/env bash
# automatika-remove.sh — zrusi vsechny naplanovane ulohy brainu (macOS).
# Pouziti: bash automatika-remove.sh
#
# Rusi i stare labely z verze, ktera mela casy natvrdo.

AGENTS="$HOME/Library/LaunchAgents"
NECO=0

for label in \
  cz.growbeyond.brain.cally \
  cz.growbeyond.brain.destilace \
  cz.growbeyond.brain.tyden \
  cz.growbeyond.brain.rano \
  cz.growbeyond.brain.vecer
do
  if [ -f "$AGENTS/$label.plist" ]; then
    launchctl unload "$AGENTS/$label.plist" >/dev/null 2>&1 || true
    rm -f "$AGENTS/$label.plist"
    echo "[automatika] Zruseno: $label"
    NECO=1
  fi
done

[ "$NECO" = "0" ] && echo "[automatika] Nic naplanovaneho nebylo."
echo "Hotovo. SessionStart hook bezi dal, ten se nevypina."
