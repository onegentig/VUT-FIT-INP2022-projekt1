# INP PROJEKT 1, FIT VUT 2022

*První projekt (procesor s Brainfuck-like ISA) z předmětu Návrh počítačových systémů (INP), třetí semestr bakalářského studia BIT na FIT VUT/BUT, ak.rok 2022/2023*

🔒 **Aktivní soukromý repozitář — nezveřejňovat!**

Hodnocení: ?? / ??<br>(??)

Zadání: ??

### TODO List

- [X] `login.b` program na výpis loginu
- [X] Spojeznit *fitkit-build*
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