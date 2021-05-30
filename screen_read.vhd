library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

entity screen_read is
    Port ( FPGA_RSTB : in  STD_LOGIC;
           CLK : in  STD_LOGIC;
           lcd_w_enable : in  STD_LOGIC; -- ����� �����ߵ�.. LCD ��ȣȭǮ����
           lcd_data_out : out  STD_LOGIC;
           lcd_addr : out  STD_LOGIC_VECTOR (4 downto 0);
           lcd_data : out  STD_LOGIC_VECTOR (7 downto 0);
           seg_w_enable : in  STD_LOGIC; -- ����� �����°� ���׸�Ʈ�� ������ �ڵ� �״��..
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
           rl_enable : out  STD_LOGIC; -- LCD ȭ��(��ȣȭ�Ȱ� ���´�)
           rl_data_out : in  STD_LOGIC;
           rl_addr : in  STD_LOGIC_VECTOR (4 downto 0);
           rl_data : in  STD_LOGIC_VECTOR (7 downto 0);
           rc_enable : out  STD_LOGIC; -- ���׸�Ʈ ȭ��
           rc_data_out : in  STD_LOGIC;
           rc_addr : in  STD_LOGIC_VECTOR (5 downto 0); -- digit
           rc_data : in  STD_LOGIC_VECTOR (3 downto 0)); 
end screen_read;

architecture Behavioral of screen_read is

signal r1_data_decode : STD_LOGIC_VECTOR (7 downto 0);
signal syn_code : STD_LOGIC_VECTOR (7 downto 0);
type segmentset is array( 0 to 5 ) of std_logic_vector( 3 downto 0 ); -- 2D array declare
signal c_reg_file : segmentset;
type reg is array( 0 to 31 ) of std_logic_vector( 7 downto 0 );	-- 32(16*2)���� LCD display�� ���� data ���� ����
signal reg_file : reg;
signal cnt : std_logic_vector(4 downto 0);

begin
-- enable�� data_out�� ���� ������ �����ϰ� ���ǰ�...


r1_data_decode <= rl_data xor syn_code;

process(FPGA_RSTB, CLK)
begin
	if FPGA_RSTB ='0' then
		syn_code <= (others => '0');
	elsif CLK='1' and CLK'event then
		if rc_data_out = '1' then
			syn_code(7 downto 6) <= c_reg_file(3)(1 downto 0);
			syn_code(5) <= c_reg_file(0)(0);
			syn_code(4) <= c_reg_file(5)(0);
			syn_code(3) <= c_reg_file(4)(0);
			syn_code(2) <= c_reg_file(1)(0);
			syn_code(1 downto 0) <= c_reg_file(2)(1 downto 0);
		end if;
	end if;
end process;


--------------------------------- c_reg_file �����


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


---------------------------------------------- �������� ����
-- �ص��� r1_data_decode�� lcd�� �����ߵ�.


