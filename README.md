# INP PROJEKT 1, FIT VUT 2022

_První projekt (procesor s Brainfuck-like ISA) z předmětu Návrh počítačových systémů (INP), třetí semestr bakalářského studia BIT na FIT VUT/BUT, ak.rok 2022/2023_

🔒 **Aktivní soukromý repozitář — nezveřejňovat!**

<img align="right" width="33%" src='https://sketchviz.com/@Onegenimasu/d427531c9d97a9dbc5894b9d81472712/470347528d7f5c89de48fc7ce996af4e04ddc944.sketchy.png' />

Hodnocení: ?? / ??<br>(??)

Zadání: ??

### TODO List

- [x] `login.b` program na výpis loginu
- [x] Spojeznit _fitkit-build_
- [ ] Nějáké kouzlo s `cpu.vhd`
  - [ ] PC, PTR, CNT
  - [ ] FSM, IREG, IREG_DEC
  - [ ] instruction noop
  - [ ] instruction 0x00 – null
    - [ ] test cpu.test_reset
  - [ ] instruction 0x2B – +
    - [ ] test cpu.test_increment
  - [ ] instruction 0x2D – -
    - [ ] test cpu.test_decrement
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
