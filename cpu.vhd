-- cpu.vhd: Simple 8-bit CPU (BrainFuck interpreter)
-- @author: Onegen Something <xkrame00@vutbr.cz>
--
library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;

-- ----------------------------------------------------------------------------
--                        Entity declaration
-- ----------------------------------------------------------------------------
entity cpu is
     port (
          CLK   : in std_logic;                            -- hodinovy signal
          RESET : in std_logic;                            -- asynchronni reset procesoru
          EN    : in std_logic;                            -- povoleni cinnosti procesoru

          -- synchronni pamet RAM
          DATA_ADDR  : out std_logic_vector(12 downto 0);  -- adresa do pameti
          DATA_WDATA : out std_logic_vector(7 downto 0);   -- mem[DATA_ADDR] <- DATA_WDATA pokud DATA_EN='1'
          DATA_RDATA : in  std_logic_vector(7 downto 0);   -- DATA_RDATA <- ram[DATA_ADDR] pokud DATA_EN='1'
          DATA_RDWR  : out std_logic;                      -- cteni (0) / zapis (1)
          DATA_EN    : out std_logic;                      -- povoleni cinnosti

          -- vstupni port
          IN_DATA : in  std_logic_vector(7 downto 0);      -- IN_DATA <- stav klavesnice pokud IN_VLD='1' a IN_REQ='1'
          IN_VLD  : in  std_logic;                         -- data platna
          IN_REQ  : out std_logic;                         -- pozadavek na vstup data

          -- vystupni port
          OUT_DATA : out std_logic_vector(7 downto 0);     -- zapisovana data
          OUT_BUSY : in  std_logic;                        -- LCD je zaneprazdnen (1), nelze zapisovat
          OUT_WE   : out std_logic                         -- LCD <- OUT_DATA pokud OUT_WE='1' a OUT_BUSY='0'
     );
