#!/usr/bin/env bash
# fathom-pull.sh — stahne nove cally z Fathomu do cally/ (macOS, Linux).
#
# Pouziti (z korene brainu):
#   bash <plugin>/scripts/fathom-pull.sh [cesta-k-brainu]
#
# Klic bere z .env v koreni brainu (FATHOM_API_KEY=...).
# Ledger .beyond/fathom-stav.json drzi recording_id uz stazenych callu.
#
# ZELEZNE PRAVIDLO: do ledgeru se zapisuje az po tom, co soubor existuje na disku.

set -euo pipefail

BRAIN="${1:-$PWD}"
ENV_FILE="$BRAIN/.env"
CALLY="$BRAIN/cally"
STATE_DIR="$BRAIN/.beyond"
STATE="$STATE_DIR/fathom-stav.json"
# Fathom vraci 10 callu na stranku a parametr limit ignoruje (overeno 02.09.2026).
# Vic se bere pres kurzor. Pri prvnim nasati historie: MAX_STRAN=20 bash fathom-pull.sh
MAX_STRAN="${MAX_STRAN:-1}"

if [ ! -f "$ENV_FILE" ]; then
  echo "[fathom] .env v $BRAIN neni — preskakuji. Neni to chyba."
  exit 0
fi

KEY="$(grep -E '^FATHOM_API_KEY=' "$ENV_FILE" | head -n1 | cut -d= -f2- | tr -d '"' | xargs || true)"
if [ -z "$KEY" ]; then
  echo "[fathom] FATHOM_API_KEY neni vyplneny — preskakuji. Neni to chyba."
  exit 0
fi

for dep in curl jq; do
  if ! command -v "$dep" >/dev/null 2>&1; then
    echo "[fathom] Chybi $dep. Na macOS: brew install $dep"
    exit 1
  fi
done

mkdir -p "$CALLY" "$STATE_DIR"
[ -f "$STATE" ] || echo '{"hotovo":[]}' > "$STATE"

if ! jq -e . "$STATE" >/dev/null 2>&1; then
  echo "[fathom] Ledger $STATE je poskozeny. Koncim, at neprepisu historii."
  exit 1
fi

ZAKLAD="https://api.fathom.ai/external/v1/meetings?include_transcript=true&include_summary=true&include_action_items=true"
RESP="$(mktemp)"
STRANKA="$(mktemp)"
trap 'rm -f "$RESP" "$STRANKA"' EXIT

echo '{"items":[]}' > "$RESP"
KURZOR=""
STRANA=0

while :; do
  URL="$ZAKLAD"
  [ -z "$KURZOR" ] || URL="$ZAKLAD&cursor=$KURZOR"

  if ! curl -sS -f --max-time 180 -H "X-Api-Key: $KEY" "$URL" -o "$STRANKA"; then
    if [ "$(jq '.items | length' "$RESP")" = "0" ]; then
      echo "[fathom] Volani API selhalo."
      exit 1
    fi
    break   # co uz mame, to zpracujeme
  fi

  TMP="$(mktemp)"
  jq -s '{items: (.[0].items + .[1].items)}' "$RESP" "$STRANKA" > "$TMP" && mv "$TMP" "$RESP"

  KURZOR="$(jq -r '.next_cursor // empty' "$STRANKA")"
  STRANA=$((STRANA + 1))
  [ -n "$KURZOR" ] && [ "$STRANA" -lt "$MAX_STRAN" ] || break
done

COUNT="$(jq '.items | length' "$RESP")"
if [ "$COUNT" = "0" ]; then
  echo "[fathom] API nevratilo zadne cally."
  exit 0
fi

slugify() {
  echo "$1" \
    | tr '[:upper:]' '[:lower:]' \
    | sed 'y/áàâäéěèêëíìîïóòôöúůùûüýčďňřšťž/aaaaeeeeeiiiiooooouuuuuycdnrstz/' \
    | sed 's/[^a-z0-9]\+/-/g; s/^-//; s/-$//'
}

NOVYCH=0

for i in $(seq 0 $((COUNT - 1))); do
  ID="$(jq -r ".items[$i].recording_id // empty" "$RESP")"
  [ -n "$ID" ] || continue

  if jq -e --arg id "$ID" '.hotovo | index($id)' "$STATE" >/dev/null 2>&1; then
    continue
  fi

  TITLE="$(jq -r ".items[$i].title // \"call\"" "$RESP")"
  # Pole se jmenuje recording_start_time (overeno proti API 02.09.2026).
  # Kdyz se to splete, vsechny cally dostanou dnesni datum.
  START="$(jq -r ".items[$i].recording_start_time // .items[$i].scheduled_start_time // empty" "$RESP")"
  DATUM="${START:0:10}"
  [ -n "$DATUM" ] || DATUM="$(date +%F)"
  SLUG="$(slugify "$TITLE")"
  [ -n "$SLUG" ] || SLUG="call"

  FILE="$CALLY/$DATUM-$SLUG.md"
  [ ! -f "$FILE" ] || FILE="$CALLY/$DATUM-$SLUG-$ID.md"

  {
    echo "---"
    echo "zdroj: fathom"
    echo "datum: $DATUM"
    echo "nazev: $TITLE"
    echo "odkaz: $(jq -r ".items[$i].share_url // \"\"" "$RESP")"
    echo "recording_id: $ID"
    echo "---"
    echo
    echo "# $TITLE"
    echo

    UCAST="$(jq -r ".items[$i].calendar_invitees[]? | (.name // .email)" "$RESP" | paste -sd ", " -)"
    if [ -n "$UCAST" ]; then
      echo "**Ucastnici:** $UCAST"
      echo
    fi

    SUM="$(jq -r ".items[$i].default_summary.markdown_formatted // empty" "$RESP")"
    if [ -n "$SUM" ]; then
      echo "## Shrnuti od Fathomu"
      echo
      echo "$SUM"
      echo
    fi

    if [ "$(jq ".items[$i].action_items | length" "$RESP")" != "0" ]; then
      echo "## Ukoly"
      echo
      jq -r ".items[$i].action_items[] | \"- [ ] \" + .description + (if .assignee.name then \" (\" + .assignee.name + \")\" else \"\" end)" "$RESP"
      echo
    fi

    if [ "$(jq ".items[$i].transcript | length" "$RESP")" != "0" ]; then
      echo "## Prepis"
      echo
      jq -r ".items[$i].transcript[] | \"**\" + (.speaker.display_name // \"?\") + \":** \" + .text" "$RESP"
      echo
    else
      echo "> Prepis Fathom nevratil. Doplni se pri dalsim behu."
      echo
    fi
  } > "$FILE"

  # Ledger az potom, a jen kdyz soubor opravdu je.
  if [ -s "$FILE" ]; then
    TMP="$(mktemp)"
    jq --arg id "$ID" '.hotovo += [$id] | .aktualizovano = (now | todate)' "$STATE" > "$TMP" && mv "$TMP" "$STATE"
    NOVYCH=$((NOVYCH + 1))
    echo "[fathom] + $(basename "$FILE")"
  else
    echo "[fathom] ! zapis selhal, $ID zkusim priste"
  fi
done

if [ "$NOVYCH" = "0" ]; then
  echo "[fathom] Nic noveho."
else
  echo "[fathom] Hotovo, novych callu: $NOVYCH"
fi
