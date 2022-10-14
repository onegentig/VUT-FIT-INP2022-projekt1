-- cpu.vhd: Simple 8-bit CPU (BrainFuck interpreter)
-- Copyright (C) 2022 Brno University of Technology,
--                    Faculty of Information Technology
-- Author: name <login AT stud.fit.vutbr.cz>
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
  -- PC (program counter)
  SIGNAL PC       : STD_LOGIC_VECTOR(11 DOWNTO 0);
  SIGNAL PC_INC   : STD_LOGIC;
  SIGNAL PC_DEC   : STD_LOGIC;
  -- PTR (pointer to data in memory)
  SIGNAL PTR      : STD_LOGIC_VECTOR(11 DOWNTO 0);
  SIGNAL PTR_INC  : STD_LOGIC;
  SIGNAL PTR_DEC  : STD_LOGIC;
  -- CNT (counter for loops)
  SIGNAL CNT      : STD_LOGIC_VECTOR(7 DOWNTO 0);
  SIGNAL CNT_INC  : STD_LOGIC;
  SIGNAL CNT_DEC  : STD_LOGIC;
  -- Helper signals
  SIGNAL MX1_SEL  : STD_LOGIC;
  SIGNAL MX2_SEL  : STD_LOGIC_VECTOR(1 DOWNTO 0);
  SIGNAL CNT_ZERO : STD_LOGIC;
  -- FSM (finite state machine)
  TYPE t_state IS (idle, fetch, decode, ex_inc_r, ex_inc_w, ex_dec_r, ex_dec_w, ex_lmov, ex_rmov, ex_print, ex_read, ex_whilebeg, ex_whileend, ex_dobeg, ex_doend, ex_noop, halt);
  SIGNAL PSTATE                    : t_state := idle;
  SIGNAL NSTATE                    : t_state;
  ATTRIBUTE fsm_encoding           : STRING;
  ATTRIBUTE fsm_encoding OF PSTATE : SIGNAL IS "sequential";
  ATTRIBUTE fsm_encoding OF NSTATE : SIGNAL IS "sequential";
BEGIN
  -- PC (program counter)
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

  -- PTR (pointer to data in memory)
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

  -- CNT (counter for loops)
  PROCESS_CNT : PROCESS (CLK, RESET)
  BEGIN
    IF (RESET = '1') THEN
      CNT <= (OTHERS => '0');
    ELSIF (rising_edge(CLK)) THEN
      IF (CNT_INC = '1') THEN
        CNT <= CNT + 1;
      ELSIF (CNT_DEC = '1') THEN
        CNT <= CNT - 1;
      END IF;
    END IF;
  END PROCESS;
  -- CNT_ZERO (CNT ?= 0 comparator)
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

  -- MX1 (program or data address in memory)
  MX1 : PROCESS (PC, PTR, MX1_SEL)
  BEGIN
    CASE MX1_SEL IS
      WHEN '0'    => DATA_ADDR <= '0' & PC;
      WHEN '1'    => DATA_ADDR <= '1' & PTR;
      WHEN OTHERS => NULL;
    END CASE;
  END PROCESS;

  -- MX2 (value to write to memory)
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

  -- FINITE STATE MACHINE
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
    -- Initial state
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
    MX1_SEL   <= '0';
    MX2_SEL   <= "00";

    CASE PSTATE IS
        -- IDLE (initial processor state)
      WHEN idle =>
        IF (EN = '1') THEN
          NSTATE <= fetch;
        ELSE
          NSTATE <= idle;
        END IF;

        -- FETCH (fetch instruction from memory)
      WHEN fetch =>
        IF (EN = '1') THEN
          NSTATE    <= decode;
          MX1_SEL   <= '0'; -- program memory
          DATA_RDWR <= '0'; -- read from memory
          DATA_EN   <= '1'; -- enable memory
        ELSE
          NSTATE <= idle;
        END IF;

        -- DECODE (decode instruction)
      WHEN decode =>
        CASE (DATA_RDATA) IS
          WHEN X"00"  => NSTATE  <= halt;
          WHEN X"2B"  => NSTATE  <= ex_inc_r;
          WHEN X"2D"  => NSTATE  <= ex_dec_r;
          WHEN X"3E"  => NSTATE  <= ex_lmov;
          WHEN X"3C"  => NSTATE  <= ex_rmov;
          WHEN X"2E"  => NSTATE  <= ex_print;
          WHEN X"2C"  => NSTATE  <= ex_read;
          WHEN X"5B"  => NSTATE  <= ex_whilebeg;
          WHEN X"5D"  => NSTATE  <= ex_whileend;
          WHEN X"28"  => NSTATE  <= ex_dobeg;
          WHEN X"29"  => NSTATE  <= ex_doend;
          WHEN OTHERS => NSTATE <= ex_noop;
        END CASE;

        -- NOOP (No operation)
      WHEN ex_noop =>
        NSTATE <= fetch;

        -- HALT (Enter infinite loop, processor effectively halts)
      WHEN halt =>
        NSTATE <= halt;

        -- INC (Increment value)
        -- tact 1 - read value from memory
      WHEN ex_inc_r =>
        PC_INC    <= '1'; -- increment program counter
        MX1_SEL   <= '1'; -- data memory
        DATA_RDWR <= '0'; -- read memory
        DATA_EN   <= '1'; -- enable memory
        NSTATE    <= ex_inc_w;

        -- tact 2 - increment value
      WHEN ex_inc_w =>
        MX1_SEL   <= '1';  -- data memory
        MX2_SEL   <= "11"; -- increment value
        DATA_RDWR <= '1';  -- write memory
        DATA_EN   <= '1';  -- enable memory
        NSTATE    <= fetch;

        -- DEC (Decrement value)
        -- tact 1 - read value from memory
      WHEN ex_dec_r =>
        PC_INC    <= '1'; -- increment program counter
        MX1_SEL   <= '1'; -- data memory
        DATA_RDWR <= '0'; -- read memory
        DATA_EN   <= '1'; -- enable memory
        NSTATE    <= ex_dec_w;

        -- tact 2 - decrement value
      WHEN ex_dec_w =>
        MX1_SEL   <= '1';  -- data memory
        MX2_SEL   <= "10"; -- decrement value
        DATA_RDWR <= '1';  -- write memory
        DATA_EN   <= '1';  -- enable memory
        NSTATE    <= fetch;

        -- (fallthrough, this should not happen)
      WHEN OTHERS =>
        NSTATE <= idle;
    END CASE;
  END PROCESS;
END behavioral;