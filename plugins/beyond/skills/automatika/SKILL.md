---
name: automatika
description: Zapne pravidelny beh na uzivatelove pocitaci pres planovac operacniho systemu. Zepta se, co ma bezet samo a v kolik. Pouzij, kdyz rika "at to bezi samo", "zapni automatiku", "stahuj cally sam", "chci to jinak nastavit", "/beyond:automatika".
---

# automatika

Zaregistruje úlohy do plánovače operačního systému, aby brain sbíral
a destiloval sám, i když Clauda zrovna neotevře.

**Nic není předem dané. Ptáš se, co má běžet a v kolik.** Uživatel neklikne
v nastavení systému ani jednou, uděláš to za něj.

## Co jde naplánovat

| Úloha | Co dělá | Cena | Podmínka |
|---|---|---|---|
| **Cally** | stáhne nové cally z Fathomu do `cally/` | zadarmo, je to čistý skript | vyplněný `FATHOM_API_KEY` v `.env` |
| **Destilace** | zpracuje `_inbox/` a zdestiluje nové soubory z `_raw/` do znalostí | jede přes model, stojí tokeny | `claude` v PATH |
| **Týdenní přehled** | projede `/beyond:tyden` a nechá výstup v brainu | jede přes model, stojí tokeny | `claude` v PATH |

Každá jde zapnout zvlášť. Nikdo nemusí brát všechny tři.

## Postup

### 1. Zjisti, co má vůbec smysl nabízet

Než se zeptáš, ověř:

- `command -v claude` (na Windows `Get-Command claude`). Bez toho nemá smysl
  nabízet destilaci ani týdenní přehled, protože obojí jede přes model.
- `FATHOM_API_KEY` v `.env`. **Když je prázdný, ranní stahování by běželo
  naprázdno.** Řekni to a nabídni buď doplnit klíč, nebo tuhle úlohu vynechat.
  Nenaplánuj úlohu, o které víš, že nic neudělá.

### 2. Zeptej se, co chce

Ne dotazník. Jedna otázka, tři možnosti, a ať si vybere klidně jen jednu
nebo žádnou. Řekni u toho rovnou cenu, ať se rozhoduje s informací:

> Co má běžet samo? Stahování callů z Fathomu je zadarmo, je to obyčejný
> skript. Večerní zpracování inboxu a destilace jede přes model, takže to
> stojí tokeny na tvém účtu. To samé týdenní přehled.

Když řekne, že nic, je to v pořádku. Nenaléhej a jdi dál.

### 3. Zeptej se na časy

U každé zvolené úlohy se zeptej, kdy se mu to hodí. Nabídni návrh, ať nemusí
vymýšlet: cally ráno, destilace večer, přehled v neděli podvečer.

**Nedávej celé hodiny ani půlhodiny.** Když řekne „ráno kolem sedmé", nastav
6:47 nebo 7:12, ne 7:00. Kulaté časy má naplánované každý a zbytečně se to
tluče s tím, co si na počítači pouští sám.

Ptej se na denní dobu, ne na cron. Cron neumí a nemá umět.

### 4. Řekni tři věci, které ho čekají

- **Běží to jen na zapnutém počítači.** Uspaný Mac úlohu spustí po probuzení,
  vypnutý notebook nestihne nic. U lokálního brainu to tak prostě je.
- **Úlohy přes model stojí peníze.** Stahování callů ne.
- **Výsledek si musí přijít přečíst sám.** Po večerním běhu leží shrnutí
  v `.beyond/posledni-beh.md`. Nikam mu nepřijde upozornění.

### 5. Nainstaluj

macOS:

```
bash scripts/automatika-install.sh <cesta-k-brainu> --cally 6:47 --destilace 21:12 --tyden ne,18:12
```

Windows:

```
powershell -ExecutionPolicy Bypass -File scripts/automatika-install.ps1 -BrainRoot <cesta> -Cally "6:47" -Destilace "21:12" -Tyden "ne,18:12"
```

Vynech přepínač u toho, co nechce. **Neuvedená úloha se nejen nenainstaluje,
ale i zruší, když tam z dřívějška byla.** Díky tomu je změna volby jenom nové
spuštění skriptu s jinými přepínači, nemusíš nic rušit ručně.

Když nechce nic, pusť to s `--nic` (Windows `-Nic`).

### 6. Ověř a zapiš

Zkontroluj, že úlohy vznikly (`launchctl list | grep growbeyond`, na Windows
`Get-ScheduledTask -TaskName "Beyond Brain*"`), a zapiš do `.beyond/stav.md`,
co je naplánované, v kolik a od kdy.

Na konec vypiš, jak to změnit a jak vypnout. **Nikdy nenech na cizím počítači
něco, o čem uživatel neví, jak to zrušit.**

## Změna a vypnutí

Změna je nové spuštění instalátoru s jinými volbami. Vypnutí je
`scripts/automatika-remove.sh` nebo `.ps1` a zruší všechno včetně úloh
z dřívějších verzí pluginu.

Když se ptá „jak to vypnu", je odpověď jeden příkaz, ne návod do nastavení
systému.

## Když to nechce

Nevadí a netlač na to. `SessionStart` hook připomene inbox při každém otevření
Clauda v brainu, což většině lidí stačí. Chová se to jako Obsidian: když ho
neotevřeš, neděje se nic.

## Proč to neběží v cloudu

Ptá se na to skoro každý, tak k tomu fakta (ověřeno 03.09.2026):

- **Routines na claude.ai** existují a běží na cronu v cloudu, ale běží
  **server side a umí sáhnout jen na claude.ai konektory**. Na lokální složku
  brainu nedosáhnou, lokální whisper nespustí a do `_inbox/` se nepodívají.
  Použitelné by to bylo až ve chvíli, kdy brain žije jako GitHub repo, a i pak
  by to pokrylo jen stahování z API a destilaci textu, ne přepisy hlasovek.
  Organizace je navíc může mít politikou vypnuté.
- **Naplánované úlohy v desktopové appce Clauda** (`~/.claude/scheduled-tasks/`)
  jsou taky lokální, ne cloudové, a běží jen **když je appka otevřená**.
  Zmeškaný běh dojedou při dalším spuštění. Oproti plánovači systému je to
  krok zpátky, protože appka musí být puštěná.
- **CronCreate v session** je jen pro tu jednu konverzaci, drží se v paměti,
  po zavření Clauda mizí a stejně vyprší po sedmi dnech. Pro produkt nepoužitelné.

Proto plánovač operačního systému. Je to jediná cesta, která funguje nad
lokální složkou, bez otevřené aplikace a bez toho, aby brain musel být
na GitHubu.
