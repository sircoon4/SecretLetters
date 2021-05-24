library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

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
           wc_data : in  STD_LOGIC_VECTOR (3 downto 0));
end screen_write;

architecture Behavioral of screen_write is

begin


end Behavioral;

