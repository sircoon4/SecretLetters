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
           wc_addr : out  STD_LOGIC_VECTOR (5 downto 0);
           wc_data : out  STD_LOGIC_VECTOR (3 downto 0));
end screen_code_write;
--screen code write
architecture Behavioral of screen_code_write is

--kmj
type reg is array( 0 to 31 ) of std_logic_vector( 7 downto 0 );
signal reg_file : reg;



--kmj clock-------------------------------------------------------------------------------------------------

signal s10_clk, s01_clk, m10_clk, m01_clk, h10_clk, h01_clk: std_logic;--��, ��, ���� Ŭ�� ���ν�ȣ
signal hr10_cnt, hr01_cnt: std_logic_vector(3 downto 0);--�ð��� ī��Ʈ�ϴ� ���ν�ȣ 
signal min10_cnt, min01_cnt: std_logic_vector(3 downto 0);--���� ī��Ʈ�ϴ� ���ν�ȣ
signal sec10_cnt, sec01_cnt: std_logic_vector(3 downto 0);--�ʸ� ī��Ʈ�ϴ� ���ν�ȣ

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
	now

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
		h10_cnt:="0000";--���� �����ڸ��� 0 �������� �� ����� ��� ��ġ�� 08�� 08�� 08�ʰ� �ȴ�
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


--kmj		
		if (push_dc='0') then
			
					if hr10_cnt < "1010" then
						reg_file(26) <= hr10_cnt + X"30";--�ƽ�Ű�ڵ���� ���̸� �޲�
					else
						reg_file(26) <= hr10_cnt + X"37";--�ƽ�Ű�ڵ���� ���̸� �޲�
					end if;
					
					if hr01_cnt < "1010" then
						reg_file(27) <= hr01_cnt + X"30";--�ƽ�Ű�ڵ���� ���̸� �޲�
					else
						reg_file(27) <= hr01_cnt + X"37";--�ƽ�Ű�ڵ���� ���̸� �޲�
					end if;			
					
					if min10_cnt < "1010" then
						reg_file(28) <= min10_cnt + X"30";--�ƽ�Ű�ڵ���� ���̸� �޲�
					else
						reg_file(28) <= min10_cnt + X"37";--�ƽ�Ű�ڵ���� ���̸� �޲�
					end if;
					
					if min01_cnt < "1010" then
						reg_file(29) <= min01_cnt + X"30";--�ƽ�Ű�ڵ���� ���̸� �޲�
					else
						reg_file(29) <= min01_cnt + X"37";--�ƽ�Ű�ڵ���� ���̸� �޲�
					end if;

					if sec10_cnt < "1010" then
						reg_file(30) <= sec10_cnt + X"30";--�ƽ�Ű�ڵ���� ���̸� �޲�
					else
						reg_file(30) <= sec10_cnt + X"37";--�ƽ�Ű�ڵ���� ���̸� �޲�
					end if;
					
					if sec01_cnt < "1010" then
						reg_file(31) <= sec01_cnt + X"30";--�ƽ�Ű�ڵ���� ���̸� �޲�
					else
						reg_file(31) <= sec01_cnt + X"37";--�ƽ�Ű�ڵ���� ���̸� �޲�
					end if;					
			end if;		
----------------------------------------------------------------------

process(FPGA_RSTB, CLK)--FPGA_RSTB, CLK�� ���� process
	Begin
		if FPGA_RSTB = '0' then--FPGA_RSTB�� 0�̸� ����
			for i in 0 to 31 loop--i�� 0~31�϶�
				reg_file(i)<=X"20";--blank�̴�
			end loop;
		elsif CLK'event and CLK='1' then--clk�� rising edge�� �� 
			if w_enable_reg ='1' and data_out ='1' then--w_enable_reg, data_out�� 1�̸�
				reg_file(conv_integer(addr)) <= data;--reg_file�� data�� �ִ´�
			end if;
		end if;
end process;

----------------------------------------------------------------------------------------------------
type c_reg is array(0 to 5) of std_logic_vector (3 downto 0);
signal c_reg_file: c_reg;


process(FPGA_RSTB, CLK)--FPGA_RSTB, CLK�� ���� process
	Begin
		if FPGA_RSTB = '0' then--FPGA_RSTB�� 0�̸� ����
			for i in 0 to 5 loop--i�� 0~31�϶�
				c_reg_file(i)<="0000";--blank�̴�
			end loop;
		elsif CLK'event and CLK='1' then--clk�� rising edge�� �� 
			if w_enable_reg ='1' and data_out ='1' then--w_enable_reg, data_out�� 1�̸�
				c_reg_file(conv_integer(addr)) <= data;--reg_file�� data�� �ִ´�
			end if;
		end if;
end process;

--��ư ������ �� c_reg
--seg_reg_file�� ������
--��ҿ��� 0000000


type seg_reg is array(0 to 5) of std_logic_vector (3 downto 0);
signal seg_reg_file: seg_reg;

if (push_dl='0') then
	for i in 0 to 5 loop
		seg_reg_file(i)<="0000";
	end loop;
else
	seg_reg_file(0)<=c_reg_file(0);
	seg_reg_file(1)<=c_reg_file(1);
	seg_reg_file(2)<=c_reg_file(2);
	seg_reg_file(3)<=c_reg_file(3);
	seg_reg_file(4)<=c_reg_file(4);
	seg_reg_file(5)<=c_reg_file(5);
	
end if;
	

end Behavioral;

