---
name: napad
description: Vytahne z brainu vsechno k danemu tematu a oznaci, co uzivatel jeste nikdy nepouzil v obsahu. Pouzij, kdyz rika "co mam k tematu X", "napad na obsah o X", "co jsem rikal o X", "dej mi tema na reels", "/beyond:napad X".
---

# napad

Vyhledávací skill nad `znalosti/` a `obsah/`. Odpovídá na otázku
„co k tomuhle už mám a co z toho jsem ještě nepoužil".

**Čte destilát, nikdy `_raw/`.** V raw je šum, proto vznikla destilace.

## Vstup

Téma jedním slovem nebo frází. Když ho uživatel neřekne, **zeptej se
na jedno slovo.** Nehádej, výsledek by byl o ničem.

## Postup

1. **Prohledej celé `znalosti/` a `obsah/`** na téma i jeho synonyma:
   `postoje.md`, `formulace.md`, `pribehy.md`, `metodika.md`,
   `jazyk-publika.md`, `rozhodnuti.md`, `obsah/co-funguje.md`,
   `obsah/napady.md`. Hledej i podle témat uvnitř záznamů, ne jen doslovné slovo.
2. **Seskup nález** podle typu: postoje, příběhy, formulace, metodika,
   jazyk publika, čísla.
3. **Označ vzorce** (tři a víc výskytů). Co se vrací, rezonuje, a to jsou
   nejsilnější kandidáti na obsah.
4. **Najdi nevyužité.** U záznamů koukni na řádek „Použito" a do
   `obsah/publikovano.md`. Co nemá „Použito", je čerstvý materiál, který
   ještě nikde nezazněl. **Tohle je hlavní hodnota skillu, zvýrazni to.**
5. **Když je téma chudé** (míň než dva záznamy), řekni to rovnou a navrhni,
   co zpracovat, aby zbohatlo.

## Co vrátit

- **Co k tématu máš:** tři až šest nejsilnějších kusů, každý s doslovnou
  citací a odkazem na zdrojový soubor, ať se to dá ověřit.
- **Nevyužité:** co ještě nikdy nedal do obsahu. Tohle první.
- **Jeden až dva konkrétní návrhy formátu** postavené na tom materiálu.
  Ne obecně „udělej reel o prodeji", ale „vezmi tuhle větu jako hook
  a tenhle příběh jako střed".
- Když je materiál slabý, řekni to.

Piš v jeho hlasu podle `ja/hlas.md`.

## Železná pravidla

- **Nikdy si nedomýšlej jeho názor.** Co není v brainu, není. „Tohle tam
  nemám" je legitimní a užitečná odpověď.
- **Vždycky uveď zdroj** u každého tvrzení. Dohledatelnost je půlka hodnoty.
- Doslovné citace neuhlazuj.
- Tohle je podklad na přemýšlení, ne hotový post. Hotový draft dělej,
  jen když si o něj řekne, a ukládej ho do `obsah/drafty/`.
