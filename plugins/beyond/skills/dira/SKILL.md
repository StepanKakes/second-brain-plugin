---
name: dira
description: Najde temata, o kterych uzivatel porad mluvi, ale neudelal o nich zadny obsah. Generator temat z jeho vlastnich dat. Pouzij, kdyz rika "o cem mluvim a nenatocil jsem to", "najdi diry", "co bych mel natocit", "dej mi temata na tyden", "/beyond:dira".
---

# dira

Nejsilnější vyhledávací skill. Hledá **mezeru mezi tím, o čem uživatel mluví,
a tím, o čem udělal obsah.**

Princip: nejcennější téma je věc, kterou řeší dokola, ale nikdy ji nezabalil
do obsahu. Tohle za něj nikdo jiný nenajde, protože nikdo jiný nemá jeho
cally a jeho poznámky.

**Čte destilát, nikdy `_raw/`.**

## Postup

### 1. Sestav „o čem mluví" (poptávka)

- **Vzorce** (tři a víc výskytů) napříč `znalosti/`. Tohle váží nejvíc.
- Časté postoje z `znalosti/postoje.md` a metodika z `znalosti/metodika.md`.
- Opakující se problémy publika z `znalosti/jazyk-publika.md`, hlavně
  doslovné citace.
- Témata z `cally/digesty.md`, která se objevují ve víc callech.

### 2. Sestav „o čem už udělal obsah" (pokrytí)

- `obsah/publikovano.md` — co vyšlo,
- řádky „Použito" u záznamů,
- `obsah/drafty/` — co je rozdělané.

### 3. Najdi díry

Vysoká poptávka a nulové pokrytí. Seřaď podle síly:
**vzorec bez obsahu > častý postoj bez obsahu > jednotlivost.**

### 4. Ověř každou díru

Než ji vypíšeš, zkontroluj, že opravdu není pokrytá. **Když si pokrytím
nejsi jistý, řekni to** místo abys hádal.

## Co vrátit

Tři až pět děr, každá:

- **Téma** jednou větou a proč je to díra (jak často to řeší proti tomu,
  že o tom není obsah).
- **Důkaz poptávky:** kde všude to v brainu je, kolikrát, ideálně jedna
  doslovná citace.
- **Konkrétní návrh formátu** postavený na existujícím materiálu.

Nejsilnější nahoru. Vzorec bez obsahu vždycky první.

Když `obsah/publikovano.md` neexistuje nebo je chudý, řekni rovnou, že
pokrytí odhaduješ jen z „Použito" značek, a že přesnost tohohle skillu
výrazně stoupne, až se začne vést, co vyšlo.

## Železná pravidla

- **Nehádej pokrytí.** „Nejsem si jistý, ověř si to" je poctivá odpověď.
- **Díra bez důkazu je tip od boku.** Vždycky zdroje a počty.
- Nedomýšlej názory, pracuj jen s tím, co v brainu je.
- Výstup je podklad, ne hotový obsah.
