#!/usr/bin/env bash
# transcribe.sh — prepis audia, videa nebo odkazu pres lokalni whisper.cpp (macOS, Linux).
#
# Pouziti:
#   bash transcribe.sh "/cesta/hlasovka.m4a"
#   bash transcribe.sh "https://youtu.be/xxxx"
#   COOKIES=/cesta/cookies.txt bash transcribe.sh "https://instagram.com/reel/xxx"
#   JAZYK=en bash transcribe.sh ...            # vychozi cs
#   BRAIN=/cesta/k/brainu bash transcribe.sh ...
#
# Vystup: cisty text na stdout.

set -euo pipefail

ZDROJ="${1:?Chybi cesta k souboru nebo odkaz}"
BRAIN="${BRAIN:-$PWD}"
JAZYK="${JAZYK:-cs}"
COOKIES="${COOKIES:-}"

BIN="$BRAIN/.beyond/bin"
MODELS="$BRAIN/.beyond/models"

# Model se muze jmenovat ruzne, kdyz ho setup-whisper prevzal z jine aplikace,
# ktera whisper.cpp uz mela. Bereme ten nejvetsi, ktery je po ruce.
vyber_model() {
  local nejlepsi="" nejskore=0 s f
  shopt -s nullglob
  for f in "$MODELS"/ggml-*.bin; do
    [ -f "$f" ] || continue
    case "$(basename "$f")" in
      *silero*|*vad*|*encoder*) continue ;;
      *large-v3-turbo*)         s=90 ;;
      *large-v3*)               s=80 ;;
      *large-v2*)               s=70 ;;
      *large*)                  s=60 ;;
      *medium*)                 s=50 ;;
      *small*)                  s=40 ;;
      *base*)                   s=30 ;;
      *tiny*)                   s=20 ;;
      *)                        continue ;;
    esac
    if [ "$s" -gt "$nejskore" ]; then nejskore="$s"; nejlepsi="$f"; fi
  done
  shopt -u nullglob
  [ -n "$nejlepsi" ] && echo "$nejlepsi"
}

find_tool() {
  local name="$1"
  if [ -x "$BIN/$name" ]; then echo "$BIN/$name"; return 0; fi
  command -v "$name" 2>/dev/null || true
}

FFMPEG="$(find_tool ffmpeg)"
WHISPER="$(find_tool whisper-cli)"
[ -n "$WHISPER" ] || WHISPER="$(find_tool whisper-cpp)"
YTDLP="$(find_tool yt-dlp)"

MODEL="$(vyber_model || true)"

if [ -z "$FFMPEG" ] || [ -z "$WHISPER" ] || [ -z "$MODEL" ] || [ ! -f "$MODEL" ]; then
  echo "CHYBI ffmpeg, whisper-cli nebo model. Spust nejdriv setup-whisper.sh."
  exit 1
fi

TMPDIR_="$(mktemp -d)"
trap 'rm -rf "$TMPDIR_"' EXIT
WAV="$TMPDIR_/audio.wav"
VSTUP="$ZDROJ"

case "$ZDROJ" in
  http://*|https://*)
    if [ -z "$YTDLP" ]; then
      echo "CHYBI yt-dlp. Odkazy bez nej neprepisu. Na macOS: brew install yt-dlp"
      exit 1
    fi
    ARGS=(-f "bestaudio/best" -o "$TMPDIR_/stazene.%(ext)s" --no-playlist --quiet)
    [ -z "$COOKIES" ] || ARGS+=(--cookies "$COOKIES")
    if ! "$YTDLP" "${ARGS[@]}" "$ZDROJ"; then
      echo "CHYBA: stazeni odkazu selhalo. U Instagramu byva duvod chybejici nebo vyprsele cookies."
      exit 1
    fi
    VSTUP="$(find "$TMPDIR_" -name 'stazene.*' | head -n1)"
    ;;
esac

if [ ! -f "$VSTUP" ]; then
  echo "CHYBA: soubor $VSTUP neexistuje."
  exit 1
fi

if ! "$FFMPEG" -y -loglevel error -i "$VSTUP" -ar 16000 -ac 1 -c:a pcm_s16le "$WAV"; then
  echo "CHYBA: ffmpeg nedokazal z tohohle souboru vytahnout zvuk."
  exit 1
fi

"$WHISPER" -m "$MODEL" -l "$JAZYK" -np -nt "$WAV" 2>/dev/null | sed '/^[[:space:]]*$/d'
