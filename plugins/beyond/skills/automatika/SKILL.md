---
name: automatika
description: Zapne nocni beh na uzivatelove pocitaci pres planovac operacniho systemu. Pouzij, kdyz rika "at to bezi samo", "zapni automatiku", "stahuj cally sam", "/beyond:automatika".
---

# automatika

Zaregistruje úlohy do plánovače operačního systému, aby brain sbíral
a destiloval sám, i když Clauda zrovna neotevře.

**Uživatel neklikne v nastavení systému ani jednou. Uděláš to za něj.**

## Co se plánuje

| Kdy | Co | Čím |
|---|---|---|
| ráno 7:12 | stáhnout nové cally z Fathomu | `scripts/fathom-pull` (čistý skript, žádný model, žádná cena) |
| večer 21:12 | zpracovat inbox a zdestilovat | `claude -p` v neinteraktivním režimu |

Časy nejsou kulaté schválně, ať se to netluče s tím, co si pouští každý.

## Postup

1. **Zjisti, jestli má `claude` v PATH.** Bez toho večerní úloha nepojede.
   Když ho nemá, zaregistruj jen ranní stahování a řekni to.
2. **Windows:** `scripts/automatika-install.ps1`, který volá
   `Register-ScheduledTask`. Úloha běží pod jeho účtem, jen když je přihlášený.
3. **macOS:** `scripts/automatika-install.sh`, který zapíše plist do
   `~/Library/LaunchAgents/` a načte ho přes `launchctl load`.
4. **Ověř, že úloha vznikla**, a vypiš, jak ji vypnout. Nikdy nenech na
   cizím počítači něco, o čem uživatel neví, jak to zrušit.
5. Zapiš do `.beyond/stav.md`, co je naplánované a od kdy.

## Co uživateli říct rovnou

- **Běží to jen když je počítač zapnutý.** Vypnutý notebook nic nestáhne.
  U lokálního brainu to tak prostě je.
- **Večerní destilace stojí peníze**, protože jede přes model na jeho účtu.
  Ranní stahování je zadarmo.
- Ráno uvidí, co přibylo, v `.beyond/posledni-beh.md`.

## Vypnutí

Musí být stejně snadné jako zapnutí. `scripts/automatika-remove.ps1`
a `.sh`. Když se ptá „jak to vypnu", je odpověď jeden příkaz, ne návod
do nastavení systému.

## Když to nechce

Nevadí a netlač na to. `SessionStart` hook stahuje cally při každém
otevření Clauda v brainu, což většině lidí stačí. Chová se to jako
Obsidian: když ho neotevřeš, neděje se nic.
