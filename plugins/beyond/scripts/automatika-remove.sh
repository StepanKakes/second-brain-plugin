#!/usr/bin/env bash
# automatika-remove.sh — zrusi nocni beh (macOS).
# Pouziti: bash automatika-remove.sh

AGENTS="$HOME/Library/LaunchAgents"
for label in cz.growbeyond.brain.rano cz.growbeyond.brain.vecer; do
  if [ -f "$AGENTS/$label.plist" ]; then
    launchctl unload "$AGENTS/$label.plist" >/dev/null 2>&1 || true
    rm -f "$AGENTS/$label.plist"
    echo "[automatika] Zruseno: $label"
  else
    echo "[automatika] Neexistuje (nebo uz je zrusene): $label"
  fi
done
echo "Hotovo. SessionStart hook bezi dal, ten se nevypina."
