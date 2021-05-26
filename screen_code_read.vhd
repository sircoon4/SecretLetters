library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

entity screen_code_read is
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
           rc_enable : in  STD_LOGIC;
           rc_data_out : out  STD_LOGIC;
           rc_addr : out  STD_LOGIC_VECTOR (5 downto 0);
           rc_data : out  STD_LOGIC_VECTOR (3 downto 0));
end screen_code_read;

architecture Behavioral of screen_code_read is

	type seg is array(0 to 31) of std_logic_vector(3 downto 0);
	signal seg_file : seg;
	signal cnt : std_logic_vector(2 downto 0);

begin
	-- test

	process(FPGA_RSTB, CLK)
	begin
		if FPGA_RSTB = '0' then
			for i in 0 to 31 loop
				seg_file(i) <= "1000";							-- reset 입력 시 모든 segment를 8로 표시
			end loop;
		elsif CLK = '1' and CLK'event then
			if push_dl = '0' then
				seg_file(0) <= 
				
		
	
	
	
	
	
	
	
	
	
	process(FPGA_RSTB, CLK)										-- segment로 보내는 데이터
	begin
		if FPGA_RSTB = '0' then
			cnt <= (others => '0');
			seg_data_out <= '0';
		elsif CLK = '1' and CLK'event then
			if seg_w_enable = '1' then
				seg_data <= seg_file(conv_integer(cnt));
				seg_addr <= cnt;
				seg_data_out <= '1';
				if cnt = "101" then								-- segment 6자리까지 갔을 때
					cnt <= (others => '0');
				else
					cnt <= cnt + 1;
				end if;
			else
				seg_data_out <= '0';
			end if;
		end if;
	end process;

end Behavioral;

