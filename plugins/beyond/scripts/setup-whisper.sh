#!/usr/bin/env bash
# setup-whisper.sh — stahne whisper.cpp, model a pomocne binarky do brainu (macOS, Linux).
#
# Pouziti (z korene brainu):
#   bash setup-whisper.sh [cesta-k-brainu]
#
# Vsechno konci v <brain>/.beyond/bin a <brain>/.beyond/models.
# Jednorazove ~1,7 GB. Skript je bezpecne pustit znovu.

set -uo pipefail

BRAIN="${1:-$PWD}"
BIN="$BRAIN/.beyond/bin"
MODELS="$BRAIN/.beyond/models"
MODEL="$MODELS/ggml-large-v3-turbo.bin"
CHYBY=()

mkdir -p "$BIN" "$MODELS"

# 1. Model (~1,6 GB)
if [ -f "$MODEL" ]; then
  echo "[setup] Model uz je, preskakuji."
else
  echo "[setup] Stahuji model large-v3-turbo (~1,6 GB) ..."
  if ! curl -L --fail --progress-bar \
      "https://huggingface.co/ggerganov/whisper.cpp/resolve/main/ggml-large-v3-turbo.bin?download=true" \
      -o "$MODEL"; then
    rm -f "$MODEL"
    CHYBY+=("model — stahni rucne z https://huggingface.co/ggerganov/whisper.cpp a uloz jako $MODEL")
  fi
fi

# 2. whisper.cpp
if command -v whisper-cli >/dev/null 2>&1 || command -v whisper-cpp >/dev/null 2>&1 || [ -x "$BIN/whisper-cli" ]; then
  echo "[setup] whisper.cpp uz je, preskakuji."
elif command -v brew >/dev/null 2>&1; then
  echo "[setup] Instaluji whisper.cpp pres brew ..."
  brew install whisper-cpp || CHYBY+=("whisper.cpp — brew install whisper-cpp selhalo")
else
  echo "[setup] Brew neni, zkousim postavit ze zdrojaku ..."
  if command -v git >/dev/null 2>&1 && command -v make >/dev/null 2>&1; then
    SRC="$BRAIN/.beyond/src/whisper.cpp"
    mkdir -p "$(dirname "$SRC")"
    if [ ! -d "$SRC" ]; then
      git clone --depth 1 https://github.com/ggml-org/whisper.cpp "$SRC" >/dev/null 2>&1
    fi
    if (cd "$SRC" && make -j >/dev/null 2>&1) && [ -f "$SRC/build/bin/whisper-cli" ]; then
      cp "$SRC/build/bin/whisper-cli" "$BIN/whisper-cli"
      chmod +x "$BIN/whisper-cli"
    else
      CHYBY+=("whisper.cpp — build selhal, nainstaluj brew a spust znovu")
    fi
  else
    CHYBY+=("whisper.cpp — chybi git nebo make, nainstaluj Xcode command line tools")
  fi
fi

# 3. ffmpeg
if command -v ffmpeg >/dev/null 2>&1; then
  echo "[setup] ffmpeg uz je, preskakuji."
elif command -v brew >/dev/null 2>&1; then
  brew install ffmpeg || CHYBY+=("ffmpeg — brew install ffmpeg selhalo")
else
  CHYBY+=("ffmpeg — nainstaluj ho (macOS: brew install ffmpeg, Linux: apt install ffmpeg)")
fi

# 4. yt-dlp (volitelne)
if ! command -v yt-dlp >/dev/null 2>&1; then
  if command -v brew >/dev/null 2>&1; then
    brew install yt-dlp >/dev/null 2>&1 || true
  fi
fi

echo
if [ ${#CHYBY[@]} -eq 0 ]; then
  echo "[setup] Hotovo. Prepisy jedou lokalne a zadarmo."
else
  echo "[setup] Cast se nepovedla. Bez toho prepisy nepojedou, ale zbytek brainu ano:"
  for c in "${CHYBY[@]}"; do echo "  - $c"; done
fi
