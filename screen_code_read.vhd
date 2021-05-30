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

	type seg is array(0 to 5) of std_logic_vector(3 downto 0);
	type reg is array(0 to 31) of std_logic_vector(7 downto 0);
	signal seg_file : seg;
	signal reg_file : reg;
	signal cnt_seg : std_logic_vector(2 downto 0);
	signal cnt_reg : std_logic_vector(4 downto 0);

begin
	-- test
	
	
	process(FPGA_RSTB, CLK)	
		variable cursor : std_logic_vector(3 downto 0);
		variable Enter : std_logic_vector(2 downto 0);
	begin
		
		cursor := "0000";
		Enter := "000";
	
		if FPGA_RSTB = '0' then
			for i in 0 to 31 loop
				reg_file(i) <= X"20";
			end loop;
		elsif CLK = '1' and CLK'event then		-- 0~9 display
			reg_file(0) <= X"30";
			reg_file(1) <= X"31";
			reg_file(2) <= X"32";
			reg_file(3) <= X"33";
			reg_file(4) <= X"34";
			reg_file(5) <= X"35";
			reg_file(6) <= X"36";
			reg_file(7) <= X"37";
			reg_file(8) <= X"38";
			reg_file(9) <= X"39";
		end if;
		
		if push_dr = '0' then					-- 커서 오른쪽으로 이동했을 때 
			if cursor = "1001" then
				cursor := "1001";
			else
				cursor := cursor + 1;
			end if;
		elsif push_dl = '0' then				-- 커서 왼쪽으로 이동했을 때
			if cursor = "0000" then
				cursor := "0000";
			else
				cursor := cursor - 1;
			end if;
		end if;
		
		
		if (push_dc = '0' and Enter = "000") then
			Enter := Enter + 1;
			seg_file(0) <= "0000" + cursor;
		elsif (push_dc = '0' and Enter = "001") then
			Enter := Enter + 1;
			seg_file(1) <= "0000" + cursor;
		elsif (push_dc = '0' and Enter = "010") then
			Enter := Enter + 1;
			seg_file(2) <= "0000" + cursor;
		elsif (push_dc = '0' and Enter = "011") then
			Enter := Enter + 1;
			seg_file(3) <= "0000" + cursor;
		elsif (push_dc = '0' and Enter = "100") then
			Enter := Enter + 1;
			seg_file(4) <= "0000" + cursor;
		elsif (push_dc = '0' and Enter = "101") then
			Enter := Enter + 1;
			seg_file(5) <= "0000" + cursor;
		end if;
	end process;
	
	process(FPGA_RSTB, CLK)											-- lcd로 보내는 데이터
	begin
		if FPGA_RSTB = '0' then
			cnt_reg <= (others => '0');
			lcd_data_out <= '0';
		elsif CLK = '1' and CLK'event then
			if lcd_w_enable = '1' then
				lcd_data <= reg_file(conv_integer(cnt_reg));
				lcd_addr <= cnt_reg;
				lcd_data_out <= '1';
				if cnt_reg = "101" then								-- lcd 31자리까지 갔을 때
					cnt_reg <= (others => '0');
				else
					cnt_reg <= cnt_reg + 1;
				end if;
			else
				lcd_data_out <= '0';
			end if;
		end if;
	end process;
	
	
	process(FPGA_RSTB, CLK)											-- segment로 보내는 데이터
	begin
		if FPGA_RSTB = '0' then
			cnt_seg <= (others => '0');
			seg_data_out <= '0';
		elsif CLK = '1' and CLK'event then
			if seg_w_enable = '1' then
				seg_data <= seg_file(conv_integer(cnt_seg));
				seg_addr <= cnt_seg;
				seg_data_out <= '1';
				if cnt_seg = "101" then								-- segment 6자리까지 갔을 때
					cnt_seg <= (others => '0');
				else
					cnt_seg <= cnt_seg + 1;
				end if;
			else
				seg_data_out <= '0';
			end if;
		end if;
	end process;

	
end Behavioral;

