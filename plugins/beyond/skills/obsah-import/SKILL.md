---
name: obsah-import
description: Dostane do brainu uzivateluv uz publikovany obsah z Instagramu vcetne prepisu reelu. Pouzij, kdyz rika "natahni muj Instagram", "nacti moje reely", "mam export z Instagramu", "prepis moje videa", "/beyond:obsah-import".
---

# obsah-import

Dostane do brainu to, co už uživatel publikoval. Je to nejrychlejší způsob,
jak z prázdného brainu udělat použitelný, protože rok obsahu je materiál,
který se jinak sbírá měsíce.

Cesty jsou čtyři. **Zjisti nejdřív, jestli má uživatel Beo**, protože pak
je odpověď jasná (cesta 1). Bez Bea nabídni jednu z ostatních, ne všechny
najednou.

## Cesta 1: Beo (nejlepší, když ho uživatel má)

**Ověřeno 03.09.2026 na celém řetězu.** Když má uživatel připojený Beo
konektor, je tohle nejrychlejší a nejúplnější cesta, protože přinese
i čísla, která se jinak nedají získat.

Postup:

1. Zavolej `content_outliers` se `scope: "mine"`. Vrátí ke každému
   příspěvku `permalink`, `views`, `reach`, `likes`, `comments`, `caption`,
   `posted_at`, **a hlavně `leads`**, tedy kolik lidí ten příspěvek přivedl
   do konverzace. To poslední je nejcennější údaj v celém brainu, protože
   spojuje obsah s byznysem, ne s marnivostí.
2. Zapiš každý příspěvek do `obsah/publikovano.md` (datum, typ, popisek,
   permalink) a čísla do `obsah/co-funguje.md`.
3. U reelů, které chceš mít přepsané, předej **permalink** skriptu
   `scripts/transcribe`. Ten si video stáhne přes yt-dlp a přepíše ho
   lokálním whisperem. **U veřejného účtu to funguje bez cookies.**
4. Přepisy do `_raw/`, pak `/beyond:destilace`.

Sekundy až minuty na příspěvek, žádný Meta klíč, žádná appka, protože
autorizaci k Instagramu už jednou proklikl při onboardingu do Bea.

Beo umí i `scope: "creators"`, tedy sledované konkurenty. Na inspiraci
a analýzu cizího obsahu to je legitimní zdroj, ale **cizí obsah nikdy
neukládej do `znalosti/`**, patří do `obsah/napady.md` jako inspirace.
Znalosti jsou jen to, co řekl uživatel sám.

## Cesta 2: Zdrojová videa (default bez Bea)

Uživatel má soubory, ze kterých reely stříhal. Hodí je do `_inbox/`,
`scripts/transcribe` je přepíše, `/beyond:destilace` z nich udělá znalosti.

Nula klíčů, nula nákladů, funguje hned. Chybí jen metriky.

## Cesta 3: Oficiální export z Instagramu (na historii)

**Tohle nabídni při `/beyond:init` každému.** Trvá to pět minut a přinese
to nejvíc.

Postup pro uživatele (řekni mu ho takhle, krok po kroku):

1. Instagram → Nastavení → Centrum účtů → Vaše informace a oprávnění
   → Stáhnout své informace.
2. Vybrat svůj účet, formát **JSON**, rozsah **Celá doba**.
3. Přijde e-mail s odkazem, obvykle do pár hodin.
4. Stažený ZIP hodit do `_inbox/`.

Co s tím uděláš:

- `content/reels.json`, `content/posts_1.json` a `content/stories.json`
  obsahují popisky, datumy a cesty k souborům,
- popisky zapiš do `obsah/publikovano.md` (datum, typ, popisek, cesta
  k souboru), protože právě tenhle soubor krmí `/beyond:dira`,
- popisky jsou zároveň nejlepší vstup pro `/beyond:hlas`,
- videa ze ZIPu přepiš přes `scripts/transcribe` a přepisy dej do `_raw/`.

Velký ZIP zpracovávej **po dávkách**, ne najednou. Po každé dávce zapiš
postup do `.beyond/import-stav.md`, ať se dá pokračovat.

## Cesta 4: yt-dlp s cookies (když nemá zdrojová videa)

Funguje a je zadarmo, ale **řekni uživateli výhrady dřív, než to spustíš**:

- automatizované stahování je proti podmínkám Instagramu,
- při větším objemu si účet vykoleduje omezení,
- cookies po čase vyprší a je potřeba je vyexportovat znovu.

Když s tím rozumí, `scripts/transcribe` má parametr na cookies. Stahuj
pomalu, v malých dávkách, s pauzou mezi položkami. Nikdy nespouštěj stovky
stažení za sebou.

Na cizí obsah (inspirace, konkurence) tohle nepoužívej ve velkém. Jeden
odkaz, na který se chce podívat, je něco jiného než hromadné stahování.

## Metriky

**S Beem (cesta 1) je máš** včetně počtu leadů na příspěvek.

**Bez Bea je nemáš.** Cesty 2 až 4 přinesou obsah a přepisy, ne čísla.
Znamenalo by to Meta appku na každého uživatele, což je na onboarding moc.

Když chce bez Bea vědět, co fungovalo, ať čísla **doplní ručně** do
`obsah/co-funguje.md` u toho, co ho zajímá. Deset ručně doplněných čísel
u obsahu, který ho zajímá, je pro rozhodování cennější než tisíc řádků
automaticky staženého balastu.

## Železné pravidlo

**Nikdy nevymýšlej metriky ani datumy.** Když je nemáš, napiš `n/a`.
Vymyšlené číslo v `obsah/co-funguje.md` je jed, protože podle něj bude
rozhodovat, co točit dál.
