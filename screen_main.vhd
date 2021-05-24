library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

entity screen_main is
    Port ( FPGA_RSTB : in  STD_LOGIC;
           CLK : in  STD_LOGIC;
           lcd_w_enable : in  STD_LOGIC;
           lcd_data_out : out  STD_LOGIC;
           lcd_addr : out  STD_LOGIC_VECTOR (4 downto 0);
           lcd_data : out  STD_LOGIC_VECTOR (7 downto 0);
           seg_w_enable : in  STD_LOGIC;
           seg_data_out : out  STD_LOGIC;
           seg_addr : out  STD_LOGIC_VECTOR (2 downto 0);
           seg_data : out  STD_LOGIC_VECTOR (3 downto 0);
           push_ul : in  STD_LOGIC;
           push_uc : in  STD_LOGIC;
           push_ur : in  STD_LOGIC;
           push_dl : in  STD_LOGIC;
           push_dc : in  STD_LOGIC;
           push_dr : in  STD_LOGIC;
           binary : in  STD_LOGIC_VECTOR (3 downto 0);
           screen_in : in  STD_LOGIC_VECTOR (2 downto 0);
           screen_out : out  STD_LOGIC_VECTOR (2 downto 0);
           rl_enable : in  STD_LOGIC;
           rl_data_out : out  STD_LOGIC;
           rl_addr : out  STD_LOGIC_VECTOR (4 downto 0);
           rl_data : out  STD_LOGIC_VECTOR (7 downto 0);
           sl_enable : out  STD_LOGIC;
           sl_data_out : in  STD_LOGIC;
           sl_addr : in  STD_LOGIC_VECTOR (4 downto 0);
           sl_data : in  STD_LOGIC_VECTOR (7 downto 0));
end screen_main;

architecture Behavioral of screen_main is
	type reg is array( 0 to 31 ) of std_logic_vector( 7 downto 0 );
	signal reg_file : reg;
	signal cnt : std_logic_vector(4 downto 0);
	signal screen : std_logic_vector(2 downto 0);
begin
	process(FPGA_RSTB, CLK)
	begin
		if FPGA_RSTB ='0' then
			for i in 0 to 31 loop
				reg_file(i) <= X"20"; -- initialize register_files
			end loop;
		elsif CLK='1' and CLK'event then
			if push_ul = '0' then
				reg_file(0) <= x"30";
			elsif push_uc = '0' then
				reg_file(1) <= x"31";
			elsif push_ur = '0' then
				reg_file(2) <= x"32";
			elsif push_dl = '0' then
				screen_out <= "001";
			elsif push_dc = '0' then
				screen_out <= "010";
			elsif push_dr = '0' then
				screen_out <= "011";
			end if;
		end if;
	end process;

	process(FPGA_RSTB, CLK)
	Begin
		if FPGA_RSTB ='0' then
			cnt <= (others => '0');
			lcd_data_out <= '0';
		elsif CLK='1' and CLK'event then
			if lcd_w_enable = '1' then
				lcd_data <= reg_file(conv_integer (cnt));
				lcd_addr <= cnt;
				lcd_data_out <= '1';
				
				if cnt= X"1F" then -- 3110
					cnt <= (others =>'0');
				else
					cnt <= cnt + 1;
				end if;
			else
				lcd_data_out <= '0'; -- do not write
			end if;
		end if;
	end process;
end Behavioral;

