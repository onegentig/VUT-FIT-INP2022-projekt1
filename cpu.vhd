-- cpu.vhd: Simple 8-bit CPU (BrainFuck interpreter)
-- Copyright (C) 2022 Brno University of Technology,
--                    Faculty of Information Technology
-- Author: Onegenimasu <https://github.com/Onegenimasu>
--
LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.std_logic_arith.ALL;
USE ieee.std_logic_unsigned.ALL;

-- ----------------------------------------------------------------------------
--                        Entity declaration
-- ----------------------------------------------------------------------------
ENTITY cpu IS
  PORT (
    CLK        : IN STD_LOGIC;                      -- hodinovy signal
    RESET      : IN STD_LOGIC;                      -- asynchronni reset procesoru
    EN         : IN STD_LOGIC;                      -- povoleni cinnosti procesoru

    -- synchronni pamet RAM
    DATA_ADDR  : OUT STD_LOGIC_VECTOR(12 DOWNTO 0); -- adresa do pameti
    DATA_WDATA : OUT STD_LOGIC_VECTOR(7 DOWNTO 0);  -- mem[DATA_ADDR] <- DATA_WDATA pokud DATA_EN='1'
    DATA_RDATA : IN STD_LOGIC_VECTOR(7 DOWNTO 0);   -- DATA_RDATA <- ram[DATA_ADDR] pokud DATA_EN='1'
    DATA_RDWR  : OUT STD_LOGIC;                     -- cteni (0) / zapis (1)
    DATA_EN    : OUT STD_LOGIC;                     -- povoleni cinnosti

    -- vstupni port
    IN_DATA    : IN STD_LOGIC_VECTOR(7 DOWNTO 0);   -- IN_DATA <- stav klavesnice pokud IN_VLD='1' a IN_REQ='1'
    IN_VLD     : IN STD_LOGIC;                      -- data platna
    IN_REQ     : OUT STD_LOGIC;                     -- pozadavek na vstup data

    -- vystupni port
    OUT_DATA   : OUT STD_LOGIC_VECTOR(7 DOWNTO 0);  -- zapisovana data
    OUT_BUSY   : IN STD_LOGIC;                      -- LCD je zaneprazdnen (1), nelze zapisovat
    OUT_WE     : OUT STD_LOGIC                      -- LCD <- OUT_DATA pokud OUT_WE='1' a OUT_BUSY='0'
  );
END cpu;
-- ----------------------------------------------------------------------------
--                      Architecture declaration
-- ----------------------------------------------------------------------------
ARCHITECTURE behavioral OF cpu IS
  -- PC (programové počítadlo)
  SIGNAL PC       : STD_LOGIC_VECTOR(11 DOWNTO 0);
  SIGNAL PC_INC   : STD_LOGIC;
  SIGNAL PC_DEC   : STD_LOGIC;
  -- PTR (ukazateľ do pamäte dát)
  SIGNAL PTR      : STD_LOGIC_VECTOR(11 DOWNTO 0);
  SIGNAL PTR_INC  : STD_LOGIC;
  SIGNAL PTR_DEC  : STD_LOGIC;
  -- CNT (počítadlo cyklov)
  SIGNAL CNT      : STD_LOGIC_VECTOR(7 DOWNTO 0);
  SIGNAL CNT_INC  : STD_LOGIC;
  SIGNAL CNT_DEC  : STD_LOGIC;
  SIGNAL CNT_LOAD : STD_LOGIC;
  -- Pomocné signály
  SIGNAL MX1_SEL  : STD_LOGIC;
  SIGNAL MX2_SEL  : STD_LOGIC_VECTOR(1 DOWNTO 0);
  SIGNAL CNT_ZERO : STD_LOGIC;
  -- FSM (konečný automat)
  TYPE t_state IS (idle, fetch, decode,
    ex_inc_r, ex_inc_w,
    ex_dec_r, ex_dec_w,
    ex_lmov, ex_rmov,
    ex_print_r, ex_print_out,
    ex_read_await, ex_read_w,
    ex_whilebeg_r, ex_whilebeg_cmp, ex_whilebeg_jmp, ex_whilebeg_skip, ex_whilebeg_cnt,
    ex_whileend_r, ex_whileend_cmp, ex_whileend_jmp, ex_whileend_ret, ex_whileend_cnt,
    ex_dobeg,
    ex_doend_r, ex_doend_cmp, ex_doend_jmp, ex_doend_ret, ex_doend_cnt,
    ex_noop, halt);
  SIGNAL PSTATE                    : t_state := idle;
  SIGNAL NSTATE                    : t_state;
  ATTRIBUTE fsm_encoding           : STRING;
  ATTRIBUTE fsm_encoding OF PSTATE : SIGNAL IS "sequential";
  ATTRIBUTE fsm_encoding OF NSTATE : SIGNAL IS "sequential";
