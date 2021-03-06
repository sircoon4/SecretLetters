library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

entity screen_code_read is
    Port (
			-- system
			FPGA_RSTB : in  STD_LOGIC;
			CLK : in  STD_LOGIC;

			-- lcd display data to display module
			lcd_w_enable : in  STD_LOGIC;
			lcd_data_out : out  STD_LOGIC;
			lcd_addr : out  STD_LOGIC_VECTOR (4 downto 0);
			lcd_data : out  STD_LOGIC_VECTOR (7 downto 0);

			-- 7 seg display data to display module
			seg_w_enable : in  STD_LOGIC;
			seg_data_out : out  STD_LOGIC;
			seg_addr : out  STD_LOGIC_VECTOR (2 downto 0);
			seg_data : out  STD_LOGIC_VECTOR (3 downto 0);

			-- push buttons
			push_ul : in  STD_LOGIC;
			push_uc : in  STD_LOGIC;
			push_ur : in  STD_LOGIC;
			push_dl : in  STD_LOGIC;
			push_dc : in  STD_LOGIC;
			push_dr : in  STD_LOGIC;
			
			-- 4 bits binary input
			binary : in  STD_LOGIC_VECTOR (3 downto 0);

			-- current screen
			screen_in : in  STD_LOGIC_VECTOR (2 downto 0);
			
			-- navigate to other screen
			screen_out : out  STD_LOGIC_VECTOR (2 downto 0);

			-- 6 digit code for decryption to read screen
			rc_enable : in  STD_LOGIC;
			rc_data_out : out  STD_LOGIC;
			rc_addr : out  STD_LOGIC_VECTOR (2 downto 0);
			rc_data : out  STD_LOGIC_VECTOR (3 downto 0)
			);
end screen_code_read;

architecture Behavioral of screen_code_read is
	-- clock 包访 signal
	signal load_100k : std_logic;
	signal clk_100k : std_logic; -- 100KHz clock
	signal cnt_100k : std_logic_vector (7 downto 0);
	signal load_50 : std_logic;
	signal clk_50 : std_logic; -- 50Hz clock
	signal cnt_50 : std_logic_vector (11 downto 0);
	
	-- 7 segments display data 傈价 包访 signal
	type seg is array(0 to 5) of std_logic_vector(3 downto 0);
	signal seg_file : seg;
	signal cnt_seg : std_logic_vector(2 downto 0);
	
	-- lcd display data 傈价 包访 signal
	type reg is array(0 to 31) of std_logic_vector(7 downto 0);
	signal reg_file : reg;
	signal cnt_reg : std_logic_vector(4 downto 0);
	
	-- read code data 傈价 to read screen 包访 signal
	type rc is array(0 to 5) of std_logic_vector(3 downto 0);
	signal rc_file : rc;
	signal cnt_rc : std_logic_vector(2 downto 0);
	
	-- push button 涝仿 焊炼 signal
	signal ul_clicked : std_logic;
	
	-- 7 segments 涝仿 困摹
	signal enter : std_logic_vector(2 downto 0);

	-- current screen栏肺 瘤沥瞪 锭 茄 锅 setting阑 困茄 signal
	signal screen_enter : std_logic;
