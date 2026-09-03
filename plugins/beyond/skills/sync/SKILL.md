---
name: sync
description: Stahne nove cally z Fathomu a zpracuje vsechno, co lezi v _inbox/ (hlasovky, videa, fotky, texty). Pouzij, kdyz uzivatel rika "sync", "co je noveho", "zpracuj inbox", "stahni cally", "/beyond:sync", nebo na zacatku session, kdyz v inboxu neco lezi.
---

# sync

Sběrač. Jediná věc, kterou dělá: **dostane nová data do brainu a nechá je
připravená k destilaci.** Nerozhoduje o obsahu, nedestiluje, nevymýšlí.
Sběr má být hloupý a spolehlivý, chytrá je až destilace.

## Krok 1: Fathom

Když je v `.env` `FATHOM_API_KEY`, spusť `scripts/fathom-pull.ps1`
(Windows) nebo `scripts/fathom-pull.sh`. Skript:

- zavolá `GET https://api.fathom.ai/external/v1/meetings?include_transcript=true&include_summary=true&include_action_items=true`
  s hlavičkou `X-Api-Key`,
- odečte, co už je v ledgeru `.beyond/fathom-stav.json` (klíč = `recording_id`),
- nové zapíše do `cally/RRRR-MM-DD-<nazev>.md`.

Do ledgeru zapisuj **až po tom, co soubor prokazatelně existuje na disku.**
Nikdy ne dopředu. Když to spadne mezi tím, call se příště stáhne znovu, a to
je správné chování. Opačná chyba je nevratná: call se označí za zpracovaný
a nikdy nedorazí.

Bez klíče krok tiše přeskoč, není to chyba.

## Krok 2: Inbox

Projdi `_inbox/` (mimo `_zpracovano/`) a každý soubor zpracuj podle přípony:

| Typ | Co s tím |
|---|---|
| `.md`, `.txt` | přečti, zařaď, žádný přepis není potřeba |
| `.jpg`, `.png`, `.heic`, `.webp` | **přečti obrázek přímo**, umíš to. Fotka poznámek, screenshot, whiteboard. Žádné OCR ani API. |
| `.pdf` | přečti přímo |
| `.m4a`, `.mp3`, `.ogg`, `.oga`, `.wav`, `.opus` | přepiš přes `scripts/transcribe` |
| `.mp4`, `.mov`, `.webm` | přepiš přes `scripts/transcribe` (vytáhne zvuk přes ffmpeg) |
| `.zip` | podívej se dovnitř. Když to vypadá jako export z Instagramu, předej to skillu `obsah-import`. |
| `odkazy.md` | řádky s URL: YouTube předej `scripts/transcribe`, ostatní stáhni a přečti |

Výstup každého zpracování ulož jako `.md` do `_raw/` s hlavičkou:

```
---
zdroj: hlasovka | video | foto | text | call | reel
datum: RRRR-MM-DD
puvod: nazev-puvodniho-souboru
---
```

Originál pak **přesuň** do `_inbox/_zpracovano/`. Přesun je dedup: co je
přesunuté, je hotové. Žádný druhý ledger na tohle nepotřebuješ.

Když přepis selže, soubor **nech v `_inbox/`** a napiš to do reportu. Nikdy
nezakládej prázdný `.md` a nepřesouvej zdroj, protože tím se vstup navždy
ztratí a nikdo si toho nevšimne.

## Krok 3: Report

Krátce, v odrážkách:

- co přibylo (kolik callů, kolik položek z inboxu),
- co selhalo a proč,
- **nabídni destilaci**: „Mám to zdestilovat?" Nedělej to sám, destilace
  je delší a dražší operace a uživatel má vědět, že běží.

## Železná pravidla

- **Ticho není úspěch.** Když něco nenajdeš nebo nepřečteš, řekni to.
  Prázdný výsledek vypadá stejně jako „nic nového" a takhle se tiše
  ztrácejí data.
- **Nepřepisuj cally, které už Fathom přepsal.** Máš je hotové z API.
- Do `_raw/` piš doslovné přepisy, ne shrnutí. Zkracuje se až v destilaci.
- Když je `_inbox/` prázdný a Fathom nic nevrátil, řekni jednu větu
  a skonči. Nevymýšlej práci.
