# Beyond Brain — plugin do Clauda

Druhý mozek pro tvůrce obsahu. Postaví ti na disku vlastní brain, stahuje
cally z Fathomu, přepisuje hlasovky a videa **lokálně a zadarmo**, destiluje
je do znalostí a dělá z nich nápady, story a plán publikací.

Běží lokálně, jako Obsidian. Bez serveru, bez n8n, bez povinného GitHubu.

## Instalace

```
/plugin marketplace add StepanKakes/second-brain-plugin
/plugin install beyond@beyond
```

Potom **otevři Clauda v prázdné složce**, kde má brain vzniknout. Plugin se
ozve sám: řekne, že je nainstalovaný, a nabídne nastavení. Nebo napiš rovnou
`/beyond:init`.

Jde to i z lokální složky, bez GitHubu:

```
/plugin marketplace add C:/cesta/k/beyond-plugin
/plugin install beyond@beyond
```

## Nastavení

`/beyond:init` je průvodce v pěti etapách a trvá zhruba 15 minut:

1. **Kde brain vznikne.** Vedle Obsidian vaultu nebo kamkoli chceš.
2. **Kdo jsi.** Šest otázek, jedna po druhé, ne dotazník. Co děláš, komu,
   co lidem opakuješ pořád dokola, v čem jdeš proti proudu.
3. **Napojení.** Fathom na cally, Beo na Instagram. Obojí volitelné.
4. **Přepisy a inbox.** Stáhne whisper a napojí složku, do které budeš
   z telefonu házet hlasovky.
5. **Nasaje tvůj obsah a naučí se tvůj hlas.** Nejdůležitější etapa.

Můžeš to kdykoli přerušit a příště pokračovat tam, kde jsi skončil.

## Jak se učí mluvit jako ty

`/beyond:hlas` z tvého vlastního obsahu vyrobí `ja/hlas.md`: která slova
používáš, která nepoužiješ nikdy, jak dlouhé máš věty, jak otvíráš a jak
končíš. Ke každému pravidlu příklad z tvého textu. Všechno, co plugin
napíše, se pak řídí tímhle souborem.

Učí se to dál za provozu. **Když opravíš text, který ti napsal, zapíše si
co jsi změnil a proč.** Za pár měsíců je tahle část přesnější než
cokoli, co se dá vyčíst z prvního nastavení.

## Co to umí

| Příkaz | Co dělá |
|---|---|
| `/beyond:init` | Založí brain a nasaje, co už máš |
| `/beyond:sync` | Stáhne cally z Fathomu, zpracuje inbox |
| `/beyond:destilace` | Z přepisů udělá znalosti |
| `/beyond:hlas` | Z tvého obsahu vyrobí tvůj style guide |
| `/beyond:napad [téma]` | Co k tématu máš a co jsi z toho nepoužil |
| `/beyond:postoj [téma]` | Jaký na to máš názor, tvými slovy |
| `/beyond:dira` | O čem mluvíš pořád a neudělal jsi o tom obsah |
| `/beyond:story [téma]` | Draft story sekvence z tvého materiálu |
| `/beyond:kalendar` | Plán publikací |
| `/beyond:tyden` | Týdenní přehled |
| `/beyond:obsah-import` | Natáhne tvůj publikovaný obsah z Instagramu |
| `/beyond:automatika` | Zapne noční běh na tvém počítači |

## Co potřebuješ

- **Předplatné Clauda.** Jediná povinná položka, protože přemýšlení jede
  přes model.
- **Fathom API klíč**, když chceš stahovat cally sám. Bez něj plugin funguje.
- **Zhruba 2 GB na disku** na model pro přepisy. Jednorázově, stáhne to
  `/beyond:init`.

Přepisy jedou lokálně přes whisper.cpp, takže **nestojí nic a nic neodchází
z tvého počítače.** Gemini klíč je volitelný a potřebuješ ho, jen když chceš
rozlišovat mluvčí nebo popsat, co je ve videu vidět.

## Jak to běží samo

1. **Při otevření.** Když otevřeš Clauda ve složce brainu, řekne ti, co čeká
   na zpracování. Nulová konfigurace.
2. **V noci.** `/beyond:automatika` zaregistruje úlohu do Task Scheduleru
   (Windows) nebo launchd (macOS). Ráno stažení callů, večer destilace.
   Běží jen když je počítač zapnutý.

## Jak dostat věci z telefonu

`/beyond:init` ti nabídne, že `_inbox/` bude ležet ve tvojí Google Drive,
iCloud nebo Dropbox složce. Pak stačí z telefonu hodit hlasovku nebo fotku
do té složky a objeví se v brainu.

**Do sync složky patří jenom `_inbox/`**, ne celý brain. Jinak by vznikaly
konfliktní kopie souborů, do kterých zapisuje Claude.

## Brain je tvůj

Plugin a tvoje data jsou dvě oddělené věci. Plugin je tenhle repozitář
a obsahuje jen mechaniku. **Tvůj brain je složka na tvém disku a nikdo
jiný do ní nevidí.** Když opravíme skill, dostaneš opravu, aniž bys musel
cokoli mergovat do svých dat.

Funguje to i jako Obsidian vault: markdown, wikilinky, žádný zámek.
Kdykoli plugin odinstaluješ, složka zůstane a je čitelná bez něj.

## Stav

Verze 0.1.0. Co ještě není hotové:

- **Beo napojení je hotové a ověřené** (03.09.2026). Když máš Beo, dostaneš
  ke svým příspěvkům permalink, views, reach a počet leadů, a z permalinku
  se reel stáhne a přepíše lokálně. Viz `/beyond:obsah-import`, cesta 1.
- **SessionStart hook** zatím jen připomene Claudovi, ať zkontroluje stav
  brainu. Stahování na pozadí bez modelu přijde, až bude ověřené na Windows
  i macOS.
- Otestované zatím na Windows. Skripty pro macOS jsou napsané, ale neproběhly.