begin
	-- Clock(100kHz, 10 us period) Generation
	process(FPGA_RSTB,CLK,load_100k,cnt_100k)
	Begin
		if FPGA_RSTB = '0' then
			cnt_100k <= (others => '0');
			clk_100k <= '0';
		elsif rising_edge (CLK) then
			if load_100k = '1' then
				cnt_100k <= (others => '0');
				clk_100k <= not clk_100k;
			else
				cnt_100k <= cnt_100k + 1;
			end if;
		end if;
	end process;
	load_100k <= '1' when (cnt_100k = X"13") else '0'; -- count 20 clk

	-- Clock(50 Hz, 20 ms period) Generation
	process(FPGA_RSTB,clk_100k,load_50,cnt_50)
	Begin
		if FPGA_RSTB = '0' then
			cnt_50 <= (others => '0');
			clk_50 <= '0';
		elsif rising_edge (clk_100k) then
			if load_50 = '1' then
				cnt_50 <= (others => '0');
				clk_50 <= not clk_50;
			else
				cnt_50 <= cnt_50 + 1;
			end if;
		end if;
	end process;
	load_50 <= '1' when (cnt_50 = X"3E7") else '0'; -- 999

	-- Input 贸府 process 沥狼
	-- push button捞 滴锅 喘府绰 巴阑 规瘤窍扁 困秦 50Hz clock阑 荤侩窃.
	process(FPGA_RSTB, clk_50)
	begin
		if FPGA_RSTB = '0' then -- 檬扁拳
			screen_out <= "001";
			
			screen_enter <= '0';
			
			enter <= "101"; -- 7 segments 涝仿 檬扁 困摹甫 谅螟 场栏肺 瘤沥
			
			ul_clicked <= '1';
			
			-- LCD: INPUT YOUR CODE!
			for i in 0 to 31 loop
				reg_file(i) <= X"20";
			end loop;
			
			reg_file(0) <= "01001001"; --I
			reg_file(1) <= "01001110"; --N
			reg_file(2) <= "01010000"; --P
			reg_file(3) <= "01010101"; --U
			reg_file(4) <= "01010100"; --T
			reg_file(5) <= "00100000"; --space
			reg_file(6) <= "01011001"; --Y
			reg_file(7) <= "01001111"; --O
			reg_file(8) <= "01010101"; --U
			reg_file(9) <= "01010010"; --R
			reg_file(10) <= "00100000"; --space
			reg_file(11) <= "01000011"; --C
			reg_file(12) <= "01001111"; --O
			reg_file(13) <= "01000100"; --D
			reg_file(14) <= "01000101"; --E
			reg_file(15) <= "00100001"; --!
			
			-- 7 seg: 000000
			for i in 0 to 5 loop
				seg_file(i) <= X"0";
			end loop;
			
			-- read code: 000000
			for i in 0 to 5 loop
				rc_file(i) <= X"0";
			end loop;
			
		elsif rising_edge(clk_50) then
			if screen_in /= "001" then -- screen捞 逞绢艾阑 锭, setting
				screen_out <= "001";
				screen_enter <= '0';
			elsif screen_in = "001" then -- current screen老 锭, 悼累
				if screen_enter = '0' then -- screen捞 逞绢棵 锭, 茄 锅 setting
					enter <= "101";
				
					for i in 0 to 5 loop
						seg_file(i) <= X"0";
					end loop;
					
					for i in 0 to 5 loop
						rc_file(i) <= X"0";
					end loop;
					
					screen_enter <= '1';
				end if;
				
				if(push_ul = '1' and ul_clicked = '0') then -- up-left push button捞 喘府搁
					-- enter 困摹俊 泅犁 binary 蔼阑 7 segments俊 钎矫窍绊, read code俊 累己
					seg_file(conv_integer(enter)) <= binary;
					rc_file(conv_integer(enter)) <= binary;
					
					if enter = "000" then -- enter 困摹啊 坷弗率 场捞搁 谅螟 场栏肺 檬扁拳
						enter <= "101";
					else -- 酒聪扼搁 快螟栏肺 捞悼
						enter <= enter - 1;
					end if;
				end if;
				ul_clicked <= push_ul; -- push button捞 滴锅 喘府绰 巴阑 规瘤
				
				if push_dl = '0' then -- down-left push button捞 喘府搁 clear 悼累
					enter <= "101";
					
					for i in 0 to 5 loop
						seg_file(i) <= X"0";
					end loop;
					
					for i in 0 to 5 loop
						rc_file(i) <= X"0";
					end loop;
				elsif push_dc = '0' then -- down-center push button捞 喘府搁 read screen栏肺 捞悼
					screen_out <= "011";
				elsif push_dr = '0' then -- down-right push button捞 喘府搁 main screen栏肺 捞悼
					screen_out <= "000";
				end if;
			end if;
		end if;
	end process;
	
	-- lcd data 傈价 process
	process(FPGA_RSTB, CLK)
	begin
		if FPGA_RSTB = '0' then
			cnt_reg <= (others => '0');
			lcd_data_out <= '0';
		elsif CLK = '1' and CLK'event then
			if lcd_w_enable = '1' then
				lcd_data <= reg_file(conv_integer(cnt_reg));
				lcd_addr <= cnt_reg;
				lcd_data_out <= '1';
				if cnt_reg = X"1F" then
					cnt_reg <= (others => '0');
				else
					cnt_reg <= cnt_reg + 1;
				end if;
			else
				lcd_data_out <= '0';
			end if;
		end if;
	end process;
	
	-- 7 seg data 傈价 process
	process(FPGA_RSTB, CLK)
	Begin
		if FPGA_RSTB ='0' then
			cnt_seg <= (others => '0');
			seg_data_out <= '0';
		elsif CLK='1' and CLK'event then
			seg_data <= seg_file(conv_integer (cnt_seg));
			seg_addr <= cnt_seg;
			seg_data_out <= '1';
			
			if cnt_seg= "101" then
				cnt_seg <= (others =>'0');
			else
				cnt_seg <= cnt_seg + 1;
			end if;
		end if;
	end process;

	-- read code 傈价 to read screen process
	process(FPGA_RSTB, CLK)
		begin
			if FPGA_RSTB = '0' then
				cnt_rc <= (others => '0');
				rc_data_out <= '0';
			elsif CLK = '1' and CLK'event then
				rc_data <= rc_file(conv_integer(cnt_rc));
				rc_addr <= cnt_rc;
				rc_data_out <= '1';
				if cnt_rc = "101" then
					cnt_rc <= (others => '0');
				else
					cnt_rc <= cnt_rc + 1;
				end if;
			end if;
		end process;
	
end Behavioral;

