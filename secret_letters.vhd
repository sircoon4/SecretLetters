library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

entity secret_letters is
    Port ( FPGA_RSTB : in  STD_LOGIC;
           CLK : in  STD_LOGIC;
           LCD_A : out  STD_LOGIC_VECTOR (1 downto 0);
           LCD_EN : out  STD_LOGIC;
           LCD_D : out  STD_LOGIC_VECTOR (7 downto 0);
           DIGIT : out  STD_LOGIC_VECTOR (6 downto 1);
           SEG_A : out  STD_LOGIC;
           SEG_B : out  STD_LOGIC;
           SEG_C : out  STD_LOGIC;
           SEG_D : out  STD_LOGIC;
           SEG_E : out  STD_LOGIC;
           SEG_F : out  STD_LOGIC;
           SEG_G : out  STD_LOGIC;
           SEG_DP : out  STD_LOGIC;
           PUSH_UL : in  STD_LOGIC;
           PUSH_UC : in  STD_LOGIC;
           PUSH_UR : in  STD_LOGIC;
           PUSH_DL : in  STD_LOGIC;
           PUSH_DC : in  STD_LOGIC;
           PUSH_DR : in  STD_LOGIC;
           BINARY : in  STD_LOGIC_VECTOR (3 downto 0));
end secret_letters;

architecture Behavioral of secret_letters is
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
			rc_addr : out  STD_LOGIC_VECTOR (2 downto 0);
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
			wc_addr : out  STD_LOGIC_VECTOR (2 downto 0);
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
			rc_addr : in  STD_LOGIC_VECTOR (2 downto 0);
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
			wc_addr : in  STD_LOGIC_VECTOR (2 downto 0);
			wc_data : in  STD_LOGIC_VECTOR (3 downto 0)
			);
	end component;

	-- lcd display data
	signal lcd_w_enable_reg : std_logic;
	signal lcd_data_out_reg : std_logic;
	signal lcd_addr_reg : std_logic_vector(4 downto 0);
	signal lcd_data_reg : std_logic_vector(7 downto 0);

	-- 7 seg display data
	signal seg_w_enable_reg : std_logic;
	signal seg_data_out_reg : std_logic;
	signal seg_addr_reg : std_logic_vector(2 downto 0);
	signal seg_data_reg : std_logic_vector(3 downto 0);

	-- read code
	signal rc_enable_reg : STD_LOGIC;
	signal rc_data_out_reg : STD_LOGIC;
	signal rc_addr_reg : STD_LOGIC_VECTOR (2 downto 0);
	signal rc_data_reg : STD_LOGIC_VECTOR (3 downto 0);

	-- write code
	signal wc_enable_reg : STD_LOGIC;
	signal wc_data_out_reg : STD_LOGIC;
	signal wc_addr_reg : STD_LOGIC_VECTOR (2 downto 0);
	signal wc_data_reg : STD_LOGIC_VECTOR (3 downto 0);

	-- read letter text
	signal rl_enable_reg : STD_LOGIC;
	signal rl_data_out_reg : STD_LOGIC;
	signal rl_addr_reg : STD_LOGIC_VECTOR (4 downto 0);
	signal rl_data_reg : STD_LOGIC_VECTOR (7 downto 0);

	-- write letter text
	signal sl_enable_reg : STD_LOGIC;
	signal sl_data_out_reg : STD_LOGIC;
	signal sl_addr_reg : STD_LOGIC_VECTOR (4 downto 0);
	signal sl_data_reg : STD_LOGIC_VECTOR (7 downto 0);

	-- screen select
	-- 0(000): main screen
	-- 1(001): code_read screen
	-- 2(010): code_write screen
	-- 3(011): read screen
	-- 4(100): write screen
	signal screen_in_reg : std_logic_vector(2 downto 0);
	type t_screen_out_reg_arr is array(0 to 4) of std_logic_vector(2 downto 0);
	signal screen_out_reg_arr : t_screen_out_reg_arr;

	-- lcd display data
	signal lcd_w_enable_reg_arr : std_logic_vector(4 downto 0);
	signal lcd_data_out_reg_arr : std_logic_vector(4 downto 0);
	type t_lcd_addr_reg_arr is array(0 to 4) of std_logic_vector(4 downto 0);
	signal lcd_addr_reg_arr : t_lcd_addr_reg_arr;
	type t_lcd_data_reg_arr is array(0 to 4) of std_logic_vector(7 downto 0);
	signal lcd_data_reg_arr : t_lcd_data_reg_arr;

	-- 7 seg display data
	signal seg_w_enable_reg_arr : std_logic_vector(4 downto 0);
	signal seg_data_out_reg_arr : std_logic_vector(4 downto 0);
	type t_seg_addr_reg_arr is array(0 to 4) of std_logic_vector(2 downto 0);
	signal seg_addr_reg_arr : t_seg_addr_reg_arr;
	type t_seg_data_reg_arr is array(0 to 4) of std_logic_vector(3 downto 0);
	signal seg_data_reg_arr : t_seg_data_reg_arr;
	
	signal clk_clone : std_logic;
