-- cpu.vhd: Simple 8-bit CPU (BrainF*ck interpreter)
-- Copyright (C) 2018 Brno University of Technology,
--                    Faculty of Information Technology
-- Author(s): Katerina Fortova (xforto00)
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
   CLK   : in std_logic;  -- hodinovy signal
   RESET : in std_logic;  -- asynchronni reset procesoru
   EN    : in std_logic;  -- povoleni cinnosti procesoru

   -- synchronni pamet ROM
   CODE_ADDR : out std_logic_vector(11 downto 0); -- adresa do pameti
   CODE_DATA : in std_logic_vector(7 downto 0);   -- CODE_DATA <- rom[CODE_ADDR] pokud CODE_EN='1'
   CODE_EN   : out std_logic;                     -- povoleni cinnosti

   -- synchronni pamet RAM
   DATA_ADDR  : out std_logic_vector(9 downto 0); -- adresa do pameti
   DATA_WDATA : out std_logic_vector(7 downto 0); -- mem[DATA_ADDR] <- DATA_WDATA pokud DATA_EN='1'
   DATA_RDATA : in std_logic_vector(7 downto 0);  -- DATA_RDATA <- ram[DATA_ADDR] pokud DATA_EN='1'
   DATA_RDWR  : out std_logic;                    -- cteni z pameti (DATA_RDWR='1') / zapis do pameti (DATA_RDWR='0')
   DATA_EN    : out std_logic;                    -- povoleni cinnosti

   -- vstupni port
   IN_DATA   : in std_logic_vector(7 downto 0);   -- IN_DATA obsahuje stisknuty znak klavesnice pokud IN_VLD='1' a IN_REQ='1'
   IN_VLD    : in std_logic;                      -- data platna pokud IN_VLD='1'
   IN_REQ    : out std_logic;                     -- pozadavek na vstup dat z klavesnice

   -- vystupni port
   OUT_DATA : out  std_logic_vector(7 downto 0);  -- zapisovana data
   OUT_BUSY : in std_logic;                       -- pokud OUT_BUSY='1', LCD je zaneprazdnen, nelze zapisovat,  OUT_WE musi byt '0'
   OUT_WE   : out std_logic                       -- LCD <- OUT_DATA pokud OUT_WE='1' a OUT_BUSY='0'
 );
end cpu;


-- ----------------------------------------------------------------------------
--                      Architecture declaration
-- ----------------------------------------------------------------------------
architecture behavioral of cpu is

    -- instrukce, stavy:

    type fsm_state is (ptr_pointer_increment, ptr_pointer_decrement,
                       ptr_cell_increment, ptr_cell_increment_multiplexer, ptr_cell_decrement, ptr_cell_decrement_multiplexer,
                       while_left_bracket, while_left_bracket2, while_left_bracket3, while_left_bracket4,
                       while_right_bracket, while_right_bracket2, while_right_bracket3, while_right_bracket4, while_right_bracket5,
                       putchar, putchar2,
                       getchar,
                       halt,
                       hexa,
                       jump, jump2, jump3,
                       start,
                       other_state,
                       fsm_instructions);

    signal fsm_decode : fsm_state;
    signal instruction_state : fsm_state;


    -- signaly:
      -- PC:
    signal reg_pc_adress: std_logic_vector(11 downto 0);
    signal reg_pc_increment: std_logic;
    signal reg_pc_decrement: std_logic;
      -- PTR:
    signal reg_ptr_adress: std_logic_vector(9 downto 0);
    signal reg_ptr_increment: std_logic;
    signal reg_ptr_decrement: std_logic;
      -- CNT:
    signal reg_cnt_adress: std_logic_vector(7 downto 0);
    signal reg_cnt_increment: std_logic;
    signal reg_cnt_decrement: std_logic;
      -- multiplexor:
    signal multiplexer: std_logic_vector(1 downto 0);
	  signal multiplexer_change: std_logic_vector(7 downto 0);

