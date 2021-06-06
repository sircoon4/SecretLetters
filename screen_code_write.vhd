library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

entity screen_code_write is
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

			-- 6 digit code for encryption to write screen
			wc_enable : in  STD_LOGIC;
			wc_data_out : out  STD_LOGIC;
			wc_addr : out  STD_LOGIC_VECTOR (2 downto 0);
			wc_data : out  STD_LOGIC_VECTOR (3 downto 0)
			);
end screen_code_write;

architecture Behavioral of screen_code_write is
	-- clock 관련 signal
	signal load_100k : std_logic;
	signal clk_100k : std_logic; -- 100KHz clock
	signal cnt_100k : std_logic_vector (7 downto 0);
	signal load_50 : std_logic;
	signal clk_50 : std_logic; -- 50Hz clock
	signal cnt_50 : std_logic_vector (11 downto 0);
	
	-- 7 segments display data 전송 관련 signal
	type seg is array(0 to 5) of std_logic_vector(3 downto 0);
	signal seg_file : seg;
	signal cnt_seg : std_logic_vector(2 downto 0);
	
	-- lcd display data 전송 관련 signal
	type reg is array(0 to 31) of std_logic_vector(7 downto 0);
	signal reg_file : reg;
	signal cnt_reg : std_logic_vector(4 downto 0);
	
	-- write code data 전송 to write screen 관련 signal
	type wc is array(0 to 5) of std_logic_vector(3 downto 0);
	signal wc_file : wc;
	signal cnt_wc : std_logic_vector(2 downto 0);
	
	-- push button 입력 보조 signal
	signal ul_clicked : std_logic;
	
	-- 7 segments 입력 위치
	signal enter : std_logic_vector(2 downto 0);

	-- current screen으로 지정될 때 한 번 setting을 위한 signal
	signal screen_enter : std_logic;
begin
	
	--Clock(100kHz, 10 us period) Generation
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
	load_100k <= '1' when (cnt_100k = X"13") else '0';

	--Clock(50 Hz, 20 ms period) Generation
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

	-- Input 처리 process 정의
	-- push button이 두번 눌리는 것을 방지하기 위해 50Hz clock을 사용함.
	process(FPGA_RSTB, clk_50)
	begin
		if FPGA_RSTB = '0' then -- 초기화
			screen_out <= "010";
			
			screen_enter <= '0';
			
			enter <= "101"; -- 7 segments 입력 초기 위치를 좌측 끝으로 지정
			
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
			
			-- write code: 000000
			for i in 0 to 5 loop
				wc_file(i) <= X"0";
			end loop;
			
		elsif rising_edge(clk_50) then
			if screen_in /= "010" then -- screen이 넘어갔을 때, setting
				screen_out <= "010";
				screen_enter <= '0';
			elsif screen_in = "010" then -- current screen일 때, 동작
				if screen_enter <= '0' then -- screen이 넘어올 때, 한 번 setting
					enter <= "101";
				
					for i in 0 to 5 loop
						seg_file(i) <= X"0";
					end loop;
					
					for i in 0 to 5 loop
						wc_file(i) <= X"0";
					end loop;
					
					screen_enter <= '1';
				end if;
				if(push_ul = '1' and ul_clicked = '0') then -- up-left push button이 눌리면
					-- enter 위치에 현재 binary 값을 7 segments에 표시하고, read code에 작성
					seg_file(conv_integer(enter)) <= binary;
					wc_file(conv_integer(enter)) <= binary;
					
					if enter = "000" then -- enter 위치가 오른쪽 끝이면 좌측 끝으로 초기화
						enter <= "101";
					else -- 아니라면 우측으로 이동
						enter <= enter - 1;
					end if;
				end if;
				ul_clicked <= push_ul; -- push button이 두번 눌리는 것을 방지
				
				if push_dl = '0' then -- down-left push button이 눌리면 clear 동작
					enter <= "101";
					
					for i in 0 to 5 loop
						seg_file(i) <= X"0";
					end loop;
					
					for i in 0 to 5 loop
						wc_file(i) <= X"0";
					end loop;
				elsif push_dc = '0' then -- down-center push button이 눌리면 write screen으로 이동
					screen_out <= "100";
				elsif push_dr = '0' then -- down-right push button이 눌리면 main screen으로 이동
					screen_out <= "000";
				end if;
			end if;
		end if;
	end process;
	
	-- lcd data 전송 process
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
	
	-- 7 seg data 전송 process
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

	-- write code 전송 to write screen process
	process(FPGA_RSTB, CLK)
	begin
		if FPGA_RSTB = '0' then
			cnt_wc <= (others => '0');
			wc_data_out <= '0';
		elsif CLK = '1' and CLK'event then
			wc_data <= wc_file(conv_integer(cnt_wc));
			wc_addr <= cnt_wc;
			wc_data_out <= '1';
			if cnt_wc = "101" then
				cnt_wc <= (others => '0');
			else
				cnt_wc <= cnt_wc + 1;
			end if;
		end if;
	end process;

end Behavioral;

