# INP PROJEKT 1, FIT VUT 2022

_První projekt (procesor s Brainfuck-like ISA) z předmětu Návrh počítačových systémů (INP), třetí semestr bakalářského studia BIT na FIT VUT/BUT, ak.rok 2022/2023_

🔒 **Aktivní soukromý repozitář — nezveřejňovat!**

<img align="right" width="55%" src='https://github.com/Onegenimasu/VUT-FIT-INP2022-projekt1/raw/main/fsm.png' />

Hodnocení: ?? / ??<br>(??)

Zadání: ??

### TODO List

- [x] `login.b` program na výpis loginu
- [x] Spojeznit _fitkit-build_
- [ ] Nějáké kouzlo s `cpu.vhd`
  - [X] PC, PTR, CNT, MX
  - [ ] FSM
    - [X] model
    - [X] implementation base
    - [X] test cpu.test_reset
  - [X] instruction noop
  - [X] instruction 0x00 – null
  - [X] instruction 0x2B – +
    - [X] test cpu.test_increment
  - [X] instruction 0x2D – -
    - [X] test cpu.test_decrement
  - [ ] instruction 0x3C – <
  - [ ] instruction 0x3E – >
    - [ ] test cpu.test_move
  - [ ] instruction 0x2E – .
    - [ ] test cpu.test_print
  - [ ] instruction 0x2C – ,
    - [ ] test cpu.test_input
  - [ ] instruction 0x5B – [
  - [ ] instruction 0x5D – ]
    - [ ] test cpu.test_while_loop
  - [ ] instruction 0x28 – ()
  - [ ] instruction 0x29 – )
    - [ ] test cpu.test_do_loop
  - [ ] (final boss) test cpu.test_login
- [ ] ⏰ Deadline 13.11.
- [ ] ⏰ Hodnocení
