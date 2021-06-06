library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

entity display_module is
    Port (
			-- system
			FPGA_RSTB : in  STD_LOGIC;
			CLK : in  STD_LOGIC;

			-- LCD output
			LCD_A : out  STD_LOGIC_VECTOR (1 downto 0);
			LCD_EN : out  STD_LOGIC;
			LCD_D : out  STD_LOGIC_VECTOR (7 downto 0);

			-- 7 segments output
			DIGIT : out STD_LOGIC_VECTOR (6 downto 1);
			SEG_A : out STD_LOGIC;
			SEG_B : out STD_LOGIC;
			SEG_C : out STD_LOGIC;
			SEG_D : out STD_LOGIC;
			SEG_E : out STD_LOGIC;
			SEG_F : out STD_LOGIC;
			SEG_G : out STD_LOGIC;
			SEG_DP : out STD_LOGIC;

			-- lcd display data from other screens
			lcd_w_enable : out std_logic;
			lcd_data_out : in std_logic; 
			lcd_addr : in std_logic_vector(4 downto 0);
			lcd_data : in std_logic_vector(7 downto 0); 

			-- 7 segments display data from other screens
			seg_w_enable : out std_logic;
			seg_data_out : in std_logic;
			seg_addr : in std_logic_vector(2 downto 0);
			seg_data : in std_logic_vector(3 downto 0)
			);
end display_module;

architecture Behavioral of display_module is
-- clock 관련 signals --------------------------

	signal load_100k : std_logic;
	signal clk_100k : std_logic; -- 100KHz clock
	signal cnt_100k : std_logic_vector (7 downto 0);
	signal load_50 : std_logic;
	signal clk_50 : std_logic; -- 50Hz clock
	signal cnt_50 : std_logic_vector (11 downto 0);
	
-- lcd 관련 signals ----------------------------
	
	-- lcd에 띄울 내용 / 32개의 ASCII
	type reg is array( 0 to 31 ) of std_logic_vector( 7 downto 0 );
	signal reg_file : reg;
	
	-- lcd 동작 관련
	signal lcd_cnt : std_logic_vector (8 downto 0);
	signal lcd_state : std_logic_vector (7 downto 0);
	signal lcd_nstate : std_logic_vector (7 downto 0);
	signal lcd_db : std_logic_vector (7 downto 0);
	
	-- lcd 데이터 통신 활성화
	signal w_enable_reg : std_logic;
	
-- 7 segments 관련 signals ----------------------
	
	-- 7 segments에 띄울 내용 / 6 digit Decimal
	type seg_type is array(0 to 5) of std_logic_vector(3 downto 0);
	signal seg_file : seg_type;
	
	-- 7 segments 동작 관련
	signal sel : std_logic_vector(2 downto 0);
	signal segment : std_logic_vector(3 downto 0);
	signal seg : std_logic_vector(7 downto 0);
	
	-- 7 segments 데이터 통신 활성화
	signal w_enable_seg : std_logic;
begin

-- clock 관련 processes --------------------------

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
load_100k <= '1' when (cnt_100k = X"13") else '0'; -- count 20 clk

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

-- data read from current screen 관련 processes --------------------------

-- lcd data reading
process(FPGA_RSTB, CLK)
Begin
	if FPGA_RSTB = '0' then
		for i in 0 to 31 loop
			reg_file(i) <= X"20"; -- initialize reg file with 'space'
		end loop;
	elsif CLK'event and CLK='1' then
		if w_enable_reg ='1' and lcd_data_out ='1' then
			reg_file(conv_integer(lcd_addr)) <= lcd_data; -- reg data of address =data
		end if;
	end if;
end process;

-- segments data reading
process(FPGA_RSTB, CLK)
Begin
	if FPGA_RSTB = '0' then
		for j in 0 to 5 loop
			seg_file(j) <= "0000";
		end loop;
	elsif CLK'event and CLK = '1' then
		if seg_data_out = '1' then
			seg_file(conv_integer(seg_addr)) <= seg_data;
		end if;
	end if;
end process;

-- lcd diplay 관련 processes --------------------------

-- 20ms에 한 번씩 LCD state를 변경
process(FPGA_RSTB, clk_50, lcd_cnt)
begin
	if FPGA_RSTB = '0' then
		lcd_cnt <= (others => '0');
	elsif rising_edge (clk_50) then
		-- X"27" state -> X"05" (return home)
		if (lcd_cnt >= "001001110") then
			lcd_cnt <= "000001010";
		-- state += 1
		else
			lcd_cnt <= lcd_cnt + 1;
		end if;
	end if;
end process;
lcd_state <= lcd_cnt (8 downto 1); -- max: 00101011 -- 8 bits
w_enable_reg <= '0' when lcd_state < X"06" else '1'; -- read until X06