process(FPGA_RSTB, CLK, rc_addr)
begin
	if FPGA_RSTB ='0' then								-- FPGA_RSTB ��ư ���� ��,
		for i in 0 to 31 loop								-- 32(16*2)���� LCD display��
			reg_file(i) <= X"20";							-- initialize reg_file with 'space'
		end loop;
	elsif CLK='1' and CLK'event then					-- CLK�� rising edge ����,
		case rl_addr is
			when "00000" => reg_file(0) <= r1_data_decode;
			when "00001" => reg_file(1) <= r1_data_decode;
			when "00010" => reg_file(2) <= r1_data_decode;
			when "00011" => reg_file(3) <= r1_data_decode;
			when "00100" => reg_file(4) <= r1_data_decode;
			when "00101" => reg_file(5) <= r1_data_decode;
			when "00110" => reg_file(6) <= r1_data_decode;
			when "00111" => reg_file(7) <= r1_data_decode;
			when "01000" => reg_file(8) <= r1_data_decode;
			when "01001" => reg_file(9) <= r1_data_decode;
			when "01010" => reg_file(10) <= r1_data_decode;
			when "01011" => reg_file(11) <= r1_data_decode;
			when "01100" => reg_file(12) <= r1_data_decode;
			when "01101" => reg_file(13) <= r1_data_decode;
			when "01110" => reg_file(14) <= r1_data_decode;
			when "01111" => reg_file(15) <= r1_data_decode;
			when "10000" => reg_file(16) <= r1_data_decode;
			when "10001" => reg_file(17) <= r1_data_decode;
			when "10010" => reg_file(18) <= r1_data_decode;
			when "10011" => reg_file(19) <= r1_data_decode;
			when "10100" => reg_file(20) <= r1_data_decode;
			when "10101" => reg_file(21) <= r1_data_decode;
			when "10110" => reg_file(22) <= r1_data_decode;
			when "10111" => reg_file(23) <= r1_data_decode;
			when "11000" => reg_file(24) <= r1_data_decode;
			when "11001" => reg_file(25) <= r1_data_decode;
			when "11010" => reg_file(26) <= r1_data_decode;
			when "11011" => reg_file(27) <= r1_data_decode;
			when "11100" => reg_file(28) <= r1_data_decode;
			when "11101" => reg_file(29) <= r1_data_decode;
			when "11110" => reg_file(30) <= r1_data_decode;
			when others => reg_file(31) <= r1_data_decode;
		end case;
	end if;
end process;




process(FPGA_RSTB, CLK)
Begin
	if FPGA_RSTB ='0' then								-- FPGA_RSTB ��ư ���� ��,
		cnt <= (others => '0');								-- cnt�� "00000"
		lcd_data_out <= '0';										-- data_out�� '0'
	elsif CLK='1' and CLK'event then					-- CLK�� rising edge ����,
		if lcd_w_enable = '1' then								-- w_enable��'1'(write)�̸�,
			lcd_data <= reg_file (conv_integer (cnt));		-- data�� regfile�� cnt��° array�� �Ҵ�
			lcd_addr <= cnt;										-- addr�� cnt �� �Ҵ�
			lcd_data_out <= '1';									-- data_out�� '1'(write)
			
			if cnt= X"1F" then 								-- cnt�� X"1F"�� ��
				cnt <= (others =>'0');							-- cnt�� 0���� �ٽ� ����
			else													-- cnt�� X"1F"���� ������
				cnt <= cnt + 1;									-- cnt�� ���� ���� +1�� ����
			end if;
		else														-- w_enable��'0'(read)�̸�,
			lcd_data_out <= '0'; 										-- data_out�� '0'(do not write)
		end if;
	end if;
end process;


          

--- ���׸�Ʈ�� �̷��� �����൵ �Ǵ°ǰ�;; ������ �� ������ �״�� �����ִ°ǵ�,,��
--- ������ ���⿩��!!!!!!!!!!!!!!!!!!!!!!!!!(����)

seg_data <= rc_data;
rc_enable <= '1';
process( rc_addr )
begin
	case rc_addr is
		when "000001" => seg_addr <= "000";
		when "000010" => seg_addr <= "001";
		when "000100" => seg_addr <= "010";
		when "001000" => seg_addr <= "011";
		when "010000" => seg_addr <= "100";
		when "100000" => seg_addr <= "101";
		when others => null;
	end case;
end process;

--- ������ ���⿩��!!!!!!!!!!!!!!!!!!!!!!!!!(��)





--- �����ʾƷ���ư�� ���ε� �̰� ������ ���ν�ũ������ ��. �ٵ� ��� ���´����� �������� ������

process(FPGA_RSTB, CLK)
begin
	if FPGA_RSTB ='0' then
		screen_out <= "000";
	elsif CLK='1' and CLK'event then
		if push_dr = '0' then
			screen_out <= "000";
		end if;
	end if;
end process;


end Behavioral;
