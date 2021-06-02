library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

entity screen_code_write is
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
           wc_enable : in  STD_LOGIC;
           wc_data_out : out  STD_LOGIC;
           wc_addr : out  STD_LOGIC_VECTOR (2 downto 0);
           wc_data : out  STD_LOGIC_VECTOR (3 downto 0));
end screen_code_write;
--screen code write
architecture Behavioral of screen_code_write is
	
	signal load_100k : std_logic;
	signal clk_100k : std_logic; -- to make
	signal cnt_100k : std_logic_vector (7 downto 0);
	signal load_50 : std_logic;
	signal clk_50 : std_logic; -- LCD display
	signal cnt_50 : std_logic_vector (11 downto 0);
	
	type seg is array(0 to 5) of std_logic_vector(3 downto 0);
	type reg is array(0 to 31) of std_logic_vector(7 downto 0);
	type wc is array(0 to 5) of std_logic_vector(3 downto 0);
	signal seg_file : seg;
	signal reg_file : reg;
	signal wc_file : wc;
	signal cnt_seg : std_logic_vector(2 downto 0);
	signal cnt_reg : std_logic_vector(4 downto 0);
	signal cnt_wc : std_logic_vector(2 downto 0);
	
	signal bc_clicked : std_logic;
	
--	signal cursor : std_logic_vector(3 downto 0);
	signal enter : std_logic_vector(2 downto 0);

begin
	-- test
	
	process(FPGA_RSTB,CLK,load_100k,cnt_100k) --Clock(100kHz, 10 us period) Generation
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

	process(FPGA_RSTB,clk_100k,load_50,cnt_50) --Clock(50 Hz, 20 ms period) Generation
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

	process(FPGA_RSTB, clk_50)
	begin
		--seg_file(0) <= "0010";
		if FPGA_RSTB = '0' then
			screen_out <= "010";
			-- cursor := "0000";
			enter <= "000";
			
			bc_clicked <= '1';
			
			for i in 0 to 5 loop
				seg_file(i) <= X"0";
			end loop;
			
			for i in 0 to 5 loop
				wc_file(i) <= X"0";
			end loop;
			
			for i in 0 to 31 loop
				reg_file(i) <= X"20";
			end loop;
			
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
			
		elsif rising_edge(clk_50) then		-- 0~9 display
			if screen_in /= "010" then
				screen_out <= "010";
			end if;
			
			if screen_in = "010" then
				if(push_ul = '1' and bc_clicked = '0') then      --assuming active-high
					seg_file(conv_integer(enter)) <= binary;
					wc_file(conv_integer(enter)) <= binary;
					enter <= enter + 1;
				end if;
				bc_clicked <= push_ul;
				
				if push_dc = '0' then
					screen_out <= "100";
				elsif push_dr = '0' then
					screen_out <= "000";
				end if;
			end if;
		end if;
		
--		if push_dr = '0' then					-- 커서 오른쪽으로 이동했을 때 
--			if dr_clicked = '0' then
--				if cursor = "1001" then
--					cursor := "1001";
--				else
--					cursor := cursor + 1;
--				end if;
--				dr_clicked <= '1';
--			end if;
--		elsif push_dl = '0' then				-- 커서 왼쪽으로 이동했을 때
--			if dl_clicked = '0' then
--				if cursor = "0000" then
--					cursor := "0000";
--				else
--					cursor := cursor - 1;
--				end if;
--				dl_clicked <= '1';
--			end if;
--		end if;
--		
--		if push_dr = '1' then					-- 커서 오른쪽으로 이동했을 때 
--			dr_clicked <= '0';
--		elsif push_dl = '1' then				-- 커서 왼쪽으로 이동했을 때
--			dl_clicked <= '0';
--		end if;
		
		
		
--		if (push_dc = '0' and Enter = "000") then
--			--Enter := Enter + 1;
--			seg_file(0) <= "0000" + cursor;
--		elsif (push_dc = '0' and Enter = "001") then
--			--Enter := Enter + 1;
--			seg_file(1) <= "0000" + cursor;
--		elsif (push_dc = '0' and Enter = "010") then
--			--Enter := Enter + 1;
--			seg_file(2) <= "0000" + cursor;
--		elsif (push_dc = '0' and Enter = "011") then
--			--Enter := Enter + 1;
--			seg_file(3) <= "0000" + cursor;
--		elsif (push_dc = '0' and Enter = "100") then
--			--Enter := Enter + 1;
--			seg_file(4) <= "0000" + cursor;
--		elsif (push_dc = '0' and Enter = "101") then
--			--Enter := Enter + 1;
--			seg_file(5) <= "0000" + cursor;
--		end if;
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
				if cnt_reg = X"1F" then								-- lcd 31자리까지 갔을 때
					cnt_reg <= (others => '0');
				else
					cnt_reg <= cnt_reg + 1;
				end if;
			else
				lcd_data_out <= '0';
			end if;
		end if;
	end process;
	
	
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
--			if seg_w_enable = '1' then
--				
--			else
--				seg_data_out <= '0'; -- do not write
--			end if;
		end if;
	end process;


	process(FPGA_RSTB, CLK)											-- read screen으로 보내는 데이터
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

