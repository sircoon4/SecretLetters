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

signal s10_clk, s01_clk, m10_clk, m01_clk, h10_clk, h01_clk: std_logic;--��, ��, ���� Ŭ�� ���ν�ȣ
signal hr10_cnt, hr01_cnt: std_logic_vector(3 downto 0);--�ð��� ī��Ʈ�ϴ� ���ν�ȣ 
signal min10_cnt, min01_cnt: std_logic_vector(3 downto 0);--���� ī��Ʈ�ϴ� ���ν�ȣ
signal sec10_cnt, sec01_cnt: std_logic_vector(3 downto 0);--�ʸ� ī��Ʈ�ϴ� ���ν�ȣ

signal sl_cnt : std_logic_vector(4 downto 0);

begin
	process(FPGA_RSTB,CLK)--rst_n�� clk�� ���� ���μ���
		variable count_clk: integer range 0 to 2000000;--���� count_clk�� ���� ����
	begin--4MHz�� 2000000�� �����ϴ� �� 0.5�ʰ� �ɸ���
		if(FPGA_RSTB='0') then--rst_n�� 0�϶�
			s01_clk<='1';--���� �����ڸ� Ŭ���� 1�̴�
			count_clk:=0;--Ŭ�� ī��Ʈ�� 0���� ���ư���
		elsif(clk'event and clk='1') then--clk�� rising edge�� ��
			if(count_clk=2000000) then--count_clk�� 2000000�϶�(0.5�� ��� ����)
				count_clk:=0;--count_clk�� 0���� ���ư���
				s01_clk<=not s01_clk;--1���� �ֱ⸦ ���ϱ� ������ 0.5�ʸ��� ���������ش�
			else
				count_clk:=count_clk+1;--count_clk�� 2000000�ɶ����� 1�� ������
			end if;
		end if;
	end process;
	

	process(s01_clk, FPGA_RSTB)--s01_clk, rst_n�� ���� ���μ���
	variable h10_cnt, h01_cnt:STD_LOGIC_VECTOR(3 downto 0);--�ð��� ��Ÿ���� ����. 3downto0�� ������ 0���� 9�� ǥ���ϱ� ���ؼ�
	variable m10_cnt, m01_cnt:STD_LOGIC_VECTOR(3 downto 0);--���� ��Ÿ���� ����
	variable s10_cnt, s01_cnt:STD_LOGIC_VECTOR(3 downto 0);--�ʸ� ��Ÿ���� ����
	begin
		if(FPGA_RSTB='0') then--rst_n�� 0�̸�
		s01_cnt:="1001";--���� �����ڸ��� 9
		s10_cnt:="0000";--���� �����ڸ��� 0
		m01_cnt:="1001";--���� �����ڸ��� 9
		m10_cnt:="0000";--���� �����ڸ��� 0
		h01_cnt:="1001";--���� �����ڸ��� 9
		h10_cnt:="0000";--���� �����ڸ��� 0 �������� �� ����� ��� ��ġ�� 09�� 9�� 9�ʰ� �ȴ�
		elsif(s01_clk'event and s01_clk='1') then--s01_clk�� 1�� �Ǿ�����. 1�ʰ� �귶�� ���� ��Ÿ����
			s01_cnt:=s01_cnt+1;--s01_cnt�� 1 ������
				if(s01_cnt>"1001") then--���� �����ڸ��� 9����ũ��
					s01_cnt:="0000";--���� �����ڸ��� 0���� ���ư���
					s10_clk<='1';
					s10_cnt:=s10_cnt+1;--���� �����ڸ��� 1������
				end if;
				if(s10_cnt>"0101") then--���� �����ڸ��� 5���� ũ��
					s10_cnt:="0000";--���� �����ڸ��� 0���� ���ư���
					m01_clk<='1';
					m01_cnt:=m01_cnt+1;--���� �����ڸ��� 1 ������
				end if;
				if(m01_cnt>"1001") then--���� �����ڸ��� 9���� ũ��
					m01_cnt:="0000";--���� �����ڸ��� 0���� ���ư���
					m10_clk<='1';
					m10_cnt:=m10_cnt+1;--���� �����ڸ��� 1 ������
				end if;
				if(m10_cnt>"0101") then--���� �����ڸ��� 5���� ũ��
					m10_cnt:="0000";--���� �����ڸ��� 0���� ���ư���
					h01_clk<='1';
					h01_cnt:=h01_cnt+1;--���� �����ڸ��� 1 ������
				end if;
				if(h01_cnt>"1001") then--���� �����ڸ��� 9���� ũ��
					h01_cnt:="0000";--���� �����ڸ��� 0���� ���ư���
					h10_cnt:=h10_cnt+1;--���� �����ڸ��� 1 ������
				end if;
				if(h01_cnt>"0010" and h10_cnt="0001") then--���� �����ڸ��� 2���� ũ�� ���� �����ڸ��� 1�϶�
					h10_cnt:="0000";--���� �����ڸ��� 0���� ���ư���
					h01_cnt:="0001";--���� �����ڸ��� 1�� �ȴ�
				end if;--12�ÿ��� 13�÷ο����� ���� �ƴ� 1�÷� �����°��� ǥ���� if���̴�
		end if;
		
		sec01_cnt<=s01_cnt;--�� �ڸ��� ī��Ʈ���� �����ߴ� ���ν�ȣ�� �־��ش�
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
   
---------------------------------------------��   
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
						letter_reg_file(26) <= hr10_cnt + X"30";--�ƽ�Ű�ڵ���� ���̸� �޲�
					else
						letter_reg_file(26) <= hr10_cnt + X"37";--�ƽ�Ű�ڵ���� ���̸� �޲�
					end if;
					
					if hr01_cnt < "1010" then
						letter_reg_file(27) <= hr01_cnt + X"30";--�ƽ�Ű�ڵ���� ���̸� �޲�
					else
						letter_reg_file(27) <= hr01_cnt + X"37";--�ƽ�Ű�ڵ���� ���̸� �޲�
					end if;			
					
					if min10_cnt < "1010" then
						letter_reg_file(28) <= min10_cnt + X"30";--�ƽ�Ű�ڵ���� ���̸� �޲�
					else
						letter_reg_file(28) <= min10_cnt + X"37";--�ƽ�Ű�ڵ���� ���̸� �޲�
					end if;
					
					if min01_cnt < "1010" then
						letter_reg_file(29) <= min01_cnt + X"30";--�ƽ�Ű�ڵ���� ���̸� �޲�
					else
						letter_reg_file(29) <= min01_cnt + X"37";--�ƽ�Ű�ڵ���� ���̸� �޲�
					end if;

					if sec10_cnt < "1010" then
						letter_reg_file(30) <= sec10_cnt + X"30";--�ƽ�Ű�ڵ���� ���̸� �޲�
					else
						letter_reg_file(30) <= sec10_cnt + X"37";--�ƽ�Ű�ڵ���� ���̸� �޲�
					end if;
					
					if sec01_cnt < "1010" then
						letter_reg_file(31) <= sec01_cnt + X"30";--�ƽ�Ű�ڵ���� ���̸� �޲�
					else
						letter_reg_file(31) <= sec01_cnt + X"37";--�ƽ�Ű�ڵ���� ���̸� �޲�
					end if;					
				end if;
			end if;
      end if;
   end process;
	


--sl_addr <= csr;
--sl_data_beforeencode <= letter_reg_file(conv_integer(csr));
----Ŀ�� ��������� �������� �밡��
--
--sl_data <= sl_data_beforeencode xor syn_code; -- ��ȣȭ!!!

	
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
	


-- �� ���ϴ� ��ȣȭ�� �ϱ� ���� �����ڵ�(syn code)�� ����� ���� ���̴�
-- �����ڵ�� ������� ����ű��ѵ�, ������ �ڵ带 ������� ���� �ѹ� �����ְ� ���ڸ� 2��1��1��1��1��2�� �ؼ� 8�ڸ��� �����.
process(FPGA_RSTB, CLK)
begin
   if FPGA_RSTB ='0' then
      syn_code <= (others => '0');
   elsif CLK='1' and CLK'event then
      if wc_data_out = '1' then
         syn_code(7 downto 6) <= c_reg_file(3)(1 downto 0);      -- ���������� 6�ڸ� �ڵ带 2��Ʈ array��Ÿ������
         syn_code(5) <= c_reg_file(0)(0);
         syn_code(4) <= c_reg_file(5)(0);
         syn_code(3) <= c_reg_file(4)(0);
         syn_code(2) <= c_reg_file(1)(0);
         syn_code(1 downto 0) <= c_reg_file(2)(1 downto 0);
      end if;
   end if;
end process;


--------------------------------- c_reg_file �����




process(FPGA_RSTB, CLK)-- �̰� ��¥ �÷��׸���°�
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



-- ����(�����Ѱ� ��ũ�� ���忡�� �ְ� �̰� �����ؾߵ�.)
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
			if cnt_seg_reg = "101" then								-- segment 6�ڸ����� ���� ��
				cnt_seg_reg <= (others => '0');
			else
				cnt_seg_reg <= cnt_seg_reg + 1;
			end if;
		end if;
	end process;

   
end Behavioral;