begin
	clk_clone <= CLK;

	dp_module : display_module port map(
			FPGA_RSTB, clk_clone,
			LCD_A, LCD_EN, LCD_D,
			DIGIT, SEG_A, SEG_B, SEG_C, SEG_D, SEG_E, SEG_F, SEG_G, SEG_DP, 
			lcd_w_enable_reg, lcd_data_out_reg, lcd_addr_reg, lcd_data_reg, 
			seg_w_enable_reg, seg_data_out_reg, seg_addr_reg, seg_data_reg
			);
	
	scr_main : screen_main port map( 
			FPGA_RSTB, clk_clone,
			lcd_w_enable_reg_arr(0), lcd_data_out_reg_arr(0), lcd_addr_reg_arr(0), lcd_data_reg_arr(0), 
			seg_w_enable_reg_arr(0), seg_data_out_reg_arr(0), seg_addr_reg_arr(0), seg_data_reg_arr(0),
			PUSH_UL, PUSH_UC, PUSH_UR, PUSH_DL, PUSH_DC, PUSH_DR, BINARY,
			screen_in_reg, screen_out_reg_arr(0), 
			rl_enable_reg, rl_data_out_reg, rl_addr_reg, rl_data_reg,
			sl_enable_reg, sl_data_out_reg, sl_addr_reg, sl_data_reg
			);
	
	scr_code_read : screen_code_read port map( 
			FPGA_RSTB, clk_clone,
			lcd_w_enable_reg_arr(1), lcd_data_out_reg_arr(1), lcd_addr_reg_arr(1), lcd_data_reg_arr(1), 
			seg_w_enable_reg_arr(1), seg_data_out_reg_arr(1), seg_addr_reg_arr(1), seg_data_reg_arr(1),
			PUSH_UL, PUSH_UC, PUSH_UR, PUSH_DL, PUSH_DC, PUSH_DR, BINARY,
			screen_in_reg, screen_out_reg_arr(1), 
			rc_enable_reg, rc_data_out_reg, rc_addr_reg, rc_data_reg
			);
			
	scr_code_write : screen_code_write port map( 
			FPGA_RSTB, clk_clone,
			lcd_w_enable_reg_arr(2), lcd_data_out_reg_arr(2), lcd_addr_reg_arr(2), lcd_data_reg_arr(2), 
			seg_w_enable_reg_arr(2), seg_data_out_reg_arr(2), seg_addr_reg_arr(2), seg_data_reg_arr(2),
			PUSH_UL, PUSH_UC, PUSH_UR, PUSH_DL, PUSH_DC, PUSH_DR, BINARY,
			screen_in_reg, screen_out_reg_arr(2), 
			wc_enable_reg, wc_data_out_reg, wc_addr_reg, wc_data_reg
			);
			
	scr_read : screen_read port map( 
			FPGA_RSTB, clk_clone,
			lcd_w_enable_reg_arr(3), lcd_data_out_reg_arr(3), lcd_addr_reg_arr(3), lcd_data_reg_arr(3), 
			seg_w_enable_reg_arr(3), seg_data_out_reg_arr(3), seg_addr_reg_arr(3), seg_data_reg_arr(3),
			PUSH_UL, PUSH_UC, PUSH_UR, PUSH_DL, PUSH_DC, PUSH_DR, BINARY,
			screen_in_reg, screen_out_reg_arr(3), 
			rl_enable_reg, rl_data_out_reg, rl_addr_reg, rl_data_reg,
			rc_enable_reg, rc_data_out_reg, rc_addr_reg, rc_data_reg
			);
			
	scr_write : screen_write port map( 
			FPGA_RSTB, clk_clone,
			lcd_w_enable_reg_arr(4), lcd_data_out_reg_arr(4), lcd_addr_reg_arr(4), lcd_data_reg_arr(4), 
			seg_w_enable_reg_arr(4), seg_data_out_reg_arr(4), seg_addr_reg_arr(4), seg_data_reg_arr(4),
			PUSH_UL, PUSH_UC, PUSH_UR, PUSH_DL, PUSH_DC, PUSH_DR, BINARY,
			screen_in_reg, screen_out_reg_arr(4), 
			sl_enable_reg, sl_data_out_reg, sl_addr_reg, sl_data_reg,
			wc_enable_reg, wc_data_out_reg, wc_addr_reg, wc_data_reg
			);
	
	process(FPGA_RSTB, CLK)
	begin
		if(FPGA_RSTB = '0') then
			screen_in_reg <= "000";
		elsif(rising_edge (CLK)) then
			if screen_in_reg = "000" then -- main screen
				lcd_w_enable_reg_arr(0) <= lcd_w_enable_reg;
				lcd_data_out_reg <= lcd_data_out_reg_arr(0);
				lcd_addr_reg <= lcd_addr_reg_arr(0);
				lcd_data_reg <= lcd_data_reg_arr(0);
				
				seg_w_enable_reg_arr(0) <= seg_w_enable_reg;
				seg_data_out_reg <= seg_data_out_reg_arr(0);
				seg_addr_reg <= seg_addr_reg_arr(0);
				seg_data_reg <= seg_data_reg_arr(0);
				
				screen_in_reg <= screen_out_reg_arr(0);
			elsif screen_in_reg = "001" then -- code_read screen
				lcd_w_enable_reg_arr(1) <= lcd_w_enable_reg;
				lcd_data_out_reg <= lcd_data_out_reg_arr(1);
				lcd_addr_reg <= lcd_addr_reg_arr(1);
				lcd_data_reg <= lcd_data_reg_arr(1);
				
				seg_w_enable_reg_arr(1) <= seg_w_enable_reg;
				seg_data_out_reg <= seg_data_out_reg_arr(1);
				seg_addr_reg <= seg_addr_reg_arr(1);
				seg_data_reg <= seg_data_reg_arr(1);
				
				screen_in_reg <= screen_out_reg_arr(1);
			elsif screen_in_reg = "010" then -- code_write screen
				lcd_w_enable_reg_arr(2) <= lcd_w_enable_reg;
				lcd_data_out_reg <= lcd_data_out_reg_arr(2);
				lcd_addr_reg <= lcd_addr_reg_arr(2);
				lcd_data_reg <= lcd_data_reg_arr(2);
				
				seg_w_enable_reg_arr(2) <= seg_w_enable_reg;
				seg_data_out_reg <= seg_data_out_reg_arr(2);
				seg_addr_reg <= seg_addr_reg_arr(2);
				seg_data_reg <= seg_data_reg_arr(2);
				
				screen_in_reg <= screen_out_reg_arr(2);
			elsif screen_in_reg = "011" then -- read screen
				lcd_w_enable_reg_arr(3) <= lcd_w_enable_reg;
				lcd_data_out_reg <= lcd_data_out_reg_arr(3);
				lcd_addr_reg <= lcd_addr_reg_arr(3);
				lcd_data_reg <= lcd_data_reg_arr(3);
				
				seg_w_enable_reg_arr(3) <= seg_w_enable_reg;
				seg_data_out_reg <= seg_data_out_reg_arr(3);
				seg_addr_reg <= seg_addr_reg_arr(3);
				seg_data_reg <= seg_data_reg_arr(3);
				
				screen_in_reg <= screen_out_reg_arr(3);
			elsif screen_in_reg = "100" then -- write screen
				lcd_w_enable_reg_arr(4) <= lcd_w_enable_reg;
				lcd_data_out_reg <= lcd_data_out_reg_arr(4);
				lcd_addr_reg <= lcd_addr_reg_arr(4);
				lcd_data_reg <= lcd_data_reg_arr(4);
				
				seg_w_enable_reg_arr(4) <= seg_w_enable_reg;
				seg_data_out_reg <= seg_data_out_reg_arr(4);
				seg_addr_reg <= seg_addr_reg_arr(4);
				seg_data_reg <= seg_data_reg_arr(4);
				
				screen_in_reg <= screen_out_reg_arr(4);
			end if;
		end if;
	end process;
end Behavioral;

