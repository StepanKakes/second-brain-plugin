#!/usr/bin/env bash
# setup-whisper.sh — zaridi lokalni prepisy (macOS, Linux).
#
# Nejdriv se podiva, jestli whisper a model uz nekde v pocitaci nejsou.
# Hleda v PATH, v homebrew a uvnitr aplikaci, ktere whisper.cpp balicuji
# (Vowen, MacWhisper, superwhisper, Vibe a spol.). Kdyz neco najde, jen na to
# ukaze odkazem. Stahuje se az to, co se nenajde.
#
# Pouziti (z korene brainu):
#   bash setup-whisper.sh [cesta-k-brainu]
#   BEYOND_WHISPER_STAHNI=1 bash setup-whisper.sh   # nehledej, porid vlastni kopii
#
# Vsechno konci v <brain>/.beyond/bin a <brain>/.beyond/models.
# Skript je bezpecne pustit znovu.

set -uo pipefail
shopt -s nullglob

BRAIN="${1:-$PWD}"
BIN="$BRAIN/.beyond/bin"
MODELS="$BRAIN/.beyond/models"
MODEL="$MODELS/ggml-large-v3-turbo.bin"
ZDROJE="$BRAIN/.beyond/whisper-zdroj.txt"
CHYBY=()
PREVZATO=()

# Kdyz je nastavene BEYOND_WHISPER_STAHNI=1, nehleda se a poridi se vlastni
# kopie. Drive prevzate odkazy je pritom potreba zahodit, jinak by je skript
# vyhodnotil jako hotovo a neudelal nic.
HLEDAT=1
if [ "${BEYOND_WHISPER_STAHNI:-0}" = "1" ]; then
  HLEDAT=0
fi

mkdir -p "$BIN" "$MODELS"

if [ "$HLEDAT" = "0" ]; then
  echo "[setup] BEYOND_WHISPER_STAHNI=1: hledani preskakuji, poridim vlastni kopii."
  for odkaz in "$BIN"/whisper-cli "$BIN"/ffmpeg "$BIN"/yt-dlp "$MODELS"/ggml-*.bin; do
    [ -L "$odkaz" ] && rm -f "$odkaz"
  done
  rm -f "$ZDROJE"
fi

velikost() {
  stat -f%z "$1" 2>/dev/null || stat -c%s "$1" 2>/dev/null || echo 0
}

lidsky() {
  awk -v b="$1" 'BEGIN{ if (b>1073741824) printf "%.1f GB", b/1073741824; else printf "%.0f MB", b/1048576 }'
}

# Vrati prvni kandidat, ktery po spusteni s --help skutecne nabehne.
# Binarka z aplikace byva slinkovana na knihovny vedle sebe, tohle overi,
# ze to funguje i pres odkaz.
prvni_funkcni() {
  local c
  for c in "$@"; do
    [ -x "$c" ] || continue
    if "$c" --help >/dev/null 2>&1; then
      echo "$c"
      return 0
    fi
  done
  return 1
}

# Skore modelu podle nazvu. Cim vetsi model, tim lepsi prepis.
skore_modelu() {
  case "$(basename "$1")" in
    *silero*|*vad*|*encoder*) echo 0 ;;
    *large-v3-turbo*)         echo 90 ;;
    *large-v3*)               echo 80 ;;
    *large-v2*)               echo 70 ;;
    *large*)                  echo 60 ;;
    *medium*)                 echo 50 ;;
    *small*)                  echo 40 ;;
    *base*)                   echo 30 ;;
    *tiny*)                   echo 20 ;;
    *)                        echo 0 ;;
  esac
}

# ---------------------------------------------------------------------------
# 1. whisper.cpp
# ---------------------------------------------------------------------------

if [ -x "$BIN/whisper-cli" ] && "$BIN/whisper-cli" --help >/dev/null 2>&1; then
  echo "[setup] whisper.cpp uz je v brainu, preskakuji."
