library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

entity screen_read is
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
           rl_enable : out  STD_LOGIC;
           rl_data_out : in  STD_LOGIC;
           rl_addr : in  STD_LOGIC_VECTOR (4 downto 0);
           rl_data : in  STD_LOGIC_VECTOR (7 downto 0);
           rc_enable : out  STD_LOGIC;
           rc_data_out : in  STD_LOGIC;
           rc_addr : in  STD_LOGIC_VECTOR (5 downto 0);
           rc_data : in  STD_LOGIC_VECTOR (3 downto 0));
end screen_read;

architecture Behavioral of screen_read is

signal r1_data_decode : STD_LOGIC_VECTOR (7 downto 0);
signal syn_code : STD_LOGIC_VECTOR (7 downto 0);
type segmentset is array( 0 to 6 ) of std_logic_vector( 3 downto 0 ); -- 2D array declare
signal seg_reg_file : segmentset;

begin


r1_data_decode <= rl_data xor syn_code;

process(FPGA_RSTB, CLK)
begin
	if FPGA_RSTB ='0' then
		syn_code <= (others => '0');
	elsif CLK='1' and CLK'event then
		syn_code(7 downto 6) <= seg_reg_file(4)(1 downto 0);
		syn_code(5) <= seg_reg_file(1)(0);
		syn_code(4) <= seg_reg_file(6)(0);
		syn_code(3) <= seg_reg_file(5)(0);
		syn_code(2) <= seg_reg_file(2)(0);
		syn_code(1 downto 0) <= seg_reg_file(3)(1 downto 0);
	end if;
end process;	


--------------------------------- seg_reg_file 만들기

process(CLK)
Begin
	if CLK='1' and CLK'event then
		seg_reg_file (conv_integer (rc_addr(2 downto 0))) <= rc_data;
	end if;
end process;

-----------------------------------여기서부터 read하기

end Behavioral;