BEGIN
  -- PC (programové počítadlo)
  PROCESS_PC : PROCESS (CLK, RESET)
  BEGIN
    IF (RESET = '1') THEN
      PC <= (OTHERS => '0');
    ELSIF (rising_edge(CLK)) THEN
      IF (PC_INC = '1') THEN
        PC <= PC + 1;
      ELSIF (PC_DEC = '1') THEN
        PC <= PC - 1;
      END IF;
    END IF;
  END PROCESS;

  -- PTR (ukazateľ do pamäte dát)
  PROCESS_PTR : PROCESS (CLK, RESET)
  BEGIN
    IF (RESET = '1') THEN
      PTR <= (OTHERS => '0');
    ELSIF (rising_edge(CLK)) THEN
      IF (PTR_INC = '1') THEN
        PTR <= PTR + 1;
      ELSIF (PTR_DEC = '1') THEN
        PTR <= PTR - 1;
      END IF;
    END IF;
  END PROCESS;

  -- CNT (počítadlo cyklov)
  PROCESS_CNT : PROCESS (CLK, RESET)
  BEGIN
    IF (RESET = '1') THEN
      CNT <= (OTHERS => '0');
    ELSIF (rising_edge(CLK)) THEN
      IF (CNT_INC = '1') THEN
        CNT <= CNT + 1;
      ELSIF (CNT_DEC = '1') THEN
        CNT <= CNT - 1;
      ELSIF (CNT_LOAD = '1') THEN
        CNT <= X"01";
      END IF;
    END IF;
  END PROCESS;
  -- CNT_ZERO (CNT ?= 0)
  PROCESS_CNTZERO : PROCESS (CLK, RESET)
  BEGIN
    IF (RESET = '1') THEN
      CNT_ZERO <= '1';
    ELSIF (rising_edge(CLK)) THEN
      IF (CNT = X"00") THEN
        CNT_ZERO <= '1';
      ELSE
        CNT_ZERO <= '0';
      END IF;
    END IF;
  END PROCESS;

  -- MX1 (programová (0) alebo dátová (1) adresa v pamäti)
  MX1 : PROCESS (PC, PTR, MX1_SEL)
  BEGIN
    CASE MX1_SEL IS
      WHEN '0'    => DATA_ADDR <= '0' & PC;
      WHEN '1'    => DATA_ADDR <= '1' & PTR;
      WHEN OTHERS => NULL;
    END CASE;
  END PROCESS;

  -- MX2 (hodnota na zápis do pamäti)
  MX2 : PROCESS (IN_DATA, DATA_RDATA, MX2_SEL)
  BEGIN
    CASE MX2_SEL IS
      WHEN "00"   => DATA_WDATA <= IN_DATA;
      WHEN "01"   => DATA_WDATA <= DATA_RDATA;
      WHEN "10"   => DATA_WDATA <= DATA_RDATA - 1;
      WHEN "11"   => DATA_WDATA <= DATA_RDATA + 1;
      WHEN OTHERS => NULL;
    END CASE;
  END PROCESS;

  -- KONEČNÝ AUTOMAT
  -- Present state logic
  FSM_PSTATE : PROCESS (CLK, RESET)
  BEGIN
    IF (RESET = '1') THEN
      PSTATE <= idle;
    ELSIF (rising_edge(CLK)) THEN
      PSTATE <= NSTATE;
    END IF;
  END PROCESS;

  -- Next state logic; output logic
  FSM_NSTATE : PROCESS (PSTATE, IN_VLD, OUT_BUSY, DATA_RDATA, CNT_ZERO, EN)
  BEGIN
    -- Východzí stav
    DATA_EN   <= '0';
    DATA_RDWR <= '0';
    IN_REQ    <= '0';
    OUT_WE    <= '0';
    OUT_DATA  <= X"00";
    PC_INC    <= '0';
    PC_DEC    <= '0';
    PTR_INC   <= '0';
    PTR_DEC   <= '0';
    CNT_INC   <= '0';
    CNT_DEC   <= '0';
    CNT_LOAD  <= '0';
    MX1_SEL   <= '0';
    MX2_SEL   <= "01";

    CASE PSTATE IS
        -- IDLE (východzí stav procesora)
      WHEN idle =>
        IF (EN = '1') THEN
          NSTATE <= fetch;
        ELSE
          NSTATE <= idle;
        END IF;

        -- FETCH (načítanie následujúcej inštrukcie z procesora)
      WHEN fetch =>
        IF (EN = '1') THEN
          NSTATE    <= decode;
          MX1_SEL   <= '0'; -- programova pamat
          DATA_RDWR <= '0'; -- citanie z pamate
          DATA_EN   <= '1'; -- povolenie pamate
        ELSE
          NSTATE <= idle;
        END IF;

        -- DECODE (dekódovanie inštrukcie)
      WHEN decode =>
        CASE (DATA_RDATA) IS
          WHEN X"00"  => NSTATE  <= halt;
          WHEN X"2B"  => NSTATE  <= ex_inc_r;
          WHEN X"2D"  => NSTATE  <= ex_dec_r;
          WHEN X"3E"  => NSTATE  <= ex_lmov;
          WHEN X"3C"  => NSTATE  <= ex_rmov;
          WHEN X"2E"  => NSTATE  <= ex_print_r;
          WHEN X"2C"  => NSTATE  <= ex_read_await;
          WHEN X"5B"  => NSTATE  <= ex_whilebeg_r;
          WHEN X"5D"  => NSTATE  <= ex_whileend_r;
          WHEN X"28"  => NSTATE  <= ex_dobeg;
          WHEN X"29"  => NSTATE  <= ex_doend_r;
          WHEN OTHERS => NSTATE <= ex_noop;
        END CASE;

        -- NOOP (žiadna operácia)
      WHEN ex_noop =>
        NSTATE <= fetch;

        -- HALT (nekonečný cyklus, efektívne zastavenie procesora)
      WHEN halt =>
        NSTATE <= halt;

        -- INC (inkrementácia hodnoty)
        -- takt 1 - načítanie hodnoty aktuálnej bunky
      WHEN ex_inc_r =>
        PC_INC    <= '1'; -- inkrementácia programovej adresy
        MX1_SEL   <= '1'; -- dátová pamäť
        DATA_RDWR <= '0'; -- čítanie z pamäte
        DATA_EN   <= '1'; -- povolenie pamäte
        NSTATE    <= ex_inc_w;
        -- takt 2 - zápis inkrementovanej hodnoty do pamäte
      WHEN ex_inc_w =>
        MX1_SEL   <= '1';  -- dátová pamäť
        MX2_SEL   <= "11"; -- inkrementácia RDATA
        DATA_RDWR <= '1';  -- zápis do pamäte
        DATA_EN   <= '1';  -- povolenie pamäte
        NSTATE    <= fetch;

        -- DEC (dekrementácia hodnoty)
        -- takt 1 - načítanie hodnoty aktuálnej bunky
      WHEN ex_dec_r =>
        PC_INC    <= '1'; -- inkrementácia programovej adresy
        MX1_SEL   <= '1'; -- dátová pamäť
        DATA_RDWR <= '0'; -- čítanie z pamäte
        DATA_EN   <= '1'; -- povolenie pamäte
        NSTATE    <= ex_dec_w;
        -- takt 2 - zápis dekrementovanej hodnoty do pamäte
      WHEN ex_dec_w =>
        MX1_SEL   <= '1';  -- dátová pamäť
        MX2_SEL   <= "10"; -- dekrementácia RDATA
        DATA_RDWR <= '1';  -- zápis do pamäte
        DATA_EN   <= '1';  -- povolenie pamäte
        NSTATE    <= fetch;

        -- LMOV (posun doľava; inkrementácia ukazovateľa)
      WHEN ex_lmov =>
        PC_INC  <= '1'; -- inkrementácia programovej adresy
        PTR_INC <= '1'; -- inkrementácia ukazovateľa
        NSTATE  <= fetch;

        -- RMOV (posun doprava; dekrementácia ukazovateľa)
      WHEN ex_rmov =>
        PC_INC  <= '1'; -- inkrementácia programovej adresy
        PTR_DEC <= '1'; -- dekrementácia ukazovateľa
        NSTATE  <= fetch;

        -- PRINT (výpis hodnoty)
        -- takt 1 - načítanie hodnoty aktuálnej bunky
      WHEN ex_print_r =>
        PC_INC    <= '1'; -- inkrementácia programovej adresy
        MX1_SEL   <= '1'; -- dátová pamäť
        DATA_RDWR <= '0'; -- čítanie z pamäte
        DATA_EN   <= '1'; -- povolenie pamäte
        NSTATE    <= ex_print_out;
        -- takt 2 - čakanie na povolenie výstupu a následný výpis hodnoty
      WHEN ex_print_out =>
        IF (OUT_BUSY = '1') THEN
          NSTATE <= ex_print_out;
        ELSE
          OUT_WE   <= '1';        -- povolenie vystupu
          OUT_DATA <= DATA_RDATA; -- vypis hodnoty
          NSTATE   <= fetch;
        END IF;

        -- READ (načítanie hodnoty do bunky)
        -- takt 1 - požiadavka o vstup (a čakanie na IN_VLD)
      WHEN ex_read_await =>
        IN_REQ <= '1'; -- požiadavka o vstup
        IF (IN_VLD = '1') THEN
          NSTATE <= ex_read_w;
        ELSE
          NSTATE <= ex_read_await; -- čakanie na vstup
        END IF;
        -- takt 2 - zápis načítanej hodnoty do bunky
      WHEN ex_read_w =>
        PC_INC    <= '1';  -- inkrementácia programovej adresy
        MX1_SEL   <= '1';  -- dátová pamäť
        MX2_SEL   <= "00"; -- načítaná hodnota -> WDATA
        DATA_RDWR <= '1';  -- zápis do pamäte
        DATA_EN   <= '1';  -- povolenie pamäte
        NSTATE    <= fetch;

        -- WHILE_BEGIN (začiatok while cyklu)
        -- takt 1 - načítanie hodnoty aktuálnej bunky
      WHEN ex_whilebeg_r =>
        PC_INC    <= '1'; -- inkrementácia programovej adresy
        MX1_SEL   <= '1'; -- dátová pamäť
        DATA_RDWR <= '0'; -- čítanie z pamäte
        DATA_EN   <= '1'; -- povolenie pamäte
        NSTATE    <= ex_whilebeg_cmp;
        -- takt 2 - porovnanie hodnoty s nulou; ak je nula, skok na koniec cyklu
      WHEN ex_whilebeg_cmp =>
        IF (DATA_RDATA = X"00") THEN
          CNT_INC   <= '1';
          MX1_SEL   <= '0'; -- programová pamäť
          DATA_RDWR <= '0'; -- čítanie z pamäte
          DATA_EN   <= '1'; -- povolenie pamäte
          NSTATE    <= ex_whilebeg_jmp;
        ELSE
          NSTATE <= fetch;
        END IF;
        -- takt 3 - prečítanie následujúcej inštrukcie
      WHEN ex_whilebeg_jmp =>
        MX1_SEL   <= '0'; -- programová pamäť
        DATA_RDWR <= '0'; -- čítanie z pamäte
        DATA_EN   <= '1'; -- povolenie pamäte
        NSTATE    <= ex_whilebeg_skip;
        -- takt 4 - zmena počítadla cyklov (prispôsobenie vnoreným cyklom)
      WHEN ex_whilebeg_skip =>
        IF (DATA_RDATA = X"5B") THEN
          CNT_INC <= '1';
        ELSIF (DATA_RDATA = X"5D") THEN
          CNT_DEC <= '1';
        END IF;
        NSTATE <= ex_whilebeg_cnt;
        -- takt 5 - prechod na ďalšiu inštrukciu a pokračovanie preskakovania, ak treba
      WHEN ex_whilebeg_cnt =>
        PC_INC <= '1';
        IF (CNT_ZERO = '1') THEN
          NSTATE <= fetch;
        ELSE
          NSTATE <= ex_whilebeg_jmp;
        END IF;

        -- WHILE_END (koniec while cyklu)
        -- takt 1 - načítanie hodnoty aktuálnej bunky
      WHEN ex_whileend_r =>
        MX1_SEL   <= '1'; -- dátová pamäť
        DATA_RDWR <= '0'; -- čítanie z pamäte
        DATA_EN   <= '1'; -- povolenie pamäte
        NSTATE    <= ex_whileend_cmp;
        -- takt 2 - porovnanie hodnoty s nulou; ak nie je nula, skok na zaciatok cyklu
      WHEN ex_whileend_cmp =>
        IF (DATA_RDATA = X"00") THEN
          PC_INC <= '1';
          NSTATE <= fetch;
        ELSE
          CNT_INC <= '1';
          PC_DEC  <= '1';
          NSTATE  <= ex_whileend_jmp;
        END IF;
        -- takt 3 - prečítanie následujúcej inštrukcie
      WHEN ex_whileend_jmp =>
        MX1_SEL   <= '0'; -- programová pamäť
        DATA_RDWR <= '0'; -- čítanie z pamäte
        DATA_EN   <= '1'; -- povolenie pamäte
        NSTATE    <= ex_whileend_ret;
        -- takt 4 - zmena počítadla cyklov (prispôsobenie vnoreným cyklom)
      WHEN ex_whileend_ret =>
        IF (DATA_RDATA = X"5D") THEN
          CNT_INC <= '1';
        ELSIF (DATA_RDATA = X"5B") THEN
          CNT_DEC <= '1';
        END IF;
        NSTATE <= ex_whileend_cnt;
        -- takt 5 - prechod na ďalšiu (predchádzajúcu) inštrukciu a pokračovanie preskakovania, ak treba
      WHEN ex_whileend_cnt =>
        IF (CNT_ZERO = '1') THEN
          PC_INC <= '1';
          NSTATE <= fetch;
        ELSE
          PC_DEC <= '1';
          NSTATE <= ex_whileend_jmp;
        END IF;

        -- DO_BEGIN (začiatok do cyklu)
      WHEN ex_dobeg =>
        PC_INC <= '1';
        NSTATE <= fetch;

        -- DO_END (koniec do cyklu)
        -- takt 1 - načítanie hodnoty aktuálnej bunky
      WHEN ex_doend_r =>
        MX1_SEL   <= '1'; -- dátová pamäť
        DATA_RDWR <= '0'; -- čítanie z pamäte
        DATA_EN   <= '1'; -- povolenie pamäte
        NSTATE    <= ex_doend_cmp;
        -- takt 2 - porovnanie hodnoty s nulou; ak nie je nula, skok na zaciatok cyklu
      WHEN ex_doend_cmp =>
        IF (DATA_RDATA = X"00") THEN
          PC_INC <= '1';
          NSTATE <= fetch;
        ELSE
          CNT_INC <= '1';
          PC_DEC  <= '1';
          NSTATE  <= ex_doend_jmp;
        END IF;
        -- takt 3 - prečítanie následujúcej inštrukcie
      WHEN ex_doend_jmp =>
        MX1_SEL   <= '0'; -- programová pamäť
        DATA_RDWR <= '0'; -- čítanie z pamäte
        DATA_EN   <= '1'; -- povolenie pamäte
        NSTATE    <= ex_doend_ret;
        -- takt 4 - zmena počítadla cyklov (prispôsobenie vnoreným cyklom)
      WHEN ex_doend_ret =>
        IF (DATA_RDATA = X"28") THEN
          CNT_DEC <= '1';
        ELSIF (DATA_RDATA = X"29") THEN
          CNT_INC <= '1';
        END IF;
        NSTATE <= ex_doend_cnt;
        -- takt 5 - prechod na ďalšiu (predchádzajúcu) inštrukciu a pokračovanie preskakovania, ak treba
      WHEN ex_doend_cnt =>
        IF (CNT_ZERO = '1') THEN
          PC_INC <= '1';
          NSTATE <= fetch;
        ELSE
          PC_DEC <= '1';
          NSTATE <= ex_doend_jmp;
        END IF;

        -- (fallthrough, nemalo by nastať)
      WHEN OTHERS =>
        NSTATE <= idle;
    END CASE;
  END PROCESS;
END behavioral;