else
  NALEZENA_BIN=""

  if [ "$HLEDAT" = "1" ]; then
    KANDIDATI_BIN=()
    # v PATH (homebrew, rucni instalace)
    for jmeno in whisper-cli whisper-cpp; do
      cesta="$(command -v "$jmeno" 2>/dev/null || true)"
      [ -n "$cesta" ] && KANDIDATI_BIN+=("$cesta")
    done
    # uvnitr aplikaci, ktere whisper.cpp balicuji
    KANDIDATI_BIN+=(
      /Applications/*.app/Contents/Resources/bin/whisper-cli
      /Applications/*.app/Contents/Resources/whisper-cli
      /Applications/*.app/Contents/MacOS/whisper-cli
      /Applications/*.app/Contents/Resources/bin/whisper-cpp
      "$HOME"/Applications/*.app/Contents/Resources/bin/whisper-cli
      "$HOME"/Applications/*.app/Contents/Resources/whisper-cli
      "$HOME"/Applications/*.app/Contents/MacOS/whisper-cli
    )
    # drivejsi buildy a bezne linuxove cesty
    KANDIDATI_BIN+=(
      "$HOME"/whisper.cpp/build/bin/whisper-cli
      "$HOME"/src/whisper.cpp/build/bin/whisper-cli
      "$HOME"/.local/bin/whisper-cli
      /usr/local/bin/whisper-cli
      /opt/homebrew/bin/whisper-cli
      /usr/bin/whisper-cli
      /opt/*/bin/whisper-cli
    )

    KANDIDAT="$(prvni_funkcni "${KANDIDATI_BIN[@]}" || true)"

    if [ -n "$KANDIDAT" ]; then
      ln -sfn "$KANDIDAT" "$BIN/whisper-cli"
      if "$BIN/whisper-cli" --help >/dev/null 2>&1; then
        echo "[setup] Whisper uz v pocitaci je, beru ho odsud:"
        echo "        $KANDIDAT"
        PREVZATO+=("whisper-cli -> $KANDIDAT")
        NALEZENA_BIN="$KANDIDAT"
      else
        rm -f "$BIN/whisper-cli"
        echo "[setup] Nasel jsem whisper, ale pres odkaz nenabehl. Nainstaluji vlastni."
      fi
    fi
  fi

  if [ -z "$NALEZENA_BIN" ]; then
    if command -v brew >/dev/null 2>&1; then
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
  fi
fi

# ---------------------------------------------------------------------------
# 2. Model
# ---------------------------------------------------------------------------

MODEL_V_BRAINU=""
for m in "$MODELS"/ggml-*.bin; do
  if [ -e "$m" ] && [ "$(skore_modelu "$m")" -gt 0 ]; then
    MODEL_V_BRAINU="$m"
    break
  fi
done

if [ -n "$MODEL_V_BRAINU" ]; then
  echo "[setup] Model uz je v brainu, preskakuji."
