library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

-- main screen

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
	type lcd_reg is array( 0 to 31 ) of std_logic_vector( 7 downto 0 );
	signal lcd_reg_file : lcd_reg;
	signal lcd_cnt : std_logic_vector(4 downto 0);
	
	type seg_reg is array( 0 to 8 ) of std_logic_vector( 3 downto 0 );
	signal seg_reg_file : seg_reg;
	signal seg_cnt : std_logic_vector(2 downto 0);
	
	signal screen : std_logic_vector(2 downto 0);
	
	type letter_reg is array( 0 to 31 ) of std_logic_vector( 7 downto 0 );
	signal letter_1 : letter_reg;
	signal letter_1_exist : std_logic;
	signal letter_2 : letter_reg;
	signal letter_2_exist : std_logic;
	signal letter_3 : letter_reg;
	signal letter_3_exist : std_logic;
	signal letter_4 : letter_reg;
	signal letter_4_exist : std_logic;
	signal letter_5 : letter_reg;
	signal letter_5_exist : std_logic;
	
	signal rl_cnt : std_logic_vector(4 downto 0);
	signal sl_cnt : std_logic_vector(4 downto 0);
	signal sl_enable_reg : std_logic;
	
	signal letter_num : std_logic_vector(2 downto 0);
begin	
	process(FPGA_RSTB, CLK)
	begin
		seg_reg_file(0) <= "0001";
		if FPGA_RSTB ='0' then
			screen_out <= "000";
			
			letter_num <= "000";
			letter_1_exist <= '0';
			letter_2_exist <= '0';
			letter_3_exist <= '0';
			letter_4_exist <= '0';
			letter_5_exist <= '0';
			
			for i in 0 to 31 loop
				lcd_reg_file(i) <= X"20"; -- initialize register_files
			end loop;
			
			for i in 0 to 8 loop
				seg_reg_file(i) <= X"0"; -- initialize register_files
			end loop;
			
			lcd_reg_file(0) <= x"31";
			lcd_reg_file(1) <= x"DB";
			lcd_reg_file(3) <= x"32";
			lcd_reg_file(4) <= x"DB";
			lcd_reg_file(6) <= x"33";
			lcd_reg_file(7) <= x"DB";
			lcd_reg_file(9) <= x"34";
			lcd_reg_file(10) <= x"DB";
			lcd_reg_file(12) <= x"35";
			lcd_reg_file(13) <= x"DB";
			
		elsif CLK='1' and CLK'event then
			if(letter_1_exist = '1') then
				lcd_reg_file(1) <= x"FF";
			elsif(letter_2_exist = '1') then
				lcd_reg_file(4) <= x"FF";
			elsif(letter_3_exist = '1') then
				lcd_reg_file(7) <= x"FF";
			elsif(letter_4_exist = '1') then
				lcd_reg_file(10) <= x"FF";
			elsif(letter_5_exist = '1') then
				lcd_reg_file(13) <= x"FF";
			end if;
			
			if push_ul = '0' then
				lcd_reg_file(16) <= x"30";
			elsif push_uc = '0' then
				lcd_reg_file(17) <= x"31";
			elsif push_ur = '0' then
				lcd_reg_file(18) <= x"32";
			elsif push_dl = '0' then -- Read
				letter_num <= binary(2 downto 0);
				screen_out <= "001";
			elsif push_dc = '0' then -- Write
				letter_num <= binary(2 downto 0);
				screen_out <= "010";
--			elsif push_dr = '0' then
--				screen_out <= "011";
			end if;
		end if;
	end process;

	process(FPGA_RSTB, CLK)
	Begin
		if FPGA_RSTB ='0' then
			lcd_cnt <= (others => '0');
			lcd_data_out <= '0';
		elsif CLK='1' and CLK'event then
			if lcd_w_enable = '1' then
				lcd_data <= lcd_reg_file(conv_integer (lcd_cnt));
				lcd_addr <= lcd_cnt;
				lcd_data_out <= '1';
				
				if lcd_cnt= X"1F" then -- 3110
					lcd_cnt <= (others =>'0');
				else
					lcd_cnt <= lcd_cnt + 1;
				end if;
			else
				lcd_data_out <= '0'; -- do not write
			end if;
		end if;
	end process;
	
	process(FPGA_RSTB, CLK)
	Begin
		if FPGA_RSTB ='0' then
			seg_cnt <= (others => '0');
			seg_data_out <= '0';
		elsif CLK='1' and CLK'event then
			seg_data <= seg_reg_file(conv_integer (seg_cnt));
			seg_addr <= seg_cnt;
			seg_data_out <= '1';
			
			if seg_cnt= "101" then
				seg_cnt <= (others =>'0');
			else
				seg_cnt <= seg_cnt + 1;
			end if;
--			if seg_w_enable = '1' then
--				
--			else
--				seg_data_out <= '0'; -- do not write
--			end if;
		end if;
	end process;
	
	process(FPGA_RSTB, CLK)
	Begin
		if FPGA_RSTB ='0' then
			rl_cnt <= (others => '0');
			rl_data_out <= '0';
		elsif CLK='1' and CLK'event then
			if rl_enable = '1' then
				case letter_num is
					when "000" => rl_data <= letter_1(conv_integer(rl_cnt));
					when "001" => rl_data <= letter_2(conv_integer(rl_cnt));
					when "010" => rl_data <= letter_3(conv_integer(rl_cnt));
					when "011" => rl_data <= letter_4(conv_integer(rl_cnt));
					when "100" => rl_data <= letter_5(conv_integer(rl_cnt));
					when others => rl_data <= X"20";
				end case;
				rl_addr <= rl_cnt;
				rl_data_out <= '1';
				
				if rl_cnt= X"1F" then -- 3110
					rl_cnt <= (others =>'0');
				else
					rl_cnt <= rl_cnt + 1;
				end if;
			else
				rl_data_out <= '0'; -- do not write
			end if;
		end if;
	end process;
	
sl_enable_reg <= '1' when (screen_in = "100" or screen_in = "000") else '0'; -- save letter when write screen

	process(FPGA_RSTB, CLK)
	Begin
		if FPGA_RSTB ='0' then
			for i in 0 to 31 loop
				letter_1(i) <= X"20"; -- initialize register_files
			end loop;
			
			for i in 0 to 31 loop
				letter_2(i) <= X"20"; -- initialize register_files
			end loop;
			
			for i in 0 to 31 loop
				letter_3(i) <= X"20"; -- initialize register_files
			end loop;
			
			for i in 0 to 31 loop
				letter_4(i) <= X"20"; -- initialize register_files
			end loop;
			
			for i in 0 to 31 loop
				letter_5(i) <= X"20"; -- initialize register_files
			end loop;
		elsif CLK'event and CLK='1' then
			if sl_enable_reg ='1' and sl_data_out ='1' then
				case letter_num is
					when "000" => letter_1(conv_integer(sl_addr)) <= sl_data;
					when "001" => letter_2(conv_integer(sl_addr)) <= sl_data;
					when "010" => letter_3(conv_integer(sl_addr)) <= sl_data;
					when "011" => letter_4(conv_integer(sl_addr)) <= sl_data;
					when "100" => letter_5(conv_integer(sl_addr)) <= sl_data;
					when others => letter_5(0) <= X"20";
				end case;
			end if;
		end if;
	end process;
	
sl_enable <= sl_enable_reg;
end Behavioral;