end cpu;
-- ----------------------------------------------------------------------------
--                      Architecture declaration
-- ----------------------------------------------------------------------------
architecture behavioral of cpu is
     -- PC (programové počítadlo)
     signal PC       : std_logic_vector(11 downto 0);
     signal PC_INC   : std_logic;
     signal PC_DEC   : std_logic;
     -- PTR (ukazateľ do pamäte dát)
     signal PTR      : std_logic_vector(11 downto 0);
     signal PTR_INC  : std_logic;
     signal PTR_DEC  : std_logic;
     -- CNT (počítadlo cyklov)
     signal CNT      : std_logic_vector(7 downto 0);
     signal CNT_INC  : std_logic;
     signal CNT_DEC  : std_logic;
     signal CNT_LOAD : std_logic;
     -- Pomocné signály
     signal MX1_SEL  : std_logic;
     signal MX2_SEL  : std_logic_vector(1 downto 0);
     signal CNT_ZERO : std_logic;
     -- FSM (konečný automat)
     type t_state is (idle, fetch, decode,
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
     signal PSTATE                    : t_state := idle;
     signal NSTATE                    : t_state;
     attribute fsm_encoding           : string;
     attribute fsm_encoding of PSTATE : signal is "sequential";
     attribute fsm_encoding of NSTATE : signal is "sequential";
begin
     -- PC (programové počítadlo)
     PROCESS_PC : process (CLK, RESET)
     begin
          if (RESET = '1') then
               PC <= (others => '0');
          elsif (rising_edge(CLK)) then
               if (PC_INC = '1') then
                    PC <= PC + 1;
               elsif (PC_DEC = '1') then
                    PC <= PC - 1;
               end if;
          end if;
     end process;

     -- PTR (ukazateľ do pamäte dát)
     PROCESS_PTR : process (CLK, RESET)
     begin
          if (RESET = '1') then
               PTR <= (others => '0');
          elsif (rising_edge(CLK)) then
               if (PTR_INC = '1') then
                    PTR <= PTR + 1;
               elsif (PTR_DEC = '1') then
                    PTR <= PTR - 1;
               end if;
          end if;
     end process;

     -- CNT (počítadlo cyklov)
     PROCESS_CNT : process (CLK, RESET)
     begin
          if (RESET = '1') then
               CNT <= (others => '0');
          elsif (rising_edge(CLK)) then
               if (CNT_LOAD = '1') then
                    CNT <= X"01";
               elsif (CNT_INC = '1') then
                    CNT <= CNT + 1;
               elsif (CNT_DEC = '1') then
                    CNT <= CNT - 1;
               end if;
          end if;
     end process;
     -- CNT_ZERO (CNT ?= 0)
     PROCESS_CNTZERO : process (CNT)
     begin
          if (CNT = X"00") then
               CNT_ZERO <= '1';
          else
               CNT_ZERO <= '0';
          end if;
     end process;

     -- MX1 (programová (0) alebo dátová (1) adresa v pamäti)
     MX1 : process (PC, PTR, MX1_SEL)
     begin
          case MX1_SEL is
               when '0'    => DATA_ADDR <= '0' & PC;
               when '1'    => DATA_ADDR <= '1' & PTR;
               when others => null;
          end case;
     end process;

     -- MX2 (hodnota na zápis do pamäti)
     MX2 : process (IN_DATA, DATA_RDATA, MX2_SEL)
     begin
          case MX2_SEL is
               when "00"   => DATA_WDATA <= IN_DATA;
               when "01"   => DATA_WDATA <= DATA_RDATA;
               when "10"   => DATA_WDATA <= DATA_RDATA - 1;
               when "11"   => DATA_WDATA <= DATA_RDATA + 1;
               when others => null;
          end case;
     end process;

     -- KONEČNÝ AUTOMAT
     -- Present state logic
     FSM_PSTATE : process (CLK, RESET)
     begin
          if (RESET = '1') then
               PSTATE <= idle;
          elsif (rising_edge(CLK)) then
               PSTATE <= NSTATE;
          end if;
     end process;

     -- Next state logic; output logic
     FSM_NSTATE : process (PSTATE, IN_VLD, OUT_BUSY, DATA_RDATA, CNT_ZERO, EN)
     begin
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

          case PSTATE is
               -- IDLE (východzí stav procesora)
               when idle =>
                    if (EN = '1') then
                         NSTATE <= fetch;
                    else
                         NSTATE <= idle;
                    end if;

               -- FETCH (načítanie následujúcej inštrukcie z procesora)
               when fetch =>
                    if (EN = '1') then
                         NSTATE    <= decode;
                         MX1_SEL   <= '0';  -- programova pamat
                         DATA_RDWR <= '0';  -- citanie z pamate
                         DATA_EN   <= '1';  -- povolenie pamate
                    else
                         NSTATE <= idle;
                    end if;

               -- DECODE (dekódovanie inštrukcie)
               when decode =>
                    case (DATA_RDATA) is
                         when X"00"  => NSTATE <= halt;
                         when X"2B"  => NSTATE <= ex_inc_r;
                         when X"2D"  => NSTATE <= ex_dec_r;
                         when X"3E"  => NSTATE <= ex_lmov;
                         when X"3C"  => NSTATE <= ex_rmov;
                         when X"2E"  => NSTATE <= ex_print_r;
                         when X"2C"  => NSTATE <= ex_read_await;
                         when X"5B"  => NSTATE <= ex_whilebeg_r;
                         when X"5D"  => NSTATE <= ex_whileend_r;
                         when X"28"  => NSTATE <= ex_dobeg;
                         when X"29"  => NSTATE <= ex_doend_r;
                         when others => NSTATE <= ex_noop;
                    end case;

               -- NOOP (žiadna operácia)
               when ex_noop =>
                    PC_INC <= '1';
                    NSTATE <= fetch;

               -- HALT (nekonečný cyklus, efektívne zastavenie procesora)
               when halt =>
                    NSTATE <= halt;

               -- INC (inkrementácia hodnoty)
               -- takt 1 - načítanie hodnoty aktuálnej bunky
               when ex_inc_r =>
                    PC_INC    <= '1';   -- inkrementácia programovej adresy
                    MX1_SEL   <= '1';   -- dátová pamäť
                    DATA_RDWR <= '0';   -- čítanie z pamäte
                    DATA_EN   <= '1';   -- povolenie pamäte
                    NSTATE    <= ex_inc_w;
               -- takt 2 - zápis inkrementovanej hodnoty do pamäte
               when ex_inc_w =>
                    MX1_SEL   <= '1';   -- dátová pamäť
                    MX2_SEL   <= "11";  -- inkrementácia RDATA
                    DATA_RDWR <= '1';   -- zápis do pamäte
                    DATA_EN   <= '1';   -- povolenie pamäte
                    NSTATE    <= fetch;

               -- DEC (dekrementácia hodnoty)
               -- takt 1 - načítanie hodnoty aktuálnej bunky
               when ex_dec_r =>
                    PC_INC    <= '1';   -- inkrementácia programovej adresy
                    MX1_SEL   <= '1';   -- dátová pamäť
                    DATA_RDWR <= '0';   -- čítanie z pamäte
                    DATA_EN   <= '1';   -- povolenie pamäte
                    NSTATE    <= ex_dec_w;
               -- takt 2 - zápis dekrementovanej hodnoty do pamäte
               when ex_dec_w =>
                    MX1_SEL   <= '1';   -- dátová pamäť
                    MX2_SEL   <= "10";  -- dekrementácia RDATA
                    DATA_RDWR <= '1';   -- zápis do pamäte
                    DATA_EN   <= '1';   -- povolenie pamäte
                    NSTATE    <= fetch;

               -- LMOV (posun doľava; inkrementácia ukazovateľa)
               when ex_lmov =>
                    PC_INC  <= '1';     -- inkrementácia programovej adresy
                    PTR_INC <= '1';     -- inkrementácia ukazovateľa
                    NSTATE  <= fetch;

               -- RMOV (posun doprava; dekrementácia ukazovateľa)
               when ex_rmov =>
                    PC_INC  <= '1';     -- inkrementácia programovej adresy
                    PTR_DEC <= '1';     -- dekrementácia ukazovateľa
                    NSTATE  <= fetch;

               -- PRINT (výpis hodnoty)
               -- takt 1 - načítanie hodnoty aktuálnej bunky
               when ex_print_r =>
                    PC_INC    <= '1';   -- inkrementácia programovej adresy
                    MX1_SEL   <= '1';   -- dátová pamäť
                    DATA_RDWR <= '0';   -- čítanie z pamäte
                    DATA_EN   <= '1';   -- povolenie pamäte
                    NSTATE    <= ex_print_out;
               -- takt 2 - čakanie na povolenie výstupu a následný výpis hodnoty
               when ex_print_out =>
                    if (OUT_BUSY = '1') then
                         NSTATE <= ex_print_out;
                    else
                         OUT_WE   <= '1';         -- povolenie vystupu
                         OUT_DATA <= DATA_RDATA;  -- vypis hodnoty
                         NSTATE   <= fetch;
                    end if;

               -- READ (načítanie hodnoty do bunky)
               -- takt 1 - požiadavka o vstup (a čakanie na IN_VLD)
               when ex_read_await =>
                    IN_REQ <= '1';      -- požiadavka o vstup
                    if (IN_VLD = '1') then
                         NSTATE <= ex_read_w;
                    else
                         NSTATE <= ex_read_await;  -- čakanie na vstup
                    end if;
               -- takt 2 - zápis načítanej hodnoty do bunky
               when ex_read_w =>
                    PC_INC    <= '1';   -- inkrementácia programovej adresy
                    MX1_SEL   <= '1';   -- dátová pamäť
                    MX2_SEL   <= "00";  -- načítaná hodnota -> WDATA
                    DATA_RDWR <= '1';   -- zápis do pamäte
                    DATA_EN   <= '1';   -- povolenie pamäte
                    NSTATE    <= fetch;

               -- WHILE_BEGIN (začiatok while cyklu)
               -- takt 1 - načítanie hodnoty aktuálnej bunky
               when ex_whilebeg_r =>
                    PC_INC    <= '1';       -- inkrementácia programovej adresy
                    MX1_SEL   <= '1';       -- dátová pamäť
                    DATA_RDWR <= '0';       -- čítanie z pamäte
                    DATA_EN   <= '1';       -- povolenie pamäte
                    NSTATE    <= ex_whilebeg_cmp;
               -- takt 2 - porovnanie hodnoty s nulou; ak je nula, skok na koniec cyklu
               when ex_whilebeg_cmp =>
                    if (DATA_RDATA = X"00") then
                         CNT_LOAD  <= '1';
                         MX1_SEL   <= '0';  -- programová pamäť
                         DATA_RDWR <= '0';  -- čítanie z pamäte
                         DATA_EN   <= '1';  -- povolenie pamäte
                         NSTATE    <= ex_whilebeg_jmp;
                    else
                         NSTATE <= fetch;
                    end if;
               -- takt 3 - prečítanie následujúcej inštrukcie
               when ex_whilebeg_jmp =>
                    MX1_SEL   <= '0';       -- programová pamäť
                    DATA_RDWR <= '0';       -- čítanie z pamäte
                    DATA_EN   <= '1';       -- povolenie pamäte
                    NSTATE    <= ex_whilebeg_skip;
               -- takt 4 - zmena počítadla cyklov (prispôsobenie vnoreným cyklom)
               when ex_whilebeg_skip =>
                    if (DATA_RDATA = X"5B") then
                         CNT_INC <= '1';
                    elsif (DATA_RDATA = X"5D") then
                         CNT_DEC <= '1';
                    end if;
                    NSTATE <= ex_whilebeg_cnt;
               -- takt 5 - prechod na ďalšiu inštrukciu a pokračovanie preskakovania, ak treba
               when ex_whilebeg_cnt =>
                    PC_INC <= '1';
                    if (CNT_ZERO = '1') then
                         NSTATE <= fetch;
                    else
                         NSTATE <= ex_whilebeg_jmp;
                    end if;

               -- WHILE_END (koniec while cyklu)
               -- takt 1 - načítanie hodnoty aktuálnej bunky
               when ex_whileend_r =>
                    MX1_SEL   <= '1';   -- dátová pamäť
                    DATA_RDWR <= '0';   -- čítanie z pamäte
                    DATA_EN   <= '1';   -- povolenie pamäte
                    NSTATE    <= ex_whileend_cmp;
               -- takt 2 - porovnanie hodnoty s nulou; ak nie je nula, skok na zaciatok cyklu
               when ex_whileend_cmp =>
                    if (DATA_RDATA = X"00") then
                         PC_INC <= '1';
                         NSTATE <= fetch;
                    else
                         CNT_LOAD <= '1';
                         PC_DEC   <= '1';
                         NSTATE   <= ex_whileend_jmp;
                    end if;
               -- takt 3 - prečítanie následujúcej inštrukcie
               when ex_whileend_jmp =>
                    MX1_SEL   <= '0';   -- programová pamäť
                    DATA_RDWR <= '0';   -- čítanie z pamäte
                    DATA_EN   <= '1';   -- povolenie pamäte
                    NSTATE    <= ex_whileend_ret;
               -- takt 4 - zmena počítadla cyklov (prispôsobenie vnoreným cyklom)
               when ex_whileend_ret =>
                    if (DATA_RDATA = X"5D") then
                         CNT_INC <= '1';
                    elsif (DATA_RDATA = X"5B") then
                         CNT_DEC <= '1';
                    end if;
                    NSTATE <= ex_whileend_cnt;
               -- takt 5 - prechod na ďalšiu (predchádzajúcu) inštrukciu a pokračovanie preskakovania, ak treba
               when ex_whileend_cnt =>
                    if (CNT_ZERO = '1') then
                         PC_INC <= '1';
                         NSTATE <= fetch;
                    else
                         PC_DEC <= '1';
                         NSTATE <= ex_whileend_jmp;
                    end if;

               -- DO_BEGIN (začiatok do cyklu)
               when ex_dobeg =>
                    PC_INC <= '1';
                    NSTATE <= fetch;

               -- DO_END (koniec do cyklu)
               -- takt 1 - načítanie hodnoty aktuálnej bunky
               when ex_doend_r =>
                    MX1_SEL   <= '1';   -- dátová pamäť
                    DATA_RDWR <= '0';   -- čítanie z pamäte
                    DATA_EN   <= '1';   -- povolenie pamäte
                    NSTATE    <= ex_doend_cmp;
               -- takt 2 - porovnanie hodnoty s nulou; ak nie je nula, skok na zaciatok cyklu
               when ex_doend_cmp =>
                    if (DATA_RDATA = X"00") then
                         PC_INC <= '1';
                         NSTATE <= fetch;
                    else
                         CNT_LOAD <= '1';
                         PC_DEC   <= '1';
                         NSTATE   <= ex_doend_jmp;
                    end if;
               -- takt 3 - prečítanie následujúcej inštrukcie
               when ex_doend_jmp =>
                    MX1_SEL   <= '0';   -- programová pamäť
                    DATA_RDWR <= '0';   -- čítanie z pamäte
                    DATA_EN   <= '1';   -- povolenie pamäte
                    NSTATE    <= ex_doend_ret;
               -- takt 4 - zmena počítadla cyklov (prispôsobenie vnoreným cyklom)
               when ex_doend_ret =>
                    if (DATA_RDATA = X"28") then
                         CNT_DEC <= '1';
                    elsif (DATA_RDATA = X"29") then
                         CNT_INC <= '1';
                    end if;
                    NSTATE <= ex_doend_cnt;
               -- takt 5 - prechod na ďalšiu (predchádzajúcu) inštrukciu a pokračovanie preskakovania, ak treba
               when ex_doend_cnt =>
                    if (CNT_ZERO = '1') then
                         PC_INC <= '1';
                         NSTATE <= fetch;
                    else
                         PC_DEC <= '1';
                         NSTATE <= ex_doend_jmp;
                    end if;

               -- (fallthrough, nemalo by nastať)
               when others =>
                    NSTATE <= idle;
          end case;
     end process;
end behavioral;
