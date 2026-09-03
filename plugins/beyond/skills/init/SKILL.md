---
name: init
description: Provede uzivatele nastavenim brainu. Pouzij, kdyz poprve spousti Beyond plugin, rika "zaloz mi brain", "nastav to", "pojdme to nastavit", "/beyond:init", nebo kdyz je slozka prazdna a plugin je nainstalovany. Zeptas se po etapach na par veci, zalozis strukturu, napises CLAUDE.md na miru, napojis klice, nastavis prepisy, nasajes jeho existujici obsah a vyrobis z nej jeho style guide.
---

# init

Zaváděcí průvodce. Po něm má uživatel na disku funkční brain, který zná
jeho, umí mluvit jeho hlasem a má v sobě jeho existující obsah.

Trvá to zhruba 15 minut a **většinu času mluví uživatel, ne ty.**

## Jak se ptáš (tohle je nejdůležitější odstavec celého skillu)

- **Jedna otázka na jednu zprávu.** Nikdy nedávej seznam šesti otázek.
  Z dotazníku vypadnou odpovědi na jednu řádku a z těch se style guide
  postavit nedá.
- **Reaguj na odpovědi.** Když řekne něco zajímavého, doptej se. Tohle
  není formulář, je to rozhovor, ze kterého vzniká jeho profil.
- **Zapisuj jeho slova, ne svoje.** Když řekne „lidi si myslí, že
  potřebujou víc followerů, a přitom potřebujou líp prodávat", ulož
  přesně tuhle větu. Neuhlazuj ji do „edukuje publikum o konverzi".
  Ten rozdíl je celý smysl složky `ja/`.
- **Řekni dopředu, kolik etap zbývá.** Lidi vydrží, když vědí, kde jsou.

## Průběh v pěti etapách

Po každé etapě zapiš stav do `.beyond/stav.md`. **Když uživatel skončí
uprostřed, musí jít příště pokračovat tam, kde přestal**, ne od začátku.
Na začátku `init` proto vždycky nejdřív zkontroluj, jestli `stav.md`
neexistuje, a když ano, nabídni pokračování.

---

### Etapa 1 z 5: Kde brain vznikne

Zeptej se, kam ho založit. Nabídni:

- vedle jeho Obsidian vaultu, pokud nějaký má (zeptej se na cestu),
- do `Dokumenty/muj-brain`,
- jinam, ať řekne cestu.

Když ve složce už `CLAUDE.md` s řádkem `beyond-brain:` je, brain existuje.
Neber to jako nový init, řekni, co v něm je, a nabídni `/beyond:sync`.

Vytvoř strukturu podle `templates/struktura.md`, soubory kopíruj
z `templates/seed/`. Šablony v pluginu **needituj**.

---

### Etapa 2 z 5: Kdo jsi

Šest otázek, jedna po druhé:

1. Co děláš a komu to prodáváš? Řekni to, jako bys to říkal kamarádovi
   v hospodě, ne jako na webu.
2. Kdo je člověk, kterému to nejvíc pomůže? Popiš ho jako člověka,
   ne jako cílovou skupinu.
3. Co lidem opakuješ pořád dokola, protože to nechápou?
4. V čem jdeš proti tomu, co se v tvém oboru běžně říká?
5. Kde publikuješ a jak často?
6. Co od brainu čekáš, že ti ušetří?

Z odpovědí napiš:

- `ja/profil.md` — otázky 1, 2, 5, 6,
- `znalosti/postoje.md` — první záznamy z otázek 3 a 4, ve formátu
  podle `skills/destilace/SKILL.md`. **Tohle jsou jeho první znalosti**
  a hned první den z nich `/beyond:napad` něco vytáhne.
- `CLAUDE.md` z `templates/CLAUDE.md.tmpl`, doplněný o to, co ses dozvěděl.

---

### Etapa 3 z 5: Napojení

Ptej se jen na to, co dává smysl. Nevyplňuj klíče, které nepoužije.

**Fathom** (přepisy hovorů). Zeptej se, jestli ho má. Když ano, klíč najde
v Fathom → Settings → API. Vlož do `.env` jako `FATHOM_API_KEY`.
Když ne, přeskoč, brain funguje i bez toho.

**Beo.** Zeptej se, jestli ho používá. Když ano, **tohle je největší
zkratka v celém nastavení**: Beo drží jeho napojení na Instagram, takže
z něj vytáhneme publikovaný obsah, čísla i počty leadů na příspěvek,
a z odkazů rovnou přepisy reelů. Ověř, že má Beo konektor připojený
(v Claudovi `/mcp`), a zkus zavolat `list_organizations`. Když to projde,
poznač si to do `.beyond/stav.md` na etapu 5.

Pozor: **jméno Beo MCP serveru se mění při každém přepojení** (viděli jsme
`beo-014b` i `beo-e477`). Nikdy ho nikam nepiš natvrdo, hledej nástroje
podle jména „beo".

**Gemini.** Nech prázdné. Je volitelný a řeší se, až bude potřeba rozlišit
mluvčí nebo popsat, co je ve videu vidět.

Na konci etapy řekni jednu větu nahlas: **`.env` nikam nekopíruj
a neposílej.** Je mimo git, ale to ho neochrání před tím, že ho někam
nahraje.

---

### Etapa 4 z 5: Přepisy a inbox

**Přepisy.** Spusť `scripts/setup-whisper.ps1` (Windows) nebo
`scripts/setup-whisper.sh` (macOS). Skript se **nejdřív podívá, jestli whisper
a model už v počítači nejsou**. Spousta lidí má transkripční appku (Vowen,
MacWhisper, superwhisper, Subtitle Edit) a ta si whisper.cpp i model nese
s sebou. Když se něco najde, brain na to jen ukáže a nestahuje nic.

