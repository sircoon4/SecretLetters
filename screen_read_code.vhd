library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

entity screen_read_code is
    Port ( FPGA_RSTB : in  STD_LOGIC;
           CLK : in  STD_LOGIC;
           w_enable : in  STD_LOGIC;
           data_out : out  STD_LOGIC;
           addr : out  STD_LOGIC_VECTOR (4 downto 0);
           data : out  STD_LOGIC_VECTOR (7 downto 0);
           push_ul : in  STD_LOGIC;
           push_uc : in  STD_LOGIC;
           push_ur : in  STD_LOGIC;
           push_dl : in  STD_LOGIC;
           push_dc : in  STD_LOGIC;
           push_dr : in  STD_LOGIC;
           binary : in  STD_LOGIC_VECTOR (3 downto 0);
           screen_in : in  STD_LOGIC_VECTOR (2 downto 0);
           screen_out : out  STD_LOGIC_VECTOR (2 downto 0));
end screen_read_code;

architecture Behavioral of screen_read_code is
	type reg is array( 0 to 31 ) of std_logic_vector( 7 downto 0 );
	signal reg_file : reg;
	signal cnt : std_logic_vector(4 downto 0);
	signal screen : std_logic_vector(2 downto 0);
begin
	screen <= screen_in;
	screen_out <= screen;
	
	process(screen)
	begin
		for i in 0 to 31 loop
			reg_file(i) <= X"31"; -- initialize register_files
		end loop;
	end process;

	process(FPGA_RSTB, CLK)
	begin
		if FPGA_RSTB ='0' then
			for i in 0 to 31 loop
				reg_file(i) <= X"20"; -- initialize register_files
			end loop;
		elsif CLK='1' and CLK'event then
			if push_ul = '0' then
				reg_file(0) <= x"31";
			elsif push_uc = '0' then
				reg_file(1) <= x"31";
			elsif push_ur = '0' then
				reg_file(2) <= x"31";
			elsif push_dl = '0' then
				screen <= "000";
			elsif push_dc = '0' then
				screen <= "010";
			elsif push_dr = '0' then
				screen <= "011";
			end if;
		end if;
	end process;

	process(FPGA_RSTB, CLK)
	Begin
		if FPGA_RSTB ='0' then
			cnt <= (others => '0');
			data_out <= '0';
		elsif CLK='1' and CLK'event then
			if w_enable = '1' then
				data <= reg_file (conv_integer (cnt));
				addr <= cnt;
				data_out <= '1';
				
				if cnt= X"1F" then -- 3110
					cnt <= (others =>'0');
				else
					cnt <= cnt + 1;
				end if;
			else
				data_out <= '0'; -- do not write
			end if;
		end if;
	end process;
end Behavioral;