begin

 -- zde dopiste vlastni VHDL kod dle blokoveho schema
  -- registr PC - programovy citac:

    reg_pc: process (CLK, RESET, reg_pc_adress, reg_pc_increment, reg_pc_decrement) is
    begin
      if (RESET = '1') then
        reg_pc_adress <= (others => '0');
      elsif rising_edge(CLK) then
        if (reg_pc_increment = '1') then
          reg_pc_adress <= reg_pc_adress + 1;
        elsif (reg_pc_decrement = '1') then
          reg_pc_adress <= reg_pc_adress - 1;
        end if;
      end if;

    end process reg_pc;

    CODE_ADDR <= reg_pc_adress;

    -- registr PTR - ukazatel do pameti dat:

    reg_ptr: process (CLK, RESET, reg_ptr_adress, reg_ptr_increment, reg_ptr_decrement) is
    begin
      if (RESET = '1') then
        reg_ptr_adress <= (others => '0');
      elsif rising_edge(CLK) then
        if (reg_ptr_increment = '1') then
          reg_ptr_adress <= reg_ptr_adress + 1;
        elsif (reg_ptr_decrement = '1') then
          reg_ptr_adress <= reg_ptr_adress - 1;
        end if;
      end if;

    end process reg_ptr;

    DATA_ADDR <= reg_ptr_adress;

    -- registr CNT - pocitani zavorek u cyklu while:

    reg_cnt: process (CLK, RESET, reg_cnt_adress, reg_cnt_increment, reg_cnt_decrement) is
    begin
      if (RESET = '1') then
        reg_cnt_adress <= (others => '0');
      elsif rising_edge(CLK) then
        if (reg_cnt_increment = '1') then
          reg_cnt_adress <= reg_cnt_adress + 1;
        elsif (reg_cnt_decrement = '1') then
          reg_cnt_adress <= reg_cnt_adress - 1;
        end if;
      end if;

    end process reg_cnt;

    -- aktualni stav - logika:

    state_new: process (CLK, RESET)
    begin
      if (RESET = '1') then
		    fsm_decode <= start;
	    elsif rising_edge(CLK) and EN = '1' then
			  fsm_decode <= instruction_state;
	    end if;

    end process state_new;

    -- multiplexor:

    multiplexer_logic: process (IN_DATA, DATA_RDATA, multiplexer, multiplexer_change) is
	  begin
		case (multiplexer) is
			when "00" => DATA_WDATA <= IN_DATA;
			when "01" => DATA_WDATA <= DATA_RDATA + 1;
			when "10" => DATA_WDATA <= DATA_RDATA - 1;
			when "11" => DATA_WDATA <= multiplexer_change;
			when others =>
		end case;

   end process multiplexer_logic;


  -- fsm (konecny automat):

    fsm: process (CODE_DATA, IN_VLD, OUT_BUSY, DATA_RDATA, reg_cnt_adress, fsm_decode) is
    begin

      -- pocatecni inicializace:

      CODE_EN <= '1';
		  DATA_EN <= '0';
      OUT_WE <= '0';
		  IN_REQ <= '0';
      DATA_RDWR <= '0';

      multiplexer <= "00";

      reg_pc_increment <= '0';
      reg_pc_decrement <= '0';
      reg_cnt_increment <= '0';
      reg_cnt_decrement <= '0';
      reg_ptr_increment <= '0';
      reg_ptr_decrement <= '0';



      case fsm_decode is
        when start =>
          CODE_EN <= '1';
          instruction_state <= fsm_instructions;

        -- dekodovani instrukci:

        when fsm_instructions =>
          case (CODE_DATA) is
            when X"3E" => instruction_state <= ptr_pointer_increment;
  					when X"3C" => instruction_state <= ptr_pointer_decrement;
  					when X"2B" => instruction_state <= ptr_cell_increment;
  					when X"2D" => instruction_state <= ptr_cell_decrement;
  					when X"5B" => instruction_state <= while_left_bracket;
  					when X"5D" => instruction_state <= while_right_bracket;
  					when X"2E" => instruction_state <= putchar;
  					when X"2C" => instruction_state <= getchar;
  					when X"23" => instruction_state <= jump;
  					when X"30" => instruction_state <= hexa;
  					when X"31" => instruction_state <= hexa;
  					when X"32" => instruction_state <= hexa;
  					when X"33" => instruction_state <= hexa;
  					when X"34" => instruction_state <= hexa;
  					when X"35" => instruction_state <= hexa;
  					when X"36" => instruction_state <= hexa;
  					when X"37" => instruction_state <= hexa;
  					when X"38" => instruction_state <= hexa;
  					when X"39" => instruction_state <= hexa;
       			when X"41" => instruction_state <= hexa;
  					when X"42" => instruction_state <= hexa;
  					when X"43" => instruction_state <= hexa;
  					when X"44" => instruction_state <= hexa;
  					when X"45" => instruction_state <= hexa;
  					when X"46" => instruction_state <= hexa;
  					when X"00" => instruction_state <= halt;
  					when others => instruction_state <= other_state;
          end case;

