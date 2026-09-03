# Struktura brainu

Tohle zakládá `/beyond:init`. Šablony jsou v `templates/seed/`, kopíruj je,
needituj je v pluginu.

```
muj-brain/
├── CLAUDE.md              z templates/CLAUDE.md.tmpl, doplněný z rozhovoru
├── .env                   z templates/env.tmpl, mimo git
├── .gitignore             z templates/gitignore.tmpl
├── .beyond/               stav a technické soubory, Obsidian to skryje
│   ├── stav.md            co je nastavené a co ne
│   ├── fathom-stav.json   ledger stažených callů
│   ├── destilace-stav.md  ledger zdestilovaných souborů
│   ├── whisper-zdroj.txt  odkud se whisper prevzal, kdyz uz v pocitaci byl
│   ├── bin/               whisper, ffmpeg, yt-dlp (nebo odkazy na ne)
│   └── models/            ggml model, jmeno zavisi na tom, co se naslo
├── ja/
│   ├── profil.md          kdo jsem, co prodávám, komu
│   ├── hlas.md            style guide, vyrobí /beyond:hlas
│   └── texty/             web, prodejní stránka, newsletter
├── cally/
│   └── digesty.md         shrnutí zpracovaných callů
├── _inbox/
│   └── _zpracovano/       hotové vstupy
├── _raw/                  doslovné přepisy
├── znalosti/
│   ├── postoje.md
│   ├── pribehy.md
│   ├── formulace.md
│   ├── jazyk-publika.md
│   ├── metodika.md
│   └── rozhodnuti.md
├── obsah/
│   ├── kalendar.md
│   ├── publikovano.md
│   ├── co-funguje.md
│   ├── napady.md
│   └── drafty/
└── prilohy/
```

## Pravidla, aby to fungovalo i v Obsidianu

- Markdown s YAML frontmatterem, nic jiného.
- `[[wikilinky]]` mezi záznamy, ať funguje graf.
- Datum v názvu souboru: `RRRR-MM-DD-nazev.md`.
- **Žádné JSON soubory na očích.** Technické věci patří do `.beyond/`,
  které Obsidian ve výchozím nastavení skryje.

## Co patří do sync složky

**Jenom `_inbox/`.** Když by se celý brain synchronizoval přes Disk nebo
Dropbox, vznikaly by konfliktní kopie souborů, do kterých zapisuje Claude.
Inbox je jediná složka, kam se jenom hází a odkud se uklízí, takže tam
konflikt nevadí.
