library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
--use ieee.numeric_std.all;
use IEEE.STD_LOGIC_UNSIGNED.ALL;
USE IEEE.STD_LOGIC_ARITH.ALL;

entity screen_write is
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
           sl_enable : in  STD_LOGIC;
           sl_data_out : out  STD_LOGIC;
           sl_addr : out  STD_LOGIC_VECTOR (4 downto 0);
           sl_data : out  STD_LOGIC_VECTOR (7 downto 0);
           wc_enable : out  STD_LOGIC;
           wc_data_out : in  STD_LOGIC;
           wc_addr : in  STD_LOGIC_VECTOR (5 downto 0);
           wc_data : in  STD_LOGIC_VECTOR (3 downto 0)
           );
           
end screen_write;


architecture Behavioral of screen_write is

type reg is array( 0 to 31 ) of std_logic_vector( 7 downto 0 );
signal letter_reg_file : reg; 
signal encode_letter : reg;                                       

type seg_reg is array( 0 to 5 ) of std_logic_vector( 3 downto 0 ); -- 2D array declare
signal c_reg_file: seg_reg;
signal reg_file : seg_reg;

type segmentset is array( 0 to 5 ) of std_logic_vector( 3 downto 0 ); 
signal seg_reg_file : segmentset;


signal w_enable_reg : std_logic;
signal lcd_cnt : std_logic_vector (8 downto 0);
signal lcd_state : std_logic_vector (7 downto 0);
signal lcd_db : std_logic_vector (7 downto 0);

signal cnt : std_logic_vector(4 downto 0);
signal cnt_lcd : std_logic_vector(5 downto 0);
signal cnt_seg_reg: std_logic_vector (2 downto 0);


signal count : std_logic_vector (1 downto 0);
signal first, second : std_logic_vector (3 downto 0);
signal csr : std_logic_vector( 4 downto 0);

signal sl_data_beforeencode : STD_LOGIC_VECTOR (7 downto 0);
signal syn_code : STD_LOGIC_VECTOR (7 downto 0);

signal s10_clk, s01_clk, m10_clk, m01_clk, h10_clk, h01_clk: std_logic;--초, 분, 시의 클락 내부신호
signal hr10_cnt, hr01_cnt: std_logic_vector(3 downto 0);--시간을 카운트하는 내부신호 
signal min10_cnt, min01_cnt: std_logic_vector(3 downto 0);--분을 카운트하는 내부신호
signal sec10_cnt, sec01_cnt: std_logic_vector(3 downto 0);--초를 카운트하는 내부신호

signal sl_cnt : std_logic_vector(4 downto 0);

