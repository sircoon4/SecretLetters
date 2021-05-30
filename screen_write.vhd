library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use ieee.numeric_std.all;
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
signal reg_file : reg;                                         
signal w_enable_reg : std_logic;
signal lcd_cnt : std_logic_vector (8 downto 0);
signal lcd_state : std_logic_vector (7 downto 0);
signal lcd_db : std_logic_vector (7 downto 0);
signal count : std_logic_vector (1 downto 0);
signal first, second : std_logic_vector (3 downto 0);
signal csr : std_logic_vector( 4 downto 0);



-- isk
signal sl_addr_beforeencode : STD_LOGIC_VECTOR (4 downto 0);
signal sl_data_beforeencode : STD_LOGIC_VECTOR (7 downto 0);
signal syn_code : STD_LOGIC_VECTOR (7 downto 0);
type segmentset is array( 0 to 5 ) of std_logic_vector( 3 downto 0 ); -- 2D array declare
signal c_reg_file : segmentset;




begin

   process(FPGA_RSTB, CLK)                                         
   begin
      if (FPGA_RSTB='0') then                                      
         for i in 0 to 31 loop
            reg_file(1) <= X"20";                                 
         end loop;
      elsif(CLK='1'and CLK'event) then                             
         if(push_ul = '0') then    
           
            csr= csr + 1;      
          
         elsif(push_uc = '0') then
         
            csr= csr- 1;
         end if;
      
      elsif(push_dr = '0') then                          
         
         screen_out<="000";      
                                                            
      end if;
   end process;
   
   
   process( FPGA_RSTB , CLK ) 
   begin   
      if(FPGA_RSTB='0')then                                        
         count<='0';
         
      elsif(CLK='1' and CLK'event)then                             
         if(push_ur = '0' & count ='0' )then
            count<='1';
            first<=binary;
      
         elsif(push_ur = '0' & count = '1')then 
            second<=binary;
            count<='0';
            letter_reg_file(conv_integer(csr))<= first & second ;      
         end if;
      end if;
      
   end process;
   
   




------------------------isk
sl_data <= sl_data_beforeencode xor syn_code; -- 암호화!!!


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




process(FPGA_RSTB, CLK)-- 이게 진짜 섹렉만드는거
Begin
   if FPGA_RSTB ='0' then
      c_reg_file <= (others => "0000");
   elsif CLK='1' and CLK'event then
      if wc_data_out = '1' then
         c_reg_file (conv_integer (wc_addr)) <= wc_data;
      end if;
   end if;


end process;