else
  NEJLEPSI=""
  NEJSKORE=0

  if [ "$HLEDAT" = "1" ]; then
    KANDIDATI_MODEL=(
      "$HOME"/Library/Application\ Support/*/models/ggml-*.bin
      "$HOME"/Library/Application\ Support/*/models/*/ggml-*.bin
      "$HOME"/Library/Application\ Support/*/ggml-*.bin
      "$HOME"/Documents/superwhisper/models/ggml-*.bin
      "$HOME"/Documents/superwhisper/models/*/ggml-*.bin
      /Applications/*.app/Contents/Resources/models/ggml-*.bin
      "$HOME"/.cache/whisper*/ggml-*.bin
      "$HOME"/.local/share/*/models/ggml-*.bin
      "$HOME"/whisper.cpp/models/ggml-*.bin
      "$HOME"/src/whisper.cpp/models/ggml-*.bin
      /usr/local/share/whisper.cpp/models/ggml-*.bin
      /opt/homebrew/share/whisper.cpp/models/ggml-*.bin
    )

    for m in "${KANDIDATI_MODEL[@]}"; do
      [ -f "$m" ] || continue
      # pod 40 MB to neni prepisovaci model, ale nejaky pomocny soubor
      [ "$(velikost "$m")" -gt 41943040 ] || continue
      s="$(skore_modelu "$m")"
      if [ "$s" -gt "$NEJSKORE" ]; then
        NEJSKORE="$s"
        NEJLEPSI="$m"
      fi
    done
  fi

  if [ -n "$NEJLEPSI" ]; then
    ln -sfn "$NEJLEPSI" "$MODELS/$(basename "$NEJLEPSI")"
    echo "[setup] Model uz v pocitaci je, beru ho odsud:"
    echo "        $NEJLEPSI ($(lidsky "$(velikost "$NEJLEPSI")"))"
    PREVZATO+=("$(basename "$NEJLEPSI") -> $NEJLEPSI")
    if [ "$NEJSKORE" -lt 60 ]; then
      echo "[setup] Pozor: je to mensi model nez large. Prepisy pojedou, ale budou"
      echo "        o neco horsi. Vetsi si vynutis pres BEYOND_WHISPER_STAHNI=1."
    fi
  else
    echo "[setup] Stahuji model large-v3-turbo (~1,6 GB) ..."
    if ! curl -L --fail --progress-bar \
        "https://huggingface.co/ggerganov/whisper.cpp/resolve/main/ggml-large-v3-turbo.bin?download=true" \
        -o "$MODEL"; then
      rm -f "$MODEL"
      CHYBY+=("model — stahni rucne z https://huggingface.co/ggerganov/whisper.cpp a uloz jako $MODEL")
    fi
  fi
fi

# ---------------------------------------------------------------------------
# 3. ffmpeg
# ---------------------------------------------------------------------------

if command -v ffmpeg >/dev/null 2>&1 || [ -x "$BIN/ffmpeg" ]; then
  echo "[setup] ffmpeg uz je, preskakuji."
else
  NALEZENY_FFMPEG=""
  if [ "$HLEDAT" = "1" ]; then
    KANDIDATI_FFMPEG=(
      /Applications/*.app/Contents/Resources/bin/ffmpeg
      /Applications/*.app/Contents/Resources/ffmpeg
      /Applications/*.app/Contents/MacOS/ffmpeg
      "$HOME"/Applications/*.app/Contents/Resources/bin/ffmpeg
    )
    NALEZENY_FFMPEG="$(prvni_funkcni "${KANDIDATI_FFMPEG[@]}" || true)"
  fi

  if [ -n "$NALEZENY_FFMPEG" ]; then
    ln -sfn "$NALEZENY_FFMPEG" "$BIN/ffmpeg"
    echo "[setup] ffmpeg uz v pocitaci je, beru ho odsud:"
    echo "        $NALEZENY_FFMPEG"
    PREVZATO+=("ffmpeg -> $NALEZENY_FFMPEG")
  elif command -v brew >/dev/null 2>&1; then
    brew install ffmpeg || CHYBY+=("ffmpeg — brew install ffmpeg selhalo")
  else
    CHYBY+=("ffmpeg — nainstaluj ho (macOS: brew install ffmpeg, Linux: apt install ffmpeg)")
  fi
fi

# ---------------------------------------------------------------------------
# 4. yt-dlp (volitelne)
# ---------------------------------------------------------------------------

if ! command -v yt-dlp >/dev/null 2>&1 && [ ! -x "$BIN/yt-dlp" ]; then
  if command -v brew >/dev/null 2>&1; then
    brew install yt-dlp >/dev/null 2>&1 || true
  fi
fi

# ---------------------------------------------------------------------------
# Zaver
# ---------------------------------------------------------------------------

if [ ${#PREVZATO[@]} -gt 0 ]; then
  {
    echo "# Odkud brain bere whisper"
    echo "#"
    echo "# Zapsal setup-whisper.sh $(date +%d.%m.%Y). Nic velkeho se nestahovalo,"
    echo "# tohle jsou odkazy na uz nainstalovane veci jinde v pocitaci. Kdyz tu"
    echo "# aplikaci odinstalujes, odkazy se rozbiji a prepisy prestanou fungovat."
    echo "# Spravi to nove spusteni: bash .beyond/setup-whisper.sh"
    echo "# Vlastni kopii si vynutis pres BEYOND_WHISPER_STAHNI=1."
    echo
    for p in "${PREVZATO[@]}"; do echo "$p"; done
  } > "$ZDROJE"
fi

echo
if [ ${#CHYBY[@]} -eq 0 ]; then
  if [ ${#PREVZATO[@]} -gt 0 ]; then
    echo "[setup] Hotovo. Prepisy jedou lokalne a zadarmo, nic velkeho se nestahovalo."
    echo "        Prehled prevzatych veci je v .beyond/whisper-zdroj.txt."
  else
    echo "[setup] Hotovo. Prepisy jedou lokalne a zadarmo."
  fi
else
  echo "[setup] Cast se nepovedla. Bez toho prepisy nepojedou, ale zbytek brainu ano:"
  for c in "${CHYBY[@]}"; do echo "  - $c"; done
fi