begin
	process(FPGA_RSTB,CLK)--rst_n과 clk에 대한 프로세스
		variable count_clk: integer range 0 to 2000000;--변수 count_clk의 범위 지정
	begin--4MHz가 2000000번 진동하는 데 0.5초가 걸린다
		if(FPGA_RSTB='0') then--rst_n이 0일때
			s01_clk<='1';--초의 일의자리 클락이 1이다
			count_clk:=0;--클락 카운트는 0으로 돌아간다
		elsif(clk'event and clk='1') then--clk가 rising edge일 때
			if(count_clk=2000000) then--count_clk가 2000000일때(0.5초 경과 시점)
				count_clk:=0;--count_clk가 0으로 돌아간다
				s01_clk<=not s01_clk;--1초의 주기를 원하기 때문에 0.5초마다 반전시켜준다
			else
				count_clk:=count_clk+1;--count_clk가 2000000될때까지 1씩 오른다
			end if;
		end if;
	end process;
	

	process(s01_clk, FPGA_RSTB)--s01_clk, rst_n에 대한 프로세스
	variable h10_cnt, h01_cnt:STD_LOGIC_VECTOR(3 downto 0);--시간을 나타내는 변수. 3downto0인 이유는 0부터 9를 표현하기 위해서
	variable m10_cnt, m01_cnt:STD_LOGIC_VECTOR(3 downto 0);--분을 나타내는 변수
	variable s10_cnt, s01_cnt:STD_LOGIC_VECTOR(3 downto 0);--초를 나타내는 변수
	begin
		if(FPGA_RSTB='0') then--rst_n이 0이면
		s01_cnt:="1001";--초의 일의자리는 9
		s10_cnt:="0000";--초의 십의자리는 0
		m01_cnt:="1001";--분의 일의자리는 9
		m10_cnt:="0000";--분의 십의자리는 0
		h01_cnt:="1001";--시의 일의자리는 9
		h10_cnt:="0000";--시의 십의자리는 0 리셋했을 때 결과를 모두 합치면 09시 9분 9초가 된다
		elsif(s01_clk'event and s01_clk='1') then--s01_clk이 1이 되었을때. 1초가 흘렀을 때를 나타낸다
			s01_cnt:=s01_cnt+1;--s01_cnt가 1 오른다
				if(s01_cnt>"1001") then--초의 일의자리가 9보다크면
					s01_cnt:="0000";--초의 일의자리가 0으로 돌아간다
					s10_clk<='1';
					s10_cnt:=s10_cnt+1;--초의 십의자리가 1오른다
				end if;
				if(s10_cnt>"0101") then--초의 십의자리가 5보다 크면
					s10_cnt:="0000";--초의 십의자리가 0으로 돌아간다
					m01_clk<='1';
					m01_cnt:=m01_cnt+1;--분의 일의자리가 1 오른다
				end if;
				if(m01_cnt>"1001") then--분의 일의자리가 9보다 크면
					m01_cnt:="0000";--분의 일의자리가 0으로 돌아간다
					m10_clk<='1';
					m10_cnt:=m10_cnt+1;--분의 십의자리가 1 오른다
				end if;
				if(m10_cnt>"0101") then--분의 십의자리가 5보다 크면
					m10_cnt:="0000";--분의 십의자리가 0으로 돌아간다
					h01_clk<='1';
					h01_cnt:=h01_cnt+1;--시의 일의자리가 1 오른다
				end if;
				if(h01_cnt>"1001") then--시의 일의자리가 9보다 크면
					h01_cnt:="0000";--시의 일의자리가 0으로 돌아간다
					h10_cnt:=h10_cnt+1;--시의 십의자리가 1 오른다
				end if;
				if(h01_cnt>"0010" and h10_cnt="0001") then--시의 일의자리가 2보다 크고 시의 십의자리가 1일때
					h10_cnt:="0000";--시의 십의자리가 0으로 돌아간다
					h01_cnt:="0001";--시의 일의자리가 1이 된다
				end if;--12시에서 13시로오르는 것이 아닌 1시로 오르는것을 표현한 if문이다
		end if;
		
		sec01_cnt<=s01_cnt;--각 자리의 카운트들을 지정했던 내부신호에 넣어준다
		sec10_cnt<=s10_cnt;
		min01_cnt<=m01_cnt;
		min10_cnt<=m10_cnt;
		hr01_cnt<=h01_cnt;
		hr10_cnt<=h10_cnt;
		
		end process;
----------------------------------------------------------------------------------------------------


   process(FPGA_RSTB, CLK)                                         
   begin
      if (FPGA_RSTB='0') then
			csr <= "00000";
         screen_out <= "100";
      elsif(CLK='1'and CLK'event) then      
			if screen_in /= "100" then
				screen_out <= "100";
			end if;
			
			if screen_in = "100" then
				if(push_uc = '0') then
					csr<= csr + 1;      
					if(csr= "11001")then
						csr<="11001";
					end if;
				elsif(push_ul = '0') then
					csr<= csr - 1;
					if(csr = "00000")then
						csr <= "00000";
					end if;
				elsif(push_dr = '0') then
					screen_out<="000";                                  
				end if;
			end if;
		end if;
   end process;
   
---------------------------------------------값   
   PROCESS( FPGA_RSTB , CLK ) 
   begin
      if(FPGA_RSTB='0')then
         count <= "00";
			
			for i in 0 to 31 loop
            letter_reg_file(i) <= X"20";                                 
         end loop;
         
      elsif(CLK = '1' and CLK'event)then
			if screen_in = "100" then
				if(push_ur = '0' and count ="00" )then
					count <= "01";
					first<=binary;  
					
				end if;
				
				if(push_ur = '0' and  count = "01")then 
					second <= binary;
					count <= "00";
					letter_reg_file(conv_integer(csr)) <= first & second ;      
				end if;
				
				if (push_dc='0') then
					if hr10_cnt < "1010" then
						letter_reg_file(26) <= hr10_cnt + X"30";--아스키코드와의 차이를 메꿈
					else
						letter_reg_file(26) <= hr10_cnt + X"37";--아스키코드와의 차이를 메꿈
					end if;
					
					if hr01_cnt < "1010" then
						letter_reg_file(27) <= hr01_cnt + X"30";--아스키코드와의 차이를 메꿈
					else
						letter_reg_file(27) <= hr01_cnt + X"37";--아스키코드와의 차이를 메꿈
					end if;			
					
					if min10_cnt < "1010" then
						letter_reg_file(28) <= min10_cnt + X"30";--아스키코드와의 차이를 메꿈
					else
						letter_reg_file(28) <= min10_cnt + X"37";--아스키코드와의 차이를 메꿈
					end if;
					
					if min01_cnt < "1010" then
						letter_reg_file(29) <= min01_cnt + X"30";--아스키코드와의 차이를 메꿈
					else
						letter_reg_file(29) <= min01_cnt + X"37";--아스키코드와의 차이를 메꿈
					end if;

					if sec10_cnt < "1010" then
						letter_reg_file(30) <= sec10_cnt + X"30";--아스키코드와의 차이를 메꿈
					else
						letter_reg_file(30) <= sec10_cnt + X"37";--아스키코드와의 차이를 메꿈
					end if;
					
					if sec01_cnt < "1010" then
						letter_reg_file(31) <= sec01_cnt + X"30";--아스키코드와의 차이를 메꿈
					else
						letter_reg_file(31) <= sec01_cnt + X"37";--아스키코드와의 차이를 메꿈
					end if;					
				end if;
			end if;
      end if;
   end process;
	


--sl_addr <= csr;
--sl_data_beforeencode <= letter_reg_file(conv_integer(csr));
----커서 문제생기면 레그파일 노가다
--
--sl_data <= sl_data_beforeencode xor syn_code; -- 암호화!!!

	
	process(FPGA_RSTB, CLK)
	begin
		if FPGA_RSTB = '0' then
			for i in 0 to 31 loop
				encode_letter(i) <= X"20";
			end loop;
		elsif CLK = '1' and CLK'event then
			encode_letter(conv_integer(csr)) <= letter_reg_file(conv_integer(csr)) xor syn_code;
		end if;
	end process;
	
	process(FPGA_RSTB, CLK)
	Begin
		if FPGA_RSTB ='0' then
			sl_cnt <= (others => '0');
			sl_data_out <= '0';
		elsif CLK='1' and CLK'event then
			if sl_enable = '1' then
				sl_data <= encode_letter(conv_integer(sl_cnt));
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
	
	process(FPGA_RSTB, CLK)
	begin
		if FPGA_RSTB = '0' then
			cnt_lcd <= (others => '0');
			lcd_data_out <= '0';
		elsif CLK = '1' and CLK'event then
			if lcd_w_enable = '1' then				
				lcd_data <= letter_reg_file(conv_integer(csr));
				lcd_addr <= csr;
				lcd_data_out <= '1';
				if cnt_lcd = "100000" then	
					cnt_lcd <= (others => '0');
				else
					cnt_lcd <= cnt_lcd + 1;
				end if;
			else
				lcd_data_out <= '0';
			end if;
		end if;
	end process;
	


-- 이 이하는 암호화를 하기 위한 난수코드(syn code)를 만들기 위한 것이다
-- 난수코드는 내맘대로 만든거긴한데, 기존의 코드를 내맘대로 순서 한번 섞어주고 뒷자리 2개1개1개1개1개2개 해서 8자리로 만든다.
process(FPGA_RSTB, CLK)
begin
   if FPGA_RSTB ='0' then
      syn_code <= (others => '0');
   elsif CLK='1' and CLK'event then
      if wc_data_out = '1' then
         syn_code(7 downto 6) <= c_reg_file(3)(1 downto 0);      -- 섹렉파일은 6자리 코드를 2비트 array로타나낸거
         syn_code(5) <= c_reg_file(0)(0);
         syn_code(4) <= c_reg_file(5)(0);
         syn_code(3) <= c_reg_file(4)(0);
         syn_code(2) <= c_reg_file(1)(0);
         syn_code(1 downto 0) <= c_reg_file(2)(1 downto 0);
      end if;
   end if;
end process;


--------------------------------- c_reg_file 만들기




process(FPGA_RSTB, CLK)-- 이게 진짜 시레그만드는거
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



-- 민지(동일한게 스크린 리드에도 있고 이건 수정해야됨.)
process(push_dl,CLK) 
Begin
	if screen_in = "100" then
		if (push_dl='0') then
			seg_reg_file(0)<=c_reg_file(0);
			seg_reg_file(1)<=c_reg_file(1);
			seg_reg_file(2)<=c_reg_file(2);
			seg_reg_file(3)<=c_reg_file(3);
			seg_reg_file(4)<=c_reg_file(4);
			seg_reg_file(5)<=c_reg_file(5);
		else
			for i in 0 to 5 loop
				seg_reg_file(i) <= "0000";
			end loop;
		end if;
	end if;
end process;

	
	process(FPGA_RSTB, CLK)
	Begin
		if FPGA_RSTB ='0' then
			cnt_seg_reg <= (others => '0');
			seg_data_out <= '0';
		elsif CLK='1' and CLK'event then
			seg_data <= seg_reg_file(conv_integer(cnt_seg_reg));
				seg_addr <= cnt_seg_reg;
				seg_data_out <= '1';
			if cnt_seg_reg = "101" then								-- segment 6자리까지 갔을 때
				cnt_seg_reg <= (others => '0');
			else
				cnt_seg_reg <= cnt_seg_reg + 1;
			end if;
		end if;
	end process;

   
end Behavioral;