Než to pustíš, řekni pravdu: **když se nic nenajde, stáhne se zhruba 1,7 GB**
a je to jednorázové. Za to má přepisy zadarmo, neomezeně a nic mu neodchází
z počítače.

Až skript doběhne, přečti si jeho výstup a řekni mu, jak to dopadlo: jestli
se něco převzalo (pak je seznam v `.beyond/whisper-zdroj.txt` a platí, že
odinstalování té aplikace přepisy rozbije, což se spraví novým spuštěním
skriptu), nebo jestli se stahovalo. Zapiš to do `.beyond/stav.md`.

Když to selže nebo nechce, zapiš to do `.beyond/stav.md` a jdi dál.
Není to konec, cally stejně přepisuje Fathom.

**Inbox.** Zeptej se, jestli má Google Disk, iCloud nebo Dropbox
se synchronizací do počítače. Když ano, zeptej se na cestu, vytvoř v ní
podsložku `beyond-inbox` a z brainu na ni udělej odkaz (symlink, na Windows
junction přes `New-Item -ItemType Junction`).

Vysvětli to jednou větou: **cokoli hodí do té složky z telefonu, se objeví
v brainu.** Hlasovka, fotka poznámek, screenshot, video.

Když sync složku nemá, nech `_inbox/` obyčejnou složkou. Funguje stejně,
jen do ní nedostane věci z telefonu.

**Do sync složky nikdy nedávej celý brain.** Sync služba a Claude by si
šly do zelí a vznikaly by konfliktní kopie.

---

### Etapa 5 z 5: Nasát obsah a naučit se hlas

**Tohle je etapa, kvůli které to celé děláme.** Nepřeskakuj ji ani když
uživatel spěchá. Radši zkrať etapu 2.

Důvod: prázdný brain nemá co destilovat a nemá z čeho dělat nápady.
Když z initu odejde s prázdnými složkami, do týdne to přestane otvírat.

Zdroje podle síly:

| Zdroj | Co s tím |
|---|---|
| **Beo** (když ho má) | nejrychlejší. `content_outliers`, scope „mine". Popisky a čísla do `obsah/publikovano.md` a `obsah/co-funguje.md`, permalinky reelů rovnou na přepis. Viz skill `obsah-import`. |
| **Export z Instagramu** | nejbohatší historie. Nastavení → Stáhnout své informace, formát JSON. Přijde e-mailem, ZIP hodí do `_inbox/`. Nabídni to i tomu, kdo má Beo, protože sahá dál do minulosti. |
| Starší nahrávky a videa | do `_inbox/`, přepsat, zdestilovat. |
| Web, prodejní stránka, newsletter | text do `ja/texty/`, je to zdroj hlasu. |
| Poznámky v Notionu nebo Obsidianu | zkopírovat do `_inbox/`. |

Po nasátí **v tomhle pořadí**:

1. `/beyond:destilace` nad tím, co přibylo,
2. `/beyond:hlas` — vyrobí `ja/hlas.md`,
3. **ukaž mu tři pravidla z jeho style guidu a zeptej se, jestli sedí.**
   Když řekne, že ne, oprav to hned. Style guide, se kterým nesouhlasí,
   je horší než žádný.

Když nemá vůbec nic, řekni to na rovinu: brain bude první dva týdny chudý.
Navrhni nejmenší krok, tedy export z Instagramu, protože ten má každý
a je hotový za pět minut.

---

## Na konci

Dopiš `.beyond/stav.md` a ukaž mu **tři věci, které může udělat hned**:

- `/beyond:napad [téma]` — co už k tématu má a nepoužil,
- `/beyond:dira` — o čem mluví pořád a neudělal o tom obsah,
- `/beyond:sync` — stáhnout nové cally a zpracovat inbox.

Drž konec krátký. Po patnácti minutách rozhovoru nikdo nečte odstavce.

## Co má běžet samo

Tohle se **zeptej, neodbývej odkazem na příkaz**. Kdo si to nenastaví teď,
nenastaví si to nikdy a brain mu za měsíc zastará.

Zeptej se na dvě věci, v tomhle pořadí:

1. **Co má běžet samo.** Tři možnosti, klidně jen jedna nebo žádná:
   stahování callů z Fathomu (zadarmo, obyčejný skript), večerní zpracování
   inboxu a destilace (jede přes model, stojí tokeny), týdenní přehled
   (taky přes model). Řekni tu cenu rovnou, ať se rozhoduje s informací.
2. **V kolik.** U každé zvolené úlohy se zeptej na denní dobu a nabídni
   návrh, ať nemusí vymýšlet. Nedávej celé hodiny, 6:47 je lepší než 7:00.

Pak to rovnou zapni přes skill `automatika`, který zná přepínače
instalátoru i to, co je potřeba ověřit předem (hlavně že prázdný
`FATHOM_API_KEY` znamená úlohu, co poběží naprázdno).

Když řekne, že nic, je to v pořádku. Zapiš do `.beyond/stav.md`, že si to
nepřál, a jdi dál. Změnit si to může kdykoli přes `/beyond:automatika`.

## Záloha

Až úplně na konec, jednou větou: chce zálohu na GitHub? Bez ní je smazaná
složka konec a historie taky. Když chce, založ git repo, přidej
`.gitignore` z šablony a proveď ho přes `gh repo create` jako **privátní**.
Když `gh` nemá nebo nechce, doporuč Obsidian Sync, iCloud nebo Time Machine
a jdi dál. **Netlač.**
