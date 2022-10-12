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
BEGIN

END behavioral;