# INP PROJEKT 1, FIT VUT 2022

_Prvý projekt (procesor s Brainfuck-like ISA) z predmetu Návrh počítačových systémov (INP), tretí semester bakalárskeho štúdia BIT na FIT VUT/BUT, ak.rok 2022/2023_

🔒 **Aktívny súkromný repozitár — nezverejňovať!**

<img align="right" width="55%" src='https://github.com/Onegenimasu/VUT-FIT-INP2022-projekt1/raw/main/fsm.png' />

Hodnotenie: ?? / ??<br>（?）

Zadanie: [ZADANI.md](ZADANI.md), originál [MOODLE PDF](https://moodle.vut.cz/pluginfile.php/508722/mod_resource/content/1/project1.pdf)

### TODO List

- [x] `login.b` program na výpis loginu
- [x] Spojazniť _fitkit-build_
- [X] Vyčarovať `cpu.vhd`
  - [X] PC, PTR, CNT, MX
  - [X] FSM logic
    - [X] model
    - [X] implementation base
    - [X] test cpu.test_reset
  - [X] instruction noop
  - [X] instruction 0x00 – null
  - [X] instruction 0x2B – +
    - [X] test cpu.test_increment
  - [X] instruction 0x2D – -
    - [X] test cpu.test_decrement
  - [X] instruction 0x3C – <
  - [X] instruction 0x3E – >
    - [X] test cpu.test_move
  - [X] instruction 0x2E – .
    - [X] test cpu.test_print
  - [X] instruction 0x2C – ,
    - [X] test cpu.test_input
  - [X] instruction 0x5B – [
  - [X] instruction 0x5D – ]
    - [X] test cpu.test_while_loop
  - [X] instruction 0x28 – (
  - [X] instruction 0x29 – )
    - [X] test cpu.test_do_loop
  - [X] test cpu.test_login (while loops only)
  - [X] test cpu.test_login (change one loop to do-while)
  - [X] make `login.png` and extract `log.txt`
  - [X] FINAL REVISION & CUSTOM TESTS
    - [X] test cpu.test_custom_while_nested
    - [X] test cpu.test_custom_do_nested
- [ ] ⏰ Deadline 13.11. 23:59:59
- [ ] ⏰ Hodnotenie
