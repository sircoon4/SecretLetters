library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

entity screen_read is
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

			-- encrypted letter from main screen
			rl_enable : out  STD_LOGIC;
			rl_data_out : in  STD_LOGIC;
			rl_addr : in  STD_LOGIC_VECTOR (4 downto 0);
			rl_data : in  STD_LOGIC_VECTOR (7 downto 0);

			-- 6 digit code for decryption from read code screen
			rc_enable : out  STD_LOGIC;
			rc_data_out : in  STD_LOGIC;
			rc_addr : in  STD_LOGIC_VECTOR (2 downto 0);
			rc_data : in  STD_LOGIC_VECTOR (3 downto 0)
			);
end screen_read;

architecture Behavioral of screen_read is

-- read code to 복호화 vector (8 bits binary)
signal syn_code : STD_LOGIC_VECTOR (7 downto 0);

-- 7 segments data 관련 signals
type seg_reg is array( 0 to 5 ) of std_logic_vector( 3 downto 0 );
signal seg_reg_file: seg_reg;
signal cnt_seg_reg: std_logic_vector (2 downto 0);

 -- read code
signal c_reg_file : seg_reg;

type reg is array( 0 to 31 ) of std_logic_vector( 7 downto 0 );
signal before_letter : reg; -- 복호화된 편지
signal decode_letter : reg; -- 암호화된 편지

-- lcd data 전송 보조 signal
signal cnt : std_logic_vector(4 downto 0);

begin

-- Input 처리 process 정의 
process(FPGA_RSTB, CLK)
begin
	if FPGA_RSTB ='0' then -- 초기화
		screen_out <= "011";
		rl_enable <= '0';
	elsif CLK='1' and CLK'event then
		if screen_in /= "011" then -- screen이 넘어갔을 때, setting
			screen_out <= "011";
			rl_enable <= '0';
		end if;
		
		if screen_in = "011" then -- current screen일 때 동작
			rl_enable <= '1';
			if push_dr = '0' then -- down-right button이 눌리면 main screen으로 이동
				screen_out <= "000";
			end if;
		end if;
	end if;
end process;

-- read code를 읽어들여 c_reg_file에 저장
process(FPGA_RSTB, CLK)
Begin
	if FPGA_RSTB ='0' then
		c_reg_file <= (others => "0000");
	elsif CLK='1' and CLK'event then
		if rc_data_out = '1' then
			c_reg_file (conv_integer (rc_addr)) <= rc_data;
		end if;
	end if;
end process;

-- read code를 8 bit binary 복호화 vector로 변경하는 process
-- syn_code signal에 저장
process(FPGA_RSTB, CLK)
begin
	if FPGA_RSTB ='0' then
		syn_code <= (others => '0');
	elsif CLK='1' and CLK'event then
		if rc_data_out = '1' then
			-- read code 6 digit 각 자리에서 한 자리나 두 자리의 binary를 추출하여 임의로 배치
			syn_code(7 downto 6) <= c_reg_file(3)(1 downto 0);
			syn_code(5) <= c_reg_file(0)(0);
			syn_code(4) <= c_reg_file(5)(0);
			syn_code(3) <= c_reg_file(4)(0);
			syn_code(2) <= c_reg_file(1)(0);
			syn_code(1 downto 0) <= c_reg_file(2)(1 downto 0);
		end if;
	end if;
end process;

-- main screen에서 암호화된 편지를 읽고 이를 복호화하여 decode_letter에 저장
process(FPGA_RSTB, CLK)
Begin
	if FPGA_RSTB ='0' then
		for i in 0 to 31 loop
			decode_letter(i) <= X"20";
		end loop;
	elsif CLK'event and CLK='1' then
		if screen_in = "011" then
			if rl_data_out ='1' then
				before_letter(conv_integer(rl_addr)) <= rl_data;
				decode_letter(conv_integer(rl_addr)) <= before_letter(conv_integer(rl_addr)) xor syn_code; -- 복호화 vector와 xor 연산을 통해 복호화
			end if;
		end if;
	end if;
end process;

-- decode_letter를 lcd data로 전송
process(FPGA_RSTB, CLK)
Begin
	if FPGA_RSTB = '0' then
		cnt <= (others => '0');
		lcd_data_out <= '0';
	elsif CLK='1' and CLK'event then
		if lcd_w_enable = '1' then
			lcd_data <= decode_letter(conv_integer (cnt));
			lcd_addr <= cnt;
			lcd_data_out <= '1';
			
			if cnt= X"1F" then
				cnt <= (others =>'0');
			else
				cnt <= cnt + 1;
			end if;
		else
			lcd_data_out <= '0';
		end if;
	end if;
end process;

-- 7 segments data 정의 process
process(push_dl,CLK)
Begin
	if screen_in = "011" then
		if (push_dl='0') then -- down-left push button이 눌리는 동안 read code를 segments data로 지정
			seg_reg_file(0)<=c_reg_file(0);
			seg_reg_file(1)<=c_reg_file(1);
			seg_reg_file(2)<=c_reg_file(2);
			seg_reg_file(3)<=c_reg_file(3);
			seg_reg_file(4)<=c_reg_file(4);
			seg_reg_file(5)<=c_reg_file(5);
		else -- button을 누르고 있지 않으면 000000을 segments data로 지정
			for i in 0 to 5 loop
				seg_reg_file(i) <= "0000";
			end loop;
		end if;
	end if;
end process;

-- 7 segments data 전송 process
process(FPGA_RSTB, CLK)
Begin
	if FPGA_RSTB ='0' then
		cnt_seg_reg <= (others => '0');
		seg_data_out <= '0';
	elsif CLK='1' and CLK'event then
		seg_data <= seg_reg_file(conv_integer(cnt_seg_reg));
			seg_addr <= cnt_seg_reg;
			seg_data_out <= '1';
		if cnt_seg_reg = "101" then								-- segment 6  
			cnt_seg_reg <= (others => '0');
		else
			cnt_seg_reg <= cnt_seg_reg + 1;
		end if;
	end if;
end process;

end Behavioral;
