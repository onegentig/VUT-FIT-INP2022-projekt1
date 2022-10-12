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
  SIGNAL CNT_ONE    : STD_LOGIC;
  SIGNAL CNT_INC    : STD_LOGIC;
  SIGNAL CNT_DEC    : STD_LOGIC;
  -- Helper signals
  SIGNAL MX1_sel    : STD_LOGIC;
  SIGNAL MX2_sel    : STD_LOGIC;
  SIGNAL RDATA_ZERO : STD_LOGIC;
  -- IREG (instruction register) and instruction decoder
  TYPE t_instr IS (halt, inc, dec, ptr_inc, ptr_dec, output, input, wloop_begin, wloop_end, dloop_begin, dloop_end);
  SIGNAL IREG     : STD_LOGIC_VECTOR(15 DOWNTO 0);
  SIGNAL IREG_DEC : t_instr;
  -- FSM (finite state machine)
  TYPE t_state IS (start, fetch, decode, ex_inc, ex_dec, ex_ptr_inc, ex_ptr_dec, ex_output, ex_input, ex_wloop_begin, ex_wloop_end, ex_dloop_begin, ex_dloop_end, halt);
  SIGNAL PSTATE : t_state;
  SIGNAL NSTATE : t_state;
BEGIN

END behavioral;