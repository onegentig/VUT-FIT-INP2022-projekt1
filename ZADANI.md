# INP — Projekt 1 : Procesor s jednoduchou inštrukční sadou

- [INP — Projekt 1 : Procesor s jednoduchou inštrukční sadou](#inp--projekt-1--procesor-s-jednoduchou-inštrukční-sadou)
  - [Činnost procesoru bfISA](#činnost-procesoru-bfisa)
    - [Mikrokontrolér](#mikrokontrolér)
    - [Doplňující teorie](#doplňující-teorie)
  - [Testovací prostředí](#testovací-prostředí)
    - [Spuštění testovacího prostředí](#spuštění-testovacího-prostředí)
  - [Úkoly](#úkoly)
  - [Odevzdání](#odevzdání)
    - [Hodnocení](#hodnocení)

*(originál: [MOODLE](https://moodle.vut.cz/pluginfile.php/508722/mod_resource/content/1/project1.pdf))*

> **Datum zadání:** *10.10.2022*
> 
> **Datum odevzdání:** *13.11.2022 23:59*
> 
> **Forma odezdání:** *IS VUT, 4 soubory*
> 
> **Max. počet bodů:** *23*

Cílem tohoto projektu je implementovat pomocí VHDL **procesor**, který bude schopen vykonávat program napsaný v supersetu ezoterického jazyka [**Brainfuck**](https://esolangs.org/wiki/Brainfuck) - jedná se o výpočetně úplnou sadu ačkoliv používa pouze osm příkazů.

## Činnost procesoru bfISA

Jazyk používá příkazy kódované pomocí 8-bitových znaků, které bude procesor zpracovávat přímo. Program pro tento procesor bude sestávat ze sekvence desíti příkazú rozšířené verzi jazyku Brainfuck (založeno na Brainlove):


| **Příkaz** | **Kód** | **Význam**                     | **C-Ekvivalent** |
|:----------:|:-------:|:------------------------------:|:----------------:|
| >          | 0x3E    | inkrementace hodnoty ukazatele | ptr += 1         |
| <          | 0x3C    | dekrementace hodnoty ukazatele | ptr -= 1         |
| +          | 0x2B    | inkrementace hodnoty buňky     | *ptr += 1        |
| -          | 0x2D    | dekrementace hodnoty buňky     | *ptr -= 1        |
| [          | 0x5B    | začátek while cyklu            | while (*ptr) {   |
| ]          | 0x5D    | konec while cyklu              | ... }            |
| (          | 0x28    | začátek do-while cyklu         | do {             |
| )          | 0x29    | konec do-while cyklu           | } while (*ptr)   |
| .          | 0x2E    | vytiskni hodnotu buňky         | putchar(*ptr)    |
| ,          | 0x2C    | načti hodnotu do buňky         | *ptr = getchar() |
| null       | 0x00    | zastav vykonávaní programu     | return           |

Vykonávaní programu začína první instrukcí a končí po dosažení konce sekvence (ASCII znak 0). Program i data jsou uložena ve stejné paměti mající kapacitu 8192 8-bitových položek. Program je uložený od adresy 0 a může být vykonávan nelineárne. Data jsou uloženy od adresy 4096 (0x1000) a obsah paměti je inicializován na hodnotu 0. Pro přístup do paměti se používa ukazatel (ptr), který se může posouvat doleva (instrukce `<`) nebo doprava (instrukce `>`) - paměť je tedy chápána jako kruhový buffer unsigned 8-bit integerů, teda posun doleva (`<`) z adresy 0x1000 posune ukazatele na adresu 0x1FFF.

V případe příkazů manipulujících s ukazatelem - teda [, ], ( a ) - je zapotřebí detekovat odpovídajúcí závorkou. Po resetu paměti bude ukazatel ukazovat na adresu 0x1000.

### Mikrokontrolér

Procesor je nutné doplnit o paměť programu a dat o celkové kapacitě 8 kB a I/O rozhraní na načítání a vypisování dat. 

* Vstup řešte maticovou klávesnicí - jakmile procesor narazí na instrukci načtení hodnoty (op.kód `0x2C`), vykonávaní se pozastaví dokud nebude stisknuto tlačítko na klávesnici. Tlačítka * a # interpretujte jako konec řádku (ASCII hodnota 10).
* Výstup řešte pomocí LCD displeje, kam se postupně vypisujú znaky. Posun kurzoru na displeji by byl řešen automaticky.

Pro usnadnění vývoje máte připraveno prostředí emulujíci výše uvedené periférie a sadu základních testů.

### Doplňující teorie

*(určeno těm, kteří doposud netuší jak procesor naimplementovat)*

![Obr.2: Blokové schéma mikrokontroleru](https://i.imgur.com/7voHnQ1.png)

Obecně platí, že procesor se skládá z datové cesty (obsahující registry), ALU apod. a řídící cesty obsahující **automat** (*FSM* - *finite state machine*).

Abychom mohli vykonávat program, obsahuje datová cesta tři registry (čítače) s možností inkrementace a dekrementace. Registr PC slouží jako programový čítač (t.j. ukazatel do paměti programu), registr PTR jako ukazatel do paměti dat a registr CNT slouží ke korektnímu určení odpovídajícího začátku/konce cyklů (while a do-while), a to počítáním otevíracích / uzavíracích závorek, viz. popis instrukční sady. Mimo to datová cesta obsahuje multiplexor MX1, pomocí kretého lze během čtení z paměti definovat, zda-li se jedná o adresu programu nebo adresu dat; multiplexor MX2, který určuje hodnotu zapisovanou do paměti. Zapsat je možné buď hodnotu načtenou ze vstupu, hodnotu v aktuální bunce sníženou o 1, hodnotu aktuální buňky zvýšenou o 1 nebo hodnotu získanou při posledním čtení z paměti. V případě, že se rozhodnete neimplementovat podporu vnořených while cyklů, můžete registr CNT ignorovat.

Všechny řídící signály jsou ovládány automatem, tak jak je uvedeno ve schématu. V prvním kroku implementujte registry (konstrukce process) a multiplexory (dataflow popis), poté postupujte od jednodušších instrukcí ke složitejším. Implementaci smyček si ponechte až na závěr; korektní činnost ověřte pomocí simulace a přiložených či vlastních testů.

Nevíte-li jak implementovat automat pomocí VHDL, podívejte se do materiálů k cvičením INP. Jako návod pro implementaci by měl posloužit pseudokód v tabulce výše. Máte-li s implementací potíže, vytvořte jednodušší verzi automatú, který nepodporuje vnořené smyčky.

<details>
<summary>Pseudokódy</summary>

**Výchozí stav**

```crystal
PC <- 0
PTR <- 0x1000
CNT <- 0
TMP <- 0x1000
```

**>**

```crystal
PTR <- 0x1000 + (PTR + 1) % 0x1000
PC <- PC + 1
```

**<**

```crystal
PTR <- 0x1000 + (PTR - 1) % 0x1000
PC <- PC + 1
```

**+**

```crystal
DATA_RDATA <- MEM[PTR]
MEM[PTR] <- DATA_RDATA + 1
PC <- PC + 1
```

**-**

```crystal
DATA_RDATA <- MEM[PTR]
MEM[PTR] <- DATA_RDATA - 1
PC <- PC + 1
```

**.**

```crystal
while (OUT_BUSY) {}
OUT_DATA <- MEM[PTR]
PC <- PC + 1
```

**,**

```crystal
IN_REQ <- 1
while (!IN_VLD) {}
MEM[PTR] <- IN_DATA
PC <- PC + 1
```

**[**

```crystal
PC <- PC + 1
if (MEM[PTR] == 0)
    CNT <- 1
    while (CNT != 0)
        c <- MEM[PC]
        if (c == '[')
            CNT <- CNT + 1
        elsif (c == ']')
            CNT <- CNT - 1
        PC <- PC + 1
```

**]**

```crystal
if (MEM[PTR] == 0)
    PC <- PC + 1
else {
    CNT <- 1
    PC <- PC - 1
    while (CNT != 0)
        c <- MEM[PC]
        if (c == ']')
            CNT <- CNT + 1
        elsif (c == '[')
            CNT <- CNT - 1

        if (CNT == 0)
            PC <- PC + 1
        else
            PC <- PC - 1
```

**null**

```crystal
PC <- PC
```

*( ( a ) nutné vymyslet, inspirace viz. [ a ] )*

-----

</details>

## Testovací prostředí

Součástí zadání je testovací prostředí, které Vám umožnuje na základní úrovni ověřit korektní činnost vašeho kódu (pomocí *behaviorálni simulace*). K ověření se používa [GHDL](https://github.com/ghdl/ghdl) a simulátor [Questa](https://www.intel.com/content/www/us/en/software/programmable/quartus-prime/questa-edition.html). Testovací prostředí spouštějte na stroji `fitkut-build.fit.vutbr.cz`, kde již je k dispozici veškerý softvér. Pro připojení je nutné použít [VPN FIT](https://www.fit.vut.cz/units/cvt/net/vpn.php) nebo se připojovat přes `merlin.fit.vutbr.cz`. Také je třeba pro vzdálený přenos obrazu vytunelovat protokol X11 (Linux: `ssh -X xlogin00@fitkit-build.fit.vutbr.cz`; Windows: pomocí *Xming X Server* a *Putty*, víc info na MOODLE).

**POZOR!** Testy nejsou kompletní ani komplexní. Jestli budete kód tvořit čistě skrze *test-driven development*, není zaručeno, že dostanete plný počet bodů, i když všechno bude svítit zeleně. V souboru `cpu.py` můžete dopsat vlastní testy - do existujících testů není dovoleno zasahovat.

### Spuštění testovacího prostředí

**Stažení zadání a inicializace simulačního prostředí**

```bash
$ mkdir inp22-projekt1
$ cd inp22-projekt1
$ python3 -m venv env
$ curl https://www.fit.vutbr.cz/~vasicek/inp22/zadani.zip | jar xv
$ . env/bin/activate
$ pip install -r zadani/requirements.txt
```

**Aktivace prostředí a spuštění automatických testů**

```bash
$ cd inp22-projekt1
$ . env/bin/activate
$ cd zadani/test
$ make
```

**Spuštění konkrétního testu**

```bash
$ cd zadani/test
$ TESTCASE=test_reset make
```

**Spuštění simulátoru pro konkrétní test**

```bash
$ cd zadani/test
$ TESTCASE=test_reset make questa
```

## Úkoly

1. **Seznamte se s jazykem Brainfuck** : Obsah souboru `login.b` obsahuje program v jazyce Brainfuck, který vypíše řetězec "xlogin01" - skopírujte obsah tohoto souboru do [debuggeru](https://www.fit.vutbr.cz/~vasicek/inp22/) a sledujte průběh programu. Vytvořte program tisknoucí Váš login.
2. **Seznamte se s testovacím prostředím `fitkit-build`** : Dostaňte se na stroj `fitkit-build` a spusťte testovací prostředí pomocí příkazů `make` (všechny testy, samozřejmě, neprojdou).
3. **Doplňte `cpu.vhd` o vaši syntetizovatelnou implementaci CPU** : Rozhraní procesoru je pevně dané a skládá se z čtyř skupin signálů:
    * *`synchronizační rozhraní`* - tvoří signály **`CLK`** (hodinový sync. signál), **`RESET`** (async. nulovací signál, nastavuje stav procesoru PTR=0 a PC=0) a **`EN`** (povolovací signál, který dovoluje procesoru vykonávat program od adresy 0 s každou vzestupnou hranou hodinového signálu).
    * *`rozhraní pro data, program a paměť`* - rozhraní je synchronní a tvoří jej tři datové a dva řídící signály. Signál **`DATA_ADDR`** (13 bit) slouží k adresaci konkrétní buňky paměti; signál **`DATA_RDATA`** (8 bit) obsahuje hodnotu buňky na adrese `DATA_ADDR`; signál **`DATA_WDATA`** (8 bit) obsahuje hodnotu, která se má zapsat do `DATA_ADDR`; řídící sigál **`DATA_EN`** slouží jako povolovací signál pro čtení a zápis do paměti; řídící signál **`DATA_RDWR`** slouží jako přepínač mezi čtením (0) a zápisem (1) do paměti.
    * *`vstupní rozhraní`* - při požadavku o data procesor nastaví signál `IN_REQ` (*input request*) a čeká, dokud signál **`IN_VLD`** (*input valid*) není 1. V tomto okamžiku může procesor přečíst signál **`IN_DATA`**, který obsahuje ASCII hodnotu načteného znaku.
    * *`výstupní rozhraní`* - při požadavku na zápis dat procesor nejdřív skontroluje, jestli **`OUT_BUSY`** je 0 (pokud je 1, procesor čeká), pak inicializuje signál **`OUT_DATA`** zapisovanou ASCII hodnotou, a na jeden hodinový takt nastaví signál **`OUT_WE`** (*povolení zápisu*) na 1.

**Přejmenování názvu identifikátorů, změna pořadí bloků či modifikace komentářů není považováno za autorské dílo a na řešení bude nahlíženo jako na plagiát!!!**

## Odevzdání

Do [IS VUT](https://www.vut.cz/studis/student.phtml?sn=zadani_odevzdani&registrace_zadani_id=886004&apid=231004) odevzdejte **4 soubory** (NE archiv):

1. `login.b` - program v jazyce Brainfuck, který vypíše Váš login
2. `cpu.vhd` - VHDL kód procesoru
3. `log.txt` - report z automatických testů získaný příkazem `make > log.txt`
4. `<login>.png` - screenshot ze simulace vykonávaní programu login.b, co je test `TESTCASE=test_login make questa`, zachycující stav signálů v okamžik zápisu posledního a předposledního znaku na výstup; není nutné uvádět všechny signály detailně, avšak na obrázku by měl býv vidět stav automatu, CLK, OUT_WE, OUT_DATA, dále by mělo být znát, že procesor narazil na instrukci HALT, signál CLK bude mít barvu *Orange* a signál OUT_DATA bude přepnut do režimu výpisu ASCII (položka Radis ve vlastnostech signálů); vyznačte na obrázku hodinové hrany, kdy je vystaven požadavek na zapsání předposledního a posledního znaku na výstup, a také hodinové hrany, kdy je vystaven požadaven ke zpracování instrukce HALT.

### Hodnocení

Za splněníní bodu 3 (implementace procesoru) lze získat až 17 bodů. Pokud implementace nepodporuje vnořené cykly, lze získat maximálně 12 bodů.

Odevzdání po termínu je penaltizováno bodovou srážkou 10 bodů za každý den zpoždění.

Pokud bude odhaleno plagiátorství nebo nepovolená spolupráce, projekt bude hodnocen 0 body, neudělením zápočtu a případným dalším adekvátním postihem dle disciplinárního řádu VUT.
