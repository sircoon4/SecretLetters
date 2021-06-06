library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;
USE IEEE.STD_LOGIC_ARITH.ALL;

entity screen_write is
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

			-- encrypted letter to main screen
			sl_enable : in  STD_LOGIC;
			sl_data_out : out  STD_LOGIC;
			sl_addr : out  STD_LOGIC_VECTOR (4 downto 0);
			sl_data : out  STD_LOGIC_VECTOR (7 downto 0);

			-- 6 digit code for encryption from write code screen
			wc_enable : out  STD_LOGIC;
			wc_data_out : in  STD_LOGIC;
			wc_addr : in  STD_LOGIC_VECTOR (2 downto 0);
			wc_data : in  STD_LOGIC_VECTOR (3 downto 0)
			);
end screen_write;


architecture Behavioral of screen_write is

-- Generate timer 관련 signal
signal s10_clk, s01_clk, m10_clk, m01_clk, h10_clk, h01_clk: std_logic;
signal hr10_cnt, hr01_cnt: std_logic_vector(3 downto 0);
signal min10_cnt, min01_cnt: std_logic_vector(3 downto 0);
signal sec10_cnt, sec01_cnt: std_logic_vector(3 downto 0);

-- clock 관련 signal
signal load_100k : std_logic;
signal clk_100k : std_logic; -- 100KHz clock
signal cnt_100k : std_logic_vector (7 downto 0);
signal load_50 : std_logic;
signal clk_50 : std_logic; -- 50Hz clock
signal cnt_50 : std_logic_vector (11 downto 0);

-- 편지 암호화 관련 signals
type reg is array( 0 to 31 ) of std_logic_vector( 7 downto 0 );
signal letter_reg_file : reg; -- 작성중인 편지

type seg_reg is array( 0 to 5 ) of std_logic_vector( 3 downto 0 );
signal c_reg_file: seg_reg; -- write code
signal syn_code : STD_LOGIC_VECTOR (7 downto 0); -- 암호화 vector

-- 암호화된 편지 save to main screen 보조 signal
signal sl_cnt : std_logic_vector(4 downto 0);

-- 7 segments data 전송 관련 signals
type segmentset is array( 0 to 5 ) of std_logic_vector( 3 downto 0 ); 
signal seg_reg_file : segmentset;
signal cnt_seg_reg: std_logic_vector (2 downto 0);

-- lcd data 전송 보조 signal
signal cnt_lcd : std_logic_vector(4 downto 0);

-- 편지 글작성 보조 signals
signal count : std_logic_vector (1 downto 0); -- ASCII 앞 4 bit, 뒤 4 bit 선택
signal first, second : std_logic_vector (3 downto 0); -- ASCII 앞 4 bit, 뒤 4 bit memory
signal csr : std_logic_vector( 4 downto 0); -- cursor
signal last_csr : std_logic_vector( 4 downto 0); -- 이전 cursor 위치

-- button 중복 입력 방지 signals
signal ul_clicked : std_logic;
signal uc_clicked : std_logic;
signal ur_clicked : std_logic;
signal dc_clicked : std_logic;

-- current screen으로 지정시 한 번 setting을 위한 signal
signal screen_enter : std_logic;

