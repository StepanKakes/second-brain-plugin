---
name: kalendar
description: Vede plan publikaci v jednom markdown souboru. Pouzij, kdyz uzivatel rika "naplanuj obsah", "co mam tenhle tyden vydat", "pridej to do kalendare", "co uz vyslo", "/beyond:kalendar".
---

# kalendar

Plán publikací je **jeden soubor**, `obsah/kalendar.md`, ne databáze.
Vedle něj je `obsah/publikovano.md`, kam se stěhuje, co už vyšlo.

Důvod, proč to není nic chytřejšího: kalendář, který se otevírá jinde než
brain, se přestane vyplňovat. Tady je vedle materiálu, ze kterého se plánuje.

## Formát

```markdown
## Týden 12. 1. — 18. 1.

- [ ] **Út 13. 1.** · reel · Proč nefunguje víc obsahu
      Materiál: znalosti/postoje.md#vic-obsahu, pribehy.md#klient-marek
      Stav: nápad
- [x] **Čt 15. 1.** · story · Zákulisí přípravy programu
      Stav: vyšlo → obsah/publikovano.md
```

Stavy: `nápad` → `napsáno` → `natočeno` → `vyšlo`. Nic mezi tím.

## Co dělá

**Plánování.** Když si řekne o plán na týden, vezmi témata z
`/beyond:dira` a `obsah/napady.md`, ne z hlavy. Ke každému bodu **připiš,
z jakého materiálu se to bude dělat.** Položka bez materiálu se nenatočí,
protože v den natáčení začne od nuly.

**Zápis.** Když řekne, že něco vyšlo, přesuň to do `obsah/publikovano.md`
s datem a odkazem, a u použitých záznamů v `znalosti/` doplň řádek
„Použito: [datum, formát]".

**Přehled.** Když se ptá, co ho čeká, vrať tenhle týden a příští, nic víc.

## Železná pravidla

- **Neplánuj za něj celý měsíc dopředu**, když si o to neřekne. Plán, který
  nikdo nedodrží, je horší než žádný, protože ho pak přestane otevírat.
- Nepřepisuj, co už je označené jako vyšlé.
- Když plánuješ a v brainu na téma není materiál, řekni to u té položky.
  Je lepší to vědět při plánování než v den natáčení.
