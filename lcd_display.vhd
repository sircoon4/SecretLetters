library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

entity secret_letter is
    Port (
			-- system
			FPGA_RSTB : in  STD_LOGIC;
		   CLK : in  STD_LOGIC;
			
			-- LCD Output
		   LCD_A : out  STD_LOGIC_VECTOR (1 downto 0);
		   LCD_EN : out  STD_LOGIC;
		   LCD_D : out  STD_LOGIC_VECTOR (7 downto 0);
			
			-- 7 Segments Output
			DIGIT : out STD_LOGIC_VECTOR (6 downto 1);
			SEG_A : out STD_LOGIC;
			SEG_B : out STD_LOGIC;
			SEG_C : out STD_LOGIC;
			SEG_D : out STD_LOGIC;
			SEG_E : out STD_LOGIC;
			SEG_F : out STD_LOGIC;
			SEG_G : out STD_LOGIC;
			SEG_DP : out STD_LOGIC;
			
			-- Input
		   push_ul : in  STD_LOGIC;
		   push_uc : in  STD_LOGIC;
		   push_ur : in  STD_LOGIC;
		   push_dl : in  STD_LOGIC;
		   push_dc : in  STD_LOGIC;
		   push_dr : in  STD_LOGIC;
		   binary : in  STD_LOGIC_VECTOR (3 downto 0)
			);
end secret_letter;

