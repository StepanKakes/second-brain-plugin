---
name: destilace
description: Promeni surove prepisy v _raw/ na znalosti ve znalosti/. Pouzij po syncu, kdyz uzivatel rika "zdestiluj to", "zpracuj cally", "co z toho vyslo", "/beyond:destilace", nebo kdyz v _raw/ lezi neco, co jeste neni v ledgeru.
---

# destilace

Chytrá vrstva. Ze surových přepisů dělá znalosti, ze kterých se dá za tři
měsíce vymýšlet obsah.

## Zlaté pravidlo

**Nikdy neukládej celý přepis do znalostí.** Hodinový call má kolem 8 000 slov
a 90 % je šum: pozdravy, technika, opakování. Kdyby se ukládal raw, hledání
by vracelo šum a báze by shnila.

Z hodinového callu vznikne typicky **5 až 15 záznamů**. Když jich máš 40,
ukládáš šum. Když jeden, špatně jsi hledal.

K originálu se dá vždycky vrátit přes cestu ke zdroji, kterou nese každý záznam.

## Osm kategorií

Při čtení aktivně hledej těchhle osm věcí. Všechno ostatní ignoruj.

| # | Kategorie | Kam | Kritérium |
|---|---|---|---|
| 1 | **Názory a postoje** | `znalosti/postoje.md` | Řekl by to veřejně jako svůj postoj? Je to opakovatelné v obsahu? |
| 2 | **Příběhy** | `znalosti/pribehy.md` | Má to začátek, konflikt a pointu? Dá se to vyprávět ve videu? |
| 3 | **Formulace** | `znalosti/formulace.md` | Vymyslel by to copywriter, nebo to řekl on přirozeně? |
| 4 | **Jazyk publika** | `znalosti/jazyk-publika.md` | Je to autentická formulace zákazníka o jeho problému? |
| 5 | **Co funguje v obsahu** | `obsah/co-funguje.md` | Je tam konkrétní obsah plus konkrétní výsledek? |
| 6 | **Rozhodnutí** | `znalosti/rozhodnuti.md` | Změní to, jak byznys funguje nebo co nabízí? |
| 7 | **Nápady** | `obsah/napady.md` | Dalo by se z toho něco vytvořit nebo otestovat? |
| 8 | **Metodika** | `znalosti/metodika.md` | Dal by se podle toho někdo řídit? Má to kroky a pořadí? |

Rozdíl mezi 1, 3 a 8 se plete nejčastěji: **co si myslí** je postoj,
**jak to řekl** je formulace, **co má člověk udělat a v jakém pořadí**
je metodika.

U kategorie 1 zaznamenej i **posuny**: „dřív tvrdil X, teď Y". Báze má
odrážet aktuální myšlení, ne konzervovat minulost.

U kategorií 3 a 4 ukládej **doslovně**. Neuhlazuj gramatiku, síla je
v přirozenosti. Parafráze zabíjí celou hodnotu.

## Formát záznamu

```
### [Krátký vyhledatelný titulek]
- Datum: DD.MM.RRRR
- Zdroj: [co to bylo + cesta k souboru v _raw/]
- Kategorie: [jedna z osmi]
- Kontext: [jedna věta: kdo, jaká situace]

[Destilát. U formulací a jazyka publika doslovné citace v uvozovkách.
U příběhů: situace → zlom → výsledek → pointa.
U rozhodnutí: co + proč + co se od toho čeká.]

- Použito: [prázdné, dokud z toho nevznikne obsah]
- Vzorec: [když se pojí s opakujícím se tématem]
```

Titulek musí být vyhledatelný. „Pain point: dosah bez prodejů" je lepší
než „Poznámka z callu".

## Vzorce

Nejcennější výstup nejsou jednotlivé záznamy, ale **opakování**. Jeden pain
point je poznámka, ten samý pain point popáté je téma na sérii.

Před uložením zkontroluj, jestli podobný záznam už neexistuje:

- **Existuje:** nezakládej duplicitu. Přidej výskyt („+ 16.07.2026, stejná
  formulace") a zvyš počítadlo. Od tří výskytů označ jako **VZOREC**.
- **Neexistuje:** založ nový.

## Postup

1. Vezmi z `_raw/` soubory, které nejsou v ledgeru `.beyond/destilace-stav.md`.
2. **Zpracovávej po jednom souboru.** Ne dávkově. Dlouhý kontext kvalitu kazí
   a při pádu ztratíš všechno.
3. Zapiš záznamy do cílů podle tabulky. Nikam jinam.
4. Do ledgeru zapiš soubor **až když jsou záznamy na disku.**
5. Na konci přidej tři až pět řádků do `cally/digesty.md`: datum, co to bylo,
   hlavní témata, co přibylo.
6. **Když do `znalosti/formulace.md` přibylo víc než deset záznamů,
   nabídni `/beyond:hlas`.** Tolik nového materiálu obvykle znamená,
   že se style guide dá zpřesnit. Nabídni to, nedělej to sám.

## Co neukládat

- Surové přepisy a dlouhé pasáže bez destilace.
- Smalltalk, techniku, logistiku („pošlu ti to mailem").
- Citlivé osobní věci, které s byznysem nesouvisí. Když je osobní kontext
  pro příběh nutný, zobecni ho.
- Pomíjivosti (reakce na aktuální funkci appky).
- Vlastní domněnky vydávané za fakta. Citace je doslovná, tvoje shrnutí je
  označené jako shrnutí. **Nikdy si nedomýšlej, co tím asi myslel.**

## Pojistka proti halucinaci

Když je vstupní soubor prázdný, nečitelný nebo přepis selhal, **nenapiš
záznam.** Napiš, že vstup chybí. Vymyšlený záznam v bázi je horší než
žádný, protože se za tři měsíce tváří jako pravda a nikdo ho nerozezná.

## Kontrola před uložením

1. Doslovnost tam, kde na ní záleží.
2. Zdroj a datum vždycky.
3. Kontext jednou větou.
4. Výjimečná čísla označ jako výjimku, ne jako normu.
5. Duplicity zkontrolované.
6. Záznam přečtitelný za dvacet sekund.

## Když si nejsi jistý

Zeptej se sám sebe: **pomůže tenhle záznam za tři měsíce vymyslet lepší
obsah nebo rozhodnutí?** Když ano, ulož. Když ne, zahoď. Prázdnější
a přesnější báze je vždycky lepší než plná a zašuměná.