--------------------- > ---------------------------------------------------------
        when ptr_pointer_increment =>
          reg_ptr_increment <= '1';
          reg_pc_increment <= '1';
          instruction_state <= start;
--------------------- < ---------------------------------------------------------
        when ptr_pointer_decrement =>
          reg_ptr_decrement <= '1';
          reg_pc_increment <= '1';
          instruction_state <= start;
--------------------- + ---------------------------------------------------------
        when ptr_cell_increment =>
          DATA_EN <= '1';
          DATA_RDWR <= '1';
          instruction_state <= ptr_cell_increment_multiplexer;

        when ptr_cell_increment_multiplexer =>
          multiplexer <= "01";
          DATA_EN <= '1';
          DATA_RDWR <= '0';
          reg_pc_increment <= '1';
          instruction_state <= start;

--------------------- - ---------------------------------------------------------
        when ptr_cell_decrement =>
          DATA_EN <= '1';
          DATA_RDWR <= '1';
          instruction_state <= ptr_cell_decrement_multiplexer;

        when ptr_cell_decrement_multiplexer =>
         multiplexer <= "10";
         DATA_EN <= '1';
         DATA_RDWR <= '0';
         reg_pc_increment <= '1';
         instruction_state <= start;

--------------------- . ---------------------------------------------------------
        when putchar =>
          if(OUT_BUSY = '1') then
            instruction_state <= putchar;
          else
            DATA_EN <= '1';
            DATA_RDWR <= '1';
            instruction_state <= putchar2;
          end if;

        when putchar2 =>
          OUT_WE <= '1';
          OUT_DATA <= DATA_RDATA;
          reg_pc_increment <= '1';
          instruction_state <= start;

--------------------- , ---------------------------------------------------------
        when getchar =>
          IN_REQ <= '1';

          if (IN_VLD = '1') then
            multiplexer <= "00";
            DATA_EN <= '1';
            DATA_RDWR <= '0';
            reg_pc_increment <= '1';
            instruction_state <= start;
          else
            instruction_state <= getchar;
          end if;
