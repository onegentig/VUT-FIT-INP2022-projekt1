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
  SIGNAL PC         : STD_LOGIC_VECTOR(12 DOWNTO 0);
  SIGNAL PC_INC     : STD_LOGIC;
  SIGNAL PC_DEC     : STD_LOGIC;
  -- PTR (pointer to data in memory)
  SIGNAL PTR        : STD_LOGIC_VECTOR(12 DOWNTO 0);
  SIGNAL PTR_INC    : STD_LOGIC;
  SIGNAL PTR_DEC    : STD_LOGIC;
  -- CNT (counter for loops)
  SIGNAL CNT        : STD_LOGIC_VECTOR(7 DOWNTO 0);
  SIGNAL CNT_INC    : STD_LOGIC;
  SIGNAL CNT_DEC    : STD_LOGIC;
  -- Helper signals
  SIGNAL MX1_SEL    : STD_LOGIC;
  SIGNAL MX2_SEL    : STD_LOGIC_VECTOR(1 DOWNTO 0);
  SIGNAL CNT_ZERO   : STD_LOGIC;
  SIGNAL RDATA_ZERO : STD_LOGIC;
  -- FSM (finite state machine)
  TYPE t_state IS (idle, fetch, decode, ex_ptr_inc, ex_ptr_dec, ex_val_inc, ex_val_dec, ex_print, ex_read, ex_wloop_beg, ex_wloop_end, ex_dloop_beg, ex_dloop_end, ex_noop, halt);
  SIGNAL PSTATE : t_state;
  SIGNAL NSTATE : t_state;
BEGIN
  -- PC (program counter)
  pc : PROCESS (PC_INC, PC_DEC, RESET, CLK)
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
  ptr : PROCESS (PTR_INC, PTR_DEC, RESET, CLK)
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
  cnt : PROCESS (CNT_INC, CNT_DEC, RESET, CLK)
  BEGIN
    IF (RESET = '1') THEN
      CNT      <= (OTHERS => '0');
      CNT_ZERO <= '1';
    ELSIF (rising_edge(CLK)) THEN
      IF (CNT_INC = '1') THEN
        CNT <= CNT + 1;
      ELSIF (CNT_DEC = '1') THEN
        CNT <= CNT - 1;
      END IF;
    END IF;
  END PROCESS;
  -- CNT_ZERO (log.1 if CNT == 0, else log.0)
  cnt_zero : PROCESS (CNT, RESET, CLK)
  BEGIN
    IF (RESET = '1') THEN
      CNT_ZERO <= '1';
    ELSIF (rising_edge(CLK)) THEN
      CASE (CNT = (OTHERS => '0'))
        WHEN TRUE           => CNT_ZERO   <= '1';
        WHEN OTHERS         => CNT_ZERO <= '0';
      END CASE;
    END IF;
  END PROCESS;

  -- MX1 (program or data address in memory)
  mx1 : PROCESS (PC, PTR, MX1_SEL)
  BEGIN
    CASE MX1_SEL IS
      WHEN '0'    => DATA_ADDR <= PC;
      WHEN '1'    => DATA_ADDR <= PTR;
      WHEN OTHERS => NULL;
    END CASE;
  END PROCESS;

  -- MX2 (value to write to memory)
  mx2 : PROCESS (IN_DATA, DATA_RDATA, MX2_SEL)
  BEGIN
    CASE MX2_SEL IS
      WHEN "00"   => DATA_WDATA <= IN_DATA;
      WHEN "01"   => DATA_WDATA <= DATA_RDATA;
      WHEN "10"   => DATA_WDATA <= DATA_RDATA - 1;
      WHEN "11"   => DATA_WDATA <= DATA_RDATA + 1;
      WHEN OTHERS => NULL;
    END CASE;
  END PROCESS;
END behavioral;