-- lcd state 동작 정의
-- 초기 설정 / lcd displays reg_file
process(lcd_state)
begin
	case lcd_state is
		when X"00" => lcd_db <= "00111000"; -- Function set
		when X"01" => lcd_db <= "00001000"; -- Display OFF
		when X"02" => lcd_db <= "00000001"; -- Display clear
		when X"03" => lcd_db <= "00000110"; -- Entry mode set
		when X"04" => lcd_db <= "00001100"; -- Display ON
		when X"05" => lcd_db <= "00000011"; -- Return Home
		when X"06" => lcd_db <= reg_file(0);
		when X"07" => lcd_db <= reg_file(1);
		when X"08" => lcd_db <= reg_file(2);
		when X"09" => lcd_db <= reg_file(3);
		when X"0A" => lcd_db <= reg_file(4);
		when X"0B" => lcd_db <= reg_file(5);
		when X"0C" => lcd_db <= reg_file(6);
		when X"0D" => lcd_db <= reg_file(7);
		when X"0E" => lcd_db <= reg_file(8);
		when X"0F" => lcd_db <= reg_file(9);
		when X"10" => lcd_db <= reg_file(10);
		when X"11" => lcd_db <= reg_file(11);
		when X"12" => lcd_db <= reg_file(12);
		when X"13" => lcd_db <= reg_file(13);
		when X"14" => lcd_db <= reg_file(14);
		when X"15" => lcd_db <= reg_file(15);
		when X"16" => lcd_db <= X"C0"; -- Change Line
		when X"17" => lcd_db <= reg_file(16);
		when X"18" => lcd_db <= reg_file(17);
		when X"19" => lcd_db <= reg_file(18);
		when X"1A" => lcd_db <= reg_file(19);
		when X"1B" => lcd_db <= reg_file(20);
		when X"1C" => lcd_db <= reg_file(21);
		when X"1D" => lcd_db <= reg_file(22);
		when X"1E" => lcd_db <= reg_file(23);
		when X"1F" => lcd_db <= reg_file(24);
		when X"20" => lcd_db <= reg_file(25);
		when X"21" => lcd_db <= reg_file(26);
		when X"22" => lcd_db <= reg_file(27);
		when X"23" => lcd_db <= reg_file(28);
		when X"24" => lcd_db <= reg_file(29);
		when X"25" => lcd_db <= reg_file(30);
		when X"26" => lcd_db <= reg_file(31);
		when others => lcd_db <= (others => '0');
	end case;
end process;

-- Write or setting
LCD_A(1) <= '0';
LCD_A(0) <= '0'
	when
		(lcd_state >= X"00" and lcd_state < X"06")
		or (lcd_state = X"16") -- change line
	else '1';
	
-- for stable move of state
LCD_EN <= not lcd_cnt(0);

-- LCD display data
LCD_D <= lcd_db;

-- LCD 데이터 통신 활성화
lcd_w_enable <= w_enable_reg;

-- 7 segments diplay 관련 processes -------------------------------------------------------------------
	
	-- 순차적으로 DIGIT, segment data 지정
	process(sel)
	begin
		case sel is
			when "000" => DIGIT <= "000001";
				segment <= seg_file(5);					
			when "001" => DIGIT <= "000010";
				segment <= seg_file(4);
			when "010" => DIGIT <= "000100";
				segment <= seg_file(3);
			when "011" => DIGIT <= "001000";
				segment <= seg_file(2);
			when "100" => DIGIT <= "010000";
				segment <= seg_file(1);
			when "101" => DIGIT <= "100000";
				segment <= seg_file(0);
			when others => null;
		end case;
	end process;
	
	-- 50us 마다 display digit 변경
	process(FPGA_RSTB, CLK)
		variable seg_clk_cnt : integer range 0 to 200;
	begin
		if(FPGA_RSTB = '0') then
			sel <= "000";
			seg_clk_cnt := 0;
		elsif(CLK'event and CLK = '1') then
			if(seg_clk_cnt = 200) then
				seg_clk_cnt := 0;
				if(sel = "101") then
					sel <= "000";
				else
					sel <= sel + 1;
				end if;
			else
				seg_clk_cnt := seg_clk_cnt + 1;
			end if;
		end if;
	end process;
	
	-- segment 데이터 정의
	process(segment)
	begin
		case segment is
			when "0000" => seg <= "00111111";
			when "0001" => seg <= "00000110";
			when "0010" => seg <= "01011011";
			when "0011" => seg <= "01001111";
			when "0100" => seg <= "01100110";
			when "0101" => seg <= "01101101";
			when "0110" => seg <= "01111101";
			when "0111" => seg <= "00100111";
			when "1000" => seg <= "01111111";
			when "1001" => seg <= "01101111";
			when others => null;
		end case;
	end process;
	
	-- 7 segments display
	SEG_A <= seg(0);
	SEG_B <= seg(1);
	SEG_C <= seg(2);
	SEG_D <= seg(3);
	SEG_E <= seg(4);
	SEG_F <= seg(5);
	SEG_G <= seg(6);
	SEG_DP <= seg(7);
				

end Behavioral;