begin
	-- Generate 1Hz clock into s01_clk
	process(FPGA_RSTB,CLK)--rst_n clk  
		variable count_clk: integer range 0 to 2000000;-- count_clk  
	begin--4MHz 2000000   0.5 
		if(FPGA_RSTB='0') then--rst_n 0
			s01_clk<='1';--   1
			count_clk:=0;--  0 
		elsif(clk'event and clk='1') then--clk rising edge 
			if(count_clk=2000000) then--count_clk 2000000(0.5  )
				count_clk:=0;--count_clk 0 
				s01_clk<=not s01_clk;--1    0.5 
			else
				count_clk:=count_clk+1;--count_clk 2000000 1 
			end if;
		end if;
	end process;
	
	-- s01_clk 기반으로 시간 데이터를 생성해 signal에 저장
	process(s01_clk, FPGA_RSTB)--s01_clk, rst_n  
		variable h10_cnt, h01_cnt:STD_LOGIC_VECTOR(3 downto 0);--  . 3downto0  0 9  
		variable m10_cnt, m01_cnt:STD_LOGIC_VECTOR(3 downto 0);--  
		variable s10_cnt, s01_cnt:STD_LOGIC_VECTOR(3 downto 0);--  
	begin
		if(FPGA_RSTB='0') then--rst_n 0
			s01_cnt:="1001";--  9
			s10_cnt:="0000";--  0
			m01_cnt:="1001";--  9
			m10_cnt:="0000";--  0
			h01_cnt:="1001";--  9
			h10_cnt:="0000";--  0      09 9 9 
		elsif(s01_clk'event and s01_clk='1') then--s01_clk 1 . 1   
			s01_cnt:=s01_cnt+1;--s01_cnt 1 
			if(s01_cnt>"1001") then--  9
				s01_cnt:="0000";--  0 
				s10_clk<='1';
				s10_cnt:=s10_cnt+1;--  1
			end if;
			if(s10_cnt>"0101") then--  5 
				s10_cnt:="0000";--  0 
				m01_clk<='1';
				m01_cnt:=m01_cnt+1;--  1 
			end if;
			if(m01_cnt>"1001") then--  9 
				m01_cnt:="0000";--  0 
				m10_clk<='1';
				m10_cnt:=m10_cnt+1;--  1 
			end if;
			if(m10_cnt>"0101") then--  5 
				m10_cnt:="0000";--  0 
				h01_clk<='1';
				h01_cnt:=h01_cnt+1;--  1 
			end if;
			if(h01_cnt>"1001") then--  9 
				h01_cnt:="0000";--  0 
				h10_cnt:=h10_cnt+1;--  1 
			end if;
			if(h01_cnt>"0010" and h10_cnt="0001") then--  2    1
				h10_cnt:="0000";--  0 
				h01_cnt:="0001";--  1 
			end if;--12 13   1   if
		end if;
		
		sec01_cnt<=s01_cnt; -- 1초
		sec10_cnt<=s10_cnt; -- 10초
		min01_cnt<=m01_cnt; -- 1분
		min10_cnt<=m10_cnt; -- 10분
		hr01_cnt<=h01_cnt; -- 1시간
		hr10_cnt<=h10_cnt; -- 10시간
		
	end process;

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
	
	-- Input 처리 process 정의
	-- push button이 두번 눌리는 것을 방지하기 위해 50Hz clock을 사용함.
   PROCESS( FPGA_RSTB , clk_50 )
   begin
      if(FPGA_RSTB='0')then -- 초기화
			screen_out <= "100";
			
         count <= "00";
			
			ul_clicked <= '1';
			uc_clicked <= '1';
			ur_clicked <= '1';
			dc_clicked <= '1';
			
			screen_enter <= '0';
			
			csr <= "00000";
			last_csr <= "11111";
			
			for i in 0 to 31 loop
            letter_reg_file(i) <= X"20";                                 
         end loop;
         
      elsif rising_edge (clk_50) then
			if screen_in /= "100" then -- screen이 넘어갈 때 setting
				screen_out <= "100";
				screen_enter <= '0';
			elsif screen_in = "100" then -- current screen일 때 동작
				if screen_enter = '0' then -- screen이 넘어올 때 한 번 setting
					csr <= "00000";
					last_csr <= "11111";
					
					for i in 0 to 31 loop
						letter_reg_file(i) <= X"20";                                 
					end loop;
					screen_enter <= '1';
				end if;
				
				if(push_ul = '1' and ul_clicked = '0') then -- up-left push button이 눌리면
					if count ="00" then -- count가 0이면 ASCII에 first 4bit를 채워서 letter에 저장
						count <= "01";
						first<=binary;
						letter_reg_file(conv_integer(csr)) <= binary & "0000";
					end if;
				end if;
				ul_clicked <= push_ul; -- push button이 두번 눌리는 것을 방지
				
				if(push_uc = '1' and uc_clicked = '0') then -- up-center push button이 눌리면
					if count = "01" then -- count가 1이면 ASCII에 second 4bit를 채워서 letter에 저장
						count <= "00";
						letter_reg_file(conv_integer(csr)) <= first & binary;
					end if;
				end if;
				uc_clicked <= push_uc; -- push button이 두번 눌리는 것을 방지
				
				if(push_ur = '1' and ur_clicked = '0') then -- up-right push button이 눌리면 cursor를 우측으로 이동
					csr <= csr + 1;
				end if;
				ur_clicked <= push_ur; -- push button이 두번 눌리는 것을 방지
				
				if last_csr /= csr then -- cursor가 이동되면 이동된 위치에 검은 사각형으로 cursor 위치를 표시
					letter_reg_file(conv_integer(csr)) <= x"FF";
					last_csr <= csr; -- cursor가 이동된 순간에 한 번만 표시
				end if;
				
				if(push_dc = '1' and dc_clicked = '0') then -- down-center push button이 눌리면 clear 동작
					csr <= "00000";
					last_csr <= "11111";
					
					for i in 0 to 31 loop
						letter_reg_file(i) <= X"20";                                 
					end loop;
				end if;
				dc_clicked <= push_dc; -- push button이 두번 눌리는 것을 방지
				
				if(push_dr = '0') then -- down-right push button이 눌리면 main screen으로 이동
					screen_out<="000";                                  
				end if;
				
				-- letter 끝 6자리에 시간 표시
				letter_reg_file(26) <= hr10_cnt + X"30";
				letter_reg_file(27) <= hr01_cnt + X"30";
				letter_reg_file(28) <= min10_cnt + X"30";
				letter_reg_file(29) <= min01_cnt + X"30";
				letter_reg_file(30) <= sec10_cnt + X"30";
				letter_reg_file(31) <= sec01_cnt + X"30";
			end if;
      end if;
   end process;
	
	-- 작성중인 letter를 lcd data로 전송
	process(FPGA_RSTB, CLK)
	begin
		if FPGA_RSTB = '0' then
			cnt_lcd <= (others => '0');
			lcd_data_out <= '0';
		elsif CLK = '1' and CLK'event then
			if lcd_w_enable = '1' then				
				lcd_data <= letter_reg_file(conv_integer(cnt_lcd));
				lcd_addr <= cnt_lcd;
				lcd_data_out <= '1';
				if cnt_lcd = X"1F" then	
					cnt_lcd <= (others => '0');
				else
					cnt_lcd <= cnt_lcd + 1;
				end if;
			else
				lcd_data_out <= '0';
			end if;
		end if;
	end process;
	
	-- write code를 읽어들여 c_reg_file에 저장
	process(FPGA_RSTB, CLK)
	Begin
		if FPGA_RSTB ='0' then
			for i in 0 to 5 loop
				c_reg_file(0) <= X"0";
			end loop;
		elsif CLK='1' and CLK'event then
			if wc_data_out = '1' then
				c_reg_file (conv_integer (wc_addr)) <= wc_data;
			end if;
		end if;
	end process;

	-- write code를 8 bit binary 암호화 vector로 변경하는 process
	-- 암호화 vector를 syn_code signal에 저장
	process(FPGA_RSTB, CLK)
	begin
		if FPGA_RSTB ='0' then
			syn_code <= (others => '0');
		elsif CLK='1' and CLK'event then
			if wc_data_out = '1' then
				-- write code 6 digit 각 자리에서 한 자리나 두 자리의 binary를 추출하여 임의로 배치
				syn_code(7 downto 6) <= c_reg_file(3)(1 downto 0);
				syn_code(5) <= c_reg_file(0)(0);
				syn_code(4) <= c_reg_file(5)(0);
				syn_code(3) <= c_reg_file(4)(0);
				syn_code(2) <= c_reg_file(1)(0);
				syn_code(1 downto 0) <= c_reg_file(2)(1 downto 0);
			end if;
		end if;
	end process;
	
	-- main screen으로 letter를 암호화해서 전송
	process(FPGA_RSTB, CLK)
	Begin
		if FPGA_RSTB ='0' then
			sl_cnt <= (others => '0');
			sl_data_out <= '0';
		elsif CLK='1' and CLK'event then
			if sl_enable = '1' then
				sl_data <= letter_reg_file(conv_integer(sl_cnt)) xor syn_code; -- letter를 xor 연산으로 암호화
				sl_addr <= sl_cnt;
				sl_data_out <= '1';
				if sl_cnt= X"1F" then -- 3110
					sl_cnt <= (others =>'0');
				else
					sl_cnt <= sl_cnt + 1;
				end if;
			else
				sl_data_out <= '0';
			end if;
		end if;
	end process;

	-- 7 segments data 정의 process
	process(push_dl,CLK) 
	Begin
		if screen_in = "100" then
			if (push_dl='0') then -- down-left push button이 눌리는 동안 write code를 segments data로 지정
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