architecture Behavioral of lcd_display is
	component display_module
		port (
			-- system
			FPGA_RSTB : in  STD_LOGIC;
		   CLK : in  STD_LOGIC;
			
			-- LCD Output
		   LCD_A : out  STD_LOGIC_VECTOR (1 downto 0);
		   LCD_EN : out  STD_LOGIC;
		   LCD_D : out  STD_LOGIC_VECTOR (7 downto 0);
			
			-- 7 Segments Output
			DIGIT : out STD_LOGIC_VECTOR (6 downto 1);
			SEG_A : out STD_LOGIC;
			SEG_B : out STD_LOGIC;
			SEG_C : out STD_LOGIC;
			SEG_D : out STD_LOGIC;
			SEG_E : out STD_LOGIC;
			SEG_F : out STD_LOGIC;
			SEG_G : out STD_LOGIC;
			SEG_DP : out STD_LOGIC;
			
			-- lcd display data from
			lcd_w_enable : out std_logic;
			lcd_data_out : in std_logic; 
			lcd_addr : in std_logic_vector(4 downto 0);
			lcd_data : in std_logic_vector(7 downto 0); 
			
			-- 7 seg display data from
			seg_w_enable : out std_logic;
			seg_data_out : in std_logic;
			seg_addr : in std_logic_vector(2 downto 0);
			seg_data : in std_logic_vector(3 downto 0) -- int 0 - 9
			);
	End component;
	
	component screen_main is
		port ( 
			  -- system
			  FPGA_RSTB : in  STD_LOGIC;
           CLK : in  STD_LOGIC;
			  
			  -- lcd display data to
           lcd_w_enable : in  STD_LOGIC;
           lcd_data_out : out  STD_LOGIC;
           lcd_addr : out  STD_LOGIC_VECTOR (4 downto 0);
           lcd_data : out  STD_LOGIC_VECTOR (7 downto 0);
			  
			  -- 7 seg display data to
           seg_w_enable : in  STD_LOGIC;
           seg_data_out : out  STD_LOGIC;
           seg_addr : out  STD_LOGIC_VECTOR (2 downto 0);
           seg_data : out  STD_LOGIC_VECTOR (3 downto 0);
			  
			  -- input
           push_ul : in  STD_LOGIC;
           push_uc : in  STD_LOGIC;
           push_ur : in  STD_LOGIC;
           push_dl : in  STD_LOGIC;
           push_dc : in  STD_LOGIC;
           push_dr : in  STD_LOGIC;
           binary : in  STD_LOGIC_VECTOR (3 downto 0);
			  
			  -- screen select
			  screen_in : in  STD_LOGIC_VECTOR (2 downto 0);
           screen_out : out  STD_LOGIC_VECTOR (2 downto 0);
			  
			  -- read letter text to read screen
			  rl_enable : in  STD_LOGIC;
			  rl_data_out : out  STD_LOGIC;
			  rl_addr : out  STD_LOGIC_VECTOR (4 downto 0);
           rl_data : out  STD_LOGIC_VECTOR (7 downto 0);
			  
			  -- write letter text from write screen
			  sl_enable : out  STD_LOGIC;
			  sl_data_out : in  STD_LOGIC;
			  sl_addr : in  STD_LOGIC_VECTOR (4 downto 0);
           sl_data : in  STD_LOGIC_VECTOR (7 downto 0)
			  );
	end component;
	
	component screen_code_read is
		port (
			  -- system
			  FPGA_RSTB : in  STD_LOGIC;
           CLK : in  STD_LOGIC;
			  
			  -- lcd display data to
           lcd_w_enable : in  STD_LOGIC;
           lcd_data_out : out  STD_LOGIC;
           lcd_addr : out  STD_LOGIC_VECTOR (4 downto 0);
           lcd_data : out  STD_LOGIC_VECTOR (7 downto 0);
			  
			  -- 7 seg display data to
           seg_w_enable : in  STD_LOGIC;
           seg_data_out : out  STD_LOGIC;
           seg_addr : out  STD_LOGIC_VECTOR (2 downto 0);
           seg_data : out  STD_LOGIC_VECTOR (3 downto 0);
			  
			  -- input
           push_ul : in  STD_LOGIC;
           push_uc : in  STD_LOGIC;
           push_ur : in  STD_LOGIC;
           push_dl : in  STD_LOGIC;
           push_dc : in  STD_LOGIC;
           push_dr : in  STD_LOGIC;
           binary : in  STD_LOGIC_VECTOR (3 downto 0);
			  
			  -- screen select
			  screen_in : in  STD_LOGIC_VECTOR (2 downto 0);
           screen_out : out  STD_LOGIC_VECTOR (2 downto 0);
			  
			  -- read code to read screen
			  rc_enable : in  STD_LOGIC;
			  rc_data_out : out  STD_LOGIC;
			  rc_addr : out  STD_LOGIC_VECTOR (5 downto 0);
           rc_data : out  STD_LOGIC_VECTOR (3 downto 0)
			  );
	end component;
	
	component screen_code_write is
		port ( 
			  -- system
			  FPGA_RSTB : in  STD_LOGIC;
           CLK : in  STD_LOGIC;
			  
			  -- lcd display data to
           lcd_w_enable : in  STD_LOGIC;
           lcd_data_out : out  STD_LOGIC;
           lcd_addr : out  STD_LOGIC_VECTOR (4 downto 0);
           lcd_data : out  STD_LOGIC_VECTOR (7 downto 0);
			  
			  -- 7 seg display data to
           seg_w_enable : in  STD_LOGIC;
           seg_data_out : out  STD_LOGIC;
           seg_addr : out  STD_LOGIC_VECTOR (2 downto 0);
           seg_data : out  STD_LOGIC_VECTOR (3 downto 0);
			  
			  -- input
           push_ul : in  STD_LOGIC;
           push_uc : in  STD_LOGIC;
           push_ur : in  STD_LOGIC;
           push_dl : in  STD_LOGIC;
           push_dc : in  STD_LOGIC;
           push_dr : in  STD_LOGIC;
           binary : in  STD_LOGIC_VECTOR (3 downto 0);
			  
			  -- screen select
			  screen_in : in  STD_LOGIC_VECTOR (2 downto 0);
           screen_out : out  STD_LOGIC_VECTOR (2 downto 0);
			  
			  -- write code to write screen
			  wc_enable : in  STD_LOGIC;
			  wc_data_out : out  STD_LOGIC;
			  wc_addr : out  STD_LOGIC_VECTOR (5 downto 0);
           wc_data : out  STD_LOGIC_VECTOR (3 downto 0)
			  );
	end component;
	
	component screen_read is
		port ( 
			  -- system
			  FPGA_RSTB : in  STD_LOGIC;
           CLK : in  STD_LOGIC;
			  
			  -- lcd display data to
           lcd_w_enable : in  STD_LOGIC;
           lcd_data_out : out  STD_LOGIC;
           lcd_addr : out  STD_LOGIC_VECTOR (4 downto 0);
           lcd_data : out  STD_LOGIC_VECTOR (7 downto 0);
			  
			  -- 7 seg display data to
           seg_w_enable : in  STD_LOGIC;
           seg_data_out : out  STD_LOGIC;
           seg_addr : out  STD_LOGIC_VECTOR (2 downto 0);
           seg_data : out  STD_LOGIC_VECTOR (3 downto 0);
			  
			  -- input
           push_ul : in  STD_LOGIC;
           push_uc : in  STD_LOGIC;
           push_ur : in  STD_LOGIC;
           push_dl : in  STD_LOGIC;
           push_dc : in  STD_LOGIC;
           push_dr : in  STD_LOGIC;
           binary : in  STD_LOGIC_VECTOR (3 downto 0);
			  
			  -- screen select
			  screen_in : in  STD_LOGIC_VECTOR (2 downto 0);
           screen_out : out  STD_LOGIC_VECTOR (2 downto 0);
			  
			  -- read letter text from main screen
			  rl_enable : out  STD_LOGIC;
			  rl_data_out : in  STD_LOGIC;
			  rl_addr : in  STD_LOGIC_VECTOR (4 downto 0);
           rl_data : in  STD_LOGIC_VECTOR (7 downto 0);
			  
			  -- read code from code read screen
			  rc_enable : out  STD_LOGIC;
			  rc_data_out : in  STD_LOGIC;
			  rc_addr : in  STD_LOGIC_VECTOR (5 downto 0);
           rc_data : in  STD_LOGIC_VECTOR (3 downto 0)
			  );
	end component;
	
	component screen_write is
		port ( 
			  -- system
			  FPGA_RSTB : in  STD_LOGIC;
           CLK : in  STD_LOGIC;
			  
			  -- lcd display data to
           lcd_w_enable : in  STD_LOGIC;
           lcd_data_out : out  STD_LOGIC;
           lcd_addr : out  STD_LOGIC_VECTOR (4 downto 0);
           lcd_data : out  STD_LOGIC_VECTOR (7 downto 0);
			  
			  -- 7 seg display data to
           seg_w_enable : in  STD_LOGIC;
           seg_data_out : out  STD_LOGIC;
           seg_addr : out  STD_LOGIC_VECTOR (2 downto 0);
           seg_data : out  STD_LOGIC_VECTOR (3 downto 0);
			  
			  -- input
           push_ul : in  STD_LOGIC;
           push_uc : in  STD_LOGIC;
           push_ur : in  STD_LOGIC;
           push_dl : in  STD_LOGIC;
           push_dc : in  STD_LOGIC;
           push_dr : in  STD_LOGIC;
           binary : in  STD_LOGIC_VECTOR (3 downto 0);
			  
			  -- screen select
			  screen_in : in  STD_LOGIC_VECTOR (2 downto 0);
           screen_out : out  STD_LOGIC_VECTOR (2 downto 0);
			  
			  -- write letter text to main screen
			  sl_enable : in  STD_LOGIC;
			  sl_data_out : out  STD_LOGIC;
			  sl_addr : out  STD_LOGIC_VECTOR (4 downto 0);
           sl_data : out  STD_LOGIC_VECTOR (7 downto 0);
			  
			  -- write code from code write screen
			  wc_enable : out  STD_LOGIC;
			  wc_data_out : in  STD_LOGIC;
			  wc_addr : in  STD_LOGIC_VECTOR (5 downto 0);
           wc_data : in  STD_LOGIC_VECTOR (3 downto 0)
			  );
	end component;

	-- lcd display data
	signal lcd_w_enable_reg : std_logic;
	signal lcd_data_out : std_logic;
	signal lcd_addr_reg : std_logic_vector(4 downto 0);
	signal lcd_data_reg : std_logic_vector(7 downto 0);
	
	-- 7 seg display data
	signal seg_w_enable_reg : std_logic;
	signal seg_data_out : std_logic;
	signal seg_addr_reg : std_logic_vector(2 downto 0);
	signal seg_data_reg : std_logic_vector(3 downto 0);
	
	-- read code
   signal rc_enable : STD_LOGIC;
   signal rc_data_out : STD_LOGIC;
   signal rc_addr : STD_LOGIC_VECTOR (5 downto 0);
   signal rc_data : STD_LOGIC_VECTOR (3 downto 0);
	
	-- write code
   signal wc_enable : STD_LOGIC;
   signal wc_data_out : STD_LOGIC;
   signal wc_addr : STD_LOGIC_VECTOR (5 downto 0);
   signal wc_data : STD_LOGIC_VECTOR (3 downto 0);
	
	-- read letter text
   signal rl_enable : STD_LOGIC;
   signal rl_data_out : STD_LOGIC;
   signal rl_addr : STD_LOGIC_VECTOR (4 downto 0);
   signal rl_data : STD_LOGIC_VECTOR (7 downto 0);
	
	-- write letter text
   signal sl_enable : STD_LOGIC;
   signal sl_data_out : STD_LOGIC;
   signal sl_addr : STD_LOGIC_VECTOR (4 downto 0);
   signal sl_data : STD_LOGIC_VECTOR (7 downto 0);
	
	-- screen select
	-- 0(000): main screen
	-- 1(001): code_read screen
	-- 2(010): code_write screen
	-- 3(011): read screen
	-- 4(100): write screen
	signal screen_in : std_logic_vector(2 downto 0);
	type t_screen_out_arr is array(0 to 4) of std_logic_vector(2 downto 0);
	signal screen_out_arr : t_screen_out_arr;
	
	-- lcd display data
	signal lcd_w_enable_reg_arr : std_logic_vector(4 downto 0);
	signal lcd_data_out_arr : std_logic_vector(4 downto 0);
	type t_lcd_addr_reg_arr is array(0 to 4) of std_logic_vector(4 downto 0);
	signal lcd_addr_reg_arr : t_lcd_addr_reg_arr;
	type t_lcd_data_reg_arr is array(0 to 4) of std_logic_vector(7 downto 0);
	signal lcd_data_reg_arr : t_lcd_data_reg_arr;
	
	-- 7 seg display data
	signal seg_w_enable_reg_arr : std_logic_vector(4 downto 0);
	signal seg_data_out_arr : std_logic_vector(4 downto 0);
	type t_seg_addr_reg_arr is array(0 to 4) of std_logic_vector(2 downto 0);
	signal seg_addr_reg_arr : t_seg_addr_reg_arr;
	type t_seg_data_reg_arr is array(0 to 4) of std_logic_vector(3 downto 0);
	signal seg_data_reg_arr : t_seg_data_reg_arr;