--------------------- while [  ---------------------------------------------------------
        when while_left_bracket =>
          reg_pc_increment <= '1';
          DATA_EN <= '1';
          DATA_RDWR <= '1';

          instruction_state <= while_left_bracket2;

        when while_left_bracket2 =>
          if DATA_RDATA = (DATA_RDATA'range => '0')  then
            reg_cnt_increment <= '1';
            instruction_state <= while_left_bracket3;
          else
            instruction_state <= start;
          end if;

        when while_left_bracket3 =>
          if reg_cnt_adress = (reg_cnt_adress'range => '0') then
            instruction_state <= start;
          else
            CODE_EN <= '1';
					  instruction_state <= while_left_bracket4;
				  end if;

        when while_left_bracket4 =>
          if (CODE_DATA = X"5B") then
            reg_cnt_increment <= '1';
          elsif (CODE_DATA = X"5D") then
            reg_cnt_decrement <= '1';
          end if;

          reg_pc_increment <= '1';
          instruction_state <= while_left_bracket3;


--------------------- while ]  ---------------------------------------------------------
       when while_right_bracket =>
          DATA_EN <= '1';
          DATA_RDWR <= '1';
          instruction_state <= while_right_bracket2;

       when while_right_bracket2 =>
        if DATA_RDATA = (DATA_RDATA'range => '0')  then
          reg_pc_increment <= '1';
          instruction_state <= start;
        else
          reg_cnt_increment <= '1';
          reg_pc_decrement <= '1';
          instruction_state <= while_right_bracket3;
        end if;

       when while_right_bracket3 =>
        if reg_cnt_adress = (reg_cnt_adress'range => '0') then
          instruction_state <= start;
        else
          CODE_EN <= '1';
          instruction_state <= while_right_bracket4;
        end if;

       when while_right_bracket4 =>
        if (CODE_DATA = X"5B") then
          reg_cnt_decrement <= '1';
        elsif (CODE_DATA = X"5D") then
          reg_cnt_increment <= '1';
        end if;
        instruction_state <= while_right_bracket5;

       when while_right_bracket5 =>
        if reg_cnt_adress = (reg_cnt_adress'range => '0')  then
         reg_pc_increment <= '1';
        else
          reg_pc_decrement <= '1';
        end if;
        instruction_state <= while_right_bracket3;

--------------------- comment  ---------------------------------------------------------

      when jump =>
        reg_pc_increment <= '1';
        instruction_state <= jump2;

      when jump2 =>
        CODE_EN <= '1';
        instruction_state <= jump3;

      when jump3 =>
        if (CODE_DATA = X"23") then
          reg_pc_increment <= '1';
          instruction_state <= start;
        else
          instruction_state <= jump;
        end if;

--------------------- hexa ---------------------------------------------------------


      when hexa =>
        DATA_EN <= '1';
        reg_pc_increment <= '1';
        multiplexer <= "11";
        -- 0-9:
        if (CODE_DATA = X"30") then
          multiplexer_change <= "00000000";
        elsif (CODE_DATA = X"31") then
          multiplexer_change <= "00010000";
        elsif (CODE_DATA = X"32") then
          multiplexer_change <= "00100000";
        elsif (CODE_DATA = X"33") then
          multiplexer_change <= "00110000";
        elsif (CODE_DATA = X"34") then
          multiplexer_change <= "01000000";
        elsif (CODE_DATA = X"35") then
          multiplexer_change <= "01010000";
        elsif (CODE_DATA = X"36") then
          multiplexer_change <= "01100000";
        elsif (CODE_DATA = X"37") then
          multiplexer_change <= "01110000";
        elsif (CODE_DATA = X"38") then
          multiplexer_change <= "10000000";
        elsif (CODE_DATA = X"39") then
          multiplexer_change <= "10010000";
        -- A-F:
        elsif (CODE_DATA = X"41") then
          multiplexer_change <= "10100000";
        elsif (CODE_DATA = X"42") then
          multiplexer_change <= "10110000";
        elsif (CODE_DATA = X"43") then
          multiplexer_change <= "11000000";
        elsif (CODE_DATA = X"44") then
          multiplexer_change <= "11010000";
        elsif (CODE_DATA = X"45") then
          multiplexer_change <= "11100000";
        elsif (CODE_DATA = X"46") then
          multiplexer_change <= "11110000";
        end if;
        instruction_state <= start;

--------------------- null (return;) ---------------------------------------------------------

      when halt =>
        instruction_state <= halt;

--------------------- jiny stav ---------------------------------------------------------

      when other_state =>
        reg_pc_increment <= '1';
        instruction_state <= start;

      when others =>

    end case;

  end process fsm;

end behavioral;
