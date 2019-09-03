-- INP - 1. projekt
-- Autor - Katerina Fortova (xforto00)

-- pouzite knihovny:
library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.std_logic_arith.all;
use IEEE.std_logic_unsigned.all;

-- popis rozhrani obvodu:
entity ledc8x8 is
port (
      RESET : in std_logic;
      SMCLK : in std_logic;
      ROW : out std_logic_vector (0 to 7);
      LED : out std_logic_vector (0 to 7));
end ledc8x8;

-- telo programu:

architecture main of ledc8x8 is

    -- pouzite signaly:

    signal counter_count : std_logic_vector(11 downto 0) := (others => '0');
    signal change_count : std_logic_vector(20 downto 0) := (others => '0');
    signal ce : std_logic;
    signal situation : std_logic_vector(1 downto 0) := "00";
    signal leds_on : std_logic_vector(7 downto 0);
    signal row_count : std_logic_vector(7 downto 0);

begin

    -- citac:

    counter: process (SMCLK, RESET) is
    begin
          if (RESET = '1') then
            counter_count <= (others => '0');
          elsif rising_edge(SMCLK) then
            counter_count <= counter_count + 1;
            if counter_count  = "111000010000" then -- SMCLK/256/8 - 1 s, doba, za kterou se maji prostridat 4 stavy - K, nic, F, nic
              ce <= '1';
              counter_count <= (others => '0');
            else
              ce <= '0';
            end if;
          end if;

    end process counter;

    -- delicka:

    change: process (RESET, SMCLK) is
    begin
          if (RESET = '1') then
            situation <= (others => '0');
            change_count <= (others => '0');
          elsif rising_edge(SMCLK) then
            change_count <= change_count + 1;
            if change_count  = "111000010000000000000" then -- SMCLK/4 - 0,25 s, doba za kterou mam prejit na novy stav, mam 4 stavy
                situation <= situation + 1; -- inkrementace, prechod na situaci, co nasleduje
                change_count <= (others => '0');
            end if;
          end if;

    end process change;

    -- rotacni registr:

    rot_reg: process (RESET, ce, SMCLK) is
    begin
          if (RESET = '1') then
            row_count <= "10000000";
          elsif ((SMCLK'event) and (SMCLK = '1') and (ce = '1')) then
            row_count <= row_count(0) & row_count(7 downto 1);
          end if;

    end process rot_reg;

    -- dekoder radku:

    row_dec: process(row_count, situation)
    begin
      -- pismeno K:
        if situation = "00" then
          case row_count is -- pismeno K
              when "10000000" => leds_on <= "11011011";
              when "01000000" => leds_on <= "11010111";
              when "00100000" => leds_on <= "11001111";
              when "00010000" => leds_on <= "11001111";
              when "00001000" => leds_on <= "11001111";
              when "00000100" => leds_on <= "11010111";
              when "00000010" => leds_on <= "11011011";
              when "00000001" => leds_on <= "11011101";
              when others => leds_on <= "11111111";
          end case;
        end if;
      -- nic:
        if situation = "01" then
          case row_count is
              when "10000000" => leds_on <= "11111111";
              when "01000000" => leds_on <= "11111111";
              when "00100000" => leds_on <= "11111111";
              when "00010000" => leds_on <= "11111111";
              when "00001000" => leds_on <= "11111111";
              when "00000100" => leds_on <= "11111111";
              when "00000010" => leds_on <= "11111111";
              when "00000001" => leds_on <= "11111111";
              when others => leds_on <= "11111111";
          end case;
        end if;
      -- pismeno F:
         if situation = "10" then
          case row_count is
              when "10000000" => leds_on <= "11000011";
              when "01000000" => leds_on <= "11011111";
              when "00100000" => leds_on <= "11000011";
              when "00010000" => leds_on <= "11011111";
              when "00001000" => leds_on <= "11011111";
              when "00000100" => leds_on <= "11011111";
              when "00000010" => leds_on <= "11011111";
              when "00000001" => leds_on <= "11011111";
              when others => leds_on <= "11111111";
          end case;
        end if;
      -- nic:
        if situation = "11" then
          case row_count is
              when "10000000" => leds_on <= "11111111";
              when "01000000" => leds_on <= "11111111";
              when "00100000" => leds_on <= "11111111";
              when "00010000" => leds_on <= "11111111";
              when "00001000" => leds_on <= "11111111";
              when "00000100" => leds_on <= "11111111";
              when "00000010" => leds_on <= "11111111";
              when "00000001" => leds_on <= "11111111";
              when others => leds_on <= "11111111";
            end case;
         end if;

   end process row_dec;

   LED <= leds_on;
   ROW <= row_count;

end main;