begin

	lcd : LCD_test port map(FPGA_RSTB, CLK, LCD_A, LCD_EN, LCD_D,
			data_in_flag, addr_reg, data_reg, w_enable_reg);
	srn_main : screen_main port map(FPGA_RSTB, CLK,
			w_enable_reg, data_out_flag(0), scr_m_addr_reg, scr_m_data_reg, 
			push_ul, push_uc, push_ur, push_dl, push_dc, push_dr, binary,
			screen, scr_m_to_screen);
			
	process(FPGA_RSTB, CLK) -- screen 별 작동 방식
	begin
		if screen = "000" then -- main screen
			lcd_w_enable_reg <= lcd_w_enable_reg_arr(0);
			lcd_data_out <= lcd_data_out_arr(0);
			lcd_addr_reg <= lcd_addr_reg_arr(0);
			lcd_data_reg <= lcd_data_reg_arr(0);
			
			seg_w_enable_reg <= seg_w_enable_reg_arr(0);
			seg_data_out <= seg_data_out_arr(0);
			seg_addr_reg <= seg_addr_reg_arr(0);
			seg_data_reg <= seg_data_reg_arr(0);
			
			screen_in <= screen_out_arr(0);
		elsif screen = "001" then -- code_read screen
			lcd_w_enable_reg <= lcd_w_enable_reg_arr(1);
			lcd_data_out <= lcd_data_out_arr(1);
			lcd_addr_reg <= lcd_addr_reg_arr(1);
			lcd_data_reg <= lcd_data_reg_arr(1);
			
			seg_w_enable_reg <= seg_w_enable_reg_arr(1);
			seg_data_out <= seg_data_out_arr(1);
			seg_addr_reg <= seg_addr_reg_arr(1);
			seg_data_reg <= seg_data_reg_arr(1);
			
			screen_in <= screen_out_arr(1);
		elsif screen = "010" then -- code_write screen
			lcd_w_enable_reg <= lcd_w_enable_reg_arr(2);
			lcd_data_out <= lcd_data_out_arr(2);
			lcd_addr_reg <= lcd_addr_reg_arr(2);
			lcd_data_reg <= lcd_data_reg_arr(2);
			
			seg_w_enable_reg <= seg_w_enable_reg_arr(2);
			seg_data_out <= seg_data_out_arr(2);
			seg_addr_reg <= seg_addr_reg_arr(2);
			seg_data_reg <= seg_data_reg_arr(2);
			
			screen_in <= screen_out_arr(2);
		elsif screen = "011" then -- read screen
			lcd_w_enable_reg <= lcd_w_enable_reg_arr(3);
			lcd_data_out <= lcd_data_out_arr(3);
			lcd_addr_reg <= lcd_addr_reg_arr(3);
			lcd_data_reg <= lcd_data_reg_arr(3);
			
			seg_w_enable_reg <= seg_w_enable_reg_arr(3);
			seg_data_out <= seg_data_out_arr(3);
			seg_addr_reg <= seg_addr_reg_arr(3);
			seg_data_reg <= seg_data_reg_arr(3);
			
			screen_in <= screen_out_arr(3);
		elsif screen = "100" then -- write screen
			lcd_w_enable_reg <= lcd_w_enable_reg_arr(4);
			lcd_data_out <= lcd_data_out_arr(4);
			lcd_addr_reg <= lcd_addr_reg_arr(4);
			lcd_data_reg <= lcd_data_reg_arr(4);
			
			seg_w_enable_reg <= seg_w_enable_reg_arr(4);
			seg_data_out <= seg_data_out_arr(4);
			seg_addr_reg <= seg_addr_reg_arr(4);
			seg_data_reg <= seg_data_reg_arr(4);
			
			screen_in <= screen_out_arr(4);
		end if;
	end process;

end Behavioral;

