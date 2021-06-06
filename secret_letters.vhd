library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

entity secret_letters is
    Port (
		  -- system
		  FPGA_RSTB : in  STD_LOGIC;
		  CLK : in  STD_LOGIC;
		  
			-- LCD Output
		  LCD_A : out  STD_LOGIC_VECTOR (1 downto 0);
		  LCD_EN : out  STD_LOGIC;
		  LCD_D : out  STD_LOGIC_VECTOR (7 downto 0);
		  
		  -- 7 Segments Output
		  DIGIT : out  STD_LOGIC_VECTOR (6 downto 1);
		  SEG_A : out  STD_LOGIC;
		  SEG_B : out  STD_LOGIC;
		  SEG_C : out  STD_LOGIC;
		  SEG_D : out  STD_LOGIC;
		  SEG_E : out  STD_LOGIC;
		  SEG_F : out  STD_LOGIC;
		  SEG_G : out  STD_LOGIC;
		  SEG_DP : out  STD_LOGIC;
		  
		  -- PUSH buttons
		  PUSH_UL : in  STD_LOGIC;
		  PUSH_UC : in  STD_LOGIC;
		  PUSH_UR : in  STD_LOGIC;
		  PUSH_DL : in  STD_LOGIC;
		  PUSH_DC : in  STD_LOGIC;
		  PUSH_DR : in  STD_LOGIC;
		  
		  -- 4bits binary input
		  BINARY : in  STD_LOGIC_VECTOR (3 downto 0)
		  );
end secret_letters;

architecture Behavioral of secret_letters is

	-- COMPONENT --------------------------------------------------------------------------------------------------------------------
	
	-- LCD�� 7 Segments�� display�� ����ϴ� component
	component display_module
		port (
			-- system
			FPGA_RSTB : in  STD_LOGIC;
			CLK : in  STD_LOGIC;

			-- LCD output
			LCD_A : out  STD_LOGIC_VECTOR (1 downto 0);
			LCD_EN : out  STD_LOGIC;
			LCD_D : out  STD_LOGIC_VECTOR (7 downto 0);

			-- 7 segments output
			DIGIT : out STD_LOGIC_VECTOR (6 downto 1);
			SEG_A : out STD_LOGIC;
			SEG_B : out STD_LOGIC;
			SEG_C : out STD_LOGIC;
			SEG_D : out STD_LOGIC;
			SEG_E : out STD_LOGIC;
			SEG_F : out STD_LOGIC;
			SEG_G : out STD_LOGIC;
			SEG_DP : out STD_LOGIC;

			-- lcd display data from other screens
			lcd_w_enable : out std_logic;
			lcd_data_out : in std_logic; 
			lcd_addr : in std_logic_vector(4 downto 0);
			lcd_data : in std_logic_vector(7 downto 0); 

			-- 7 segments display data from other screens
			seg_w_enable : out std_logic;
			seg_data_out : in std_logic;
			seg_addr : in std_logic_vector(2 downto 0);
			seg_data : in std_logic_vector(3 downto 0)
			);
	End component;
	
	-- main screen�� ����ϴ� component
	-- ���� ��ȣ�� READ/WRITE ��带 ������ �� �ִ�.
	component screen_main is
		port ( 
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

			-- encrypted letter to read screen
			rl_enable : in  STD_LOGIC;
			rl_data_out : out  STD_LOGIC;
			rl_addr : out  STD_LOGIC_VECTOR (4 downto 0);
			rl_data : out  STD_LOGIC_VECTOR (7 downto 0);

			-- encrypted letter from write screen
			sl_enable : out  STD_LOGIC;
			sl_data_out : in  STD_LOGIC;
			sl_addr : in  STD_LOGIC_VECTOR (4 downto 0);
			sl_data : in  STD_LOGIC_VECTOR (7 downto 0)
			);
	end component;
	
	-- read code screen�� ����ϴ� component
	-- 6 digit decimal�� �Է��Ͽ� read screen���� ������.
	component screen_code_read is
		port (
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

			-- 6 digit code for decryption to read screen
			rc_enable : in  STD_LOGIC;
			rc_data_out : out  STD_LOGIC;
			rc_addr : out  STD_LOGIC_VECTOR (2 downto 0);
			rc_data : out  STD_LOGIC_VECTOR (3 downto 0)
			);
	end component;
	
	-- write code screen�� ����ϴ� component
	-- 6 digit decimal�� �Է��Ͽ� write screen���� ������.
	component screen_code_write is
		port ( 
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

			-- 6 digit code for encryption to write screen
			wc_enable : in  STD_LOGIC;
			wc_data_out : out  STD_LOGIC;
			wc_addr : out  STD_LOGIC_VECTOR (2 downto 0);
			wc_data : out  STD_LOGIC_VECTOR (3 downto 0)
			);
	end component;
	
	-- read screen�� ����ϴ� component
	-- main screen���� ��ȣȭ�� ������ �ް�, read code screen���� 6 digit code�� �޾Ƽ� ������ ��ȣȭ �Ѵ�.
	component screen_read is
		port ( 
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

			-- encrypted letter from main screen
			rl_enable : out  STD_LOGIC;
			rl_data_out : in  STD_LOGIC;
			rl_addr : in  STD_LOGIC_VECTOR (4 downto 0);
			rl_data : in  STD_LOGIC_VECTOR (7 downto 0);

			-- 6 digit code for decryption from read code screen
			rc_enable : out  STD_LOGIC;
			rc_data_out : in  STD_LOGIC;
			rc_addr : in  STD_LOGIC_VECTOR (2 downto 0);
			rc_data : in  STD_LOGIC_VECTOR (3 downto 0)
			);
	end component;
	
	-- write screen�� ����ϴ� component
	-- 4bit binary�� ������ �Է��ϰ� write code screen���� 6 digit code�� �޾Ƽ� ������ ��ȣȭ �Ѵ�.
	-- main screen���� ��ȣȭ�� ������ ������.
	component screen_write is
		port ( 
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
	end component;
	
	-- SIGNAL --------------------------------------------------------------------------------------------------------------------
	

	-- Screen Navigation (Top module ����) -------------------------------------
	
	-- screen select
	-- 0(000): main screen
	-- 1(001): code_read screen
	-- 2(010): code_write screen
	-- 3(011): read screen
	-- 4(100): write screen
	
	-- current screen
	signal screen_in_reg : std_logic_vector(2 downto 0);
	
	-- screen select code from each screen
	type t_screen_out_reg_arr is array(0 to 4) of std_logic_vector(2 downto 0);
	signal screen_out_reg_arr : t_screen_out_reg_arr;
	
	--------------------------------------------------------------------------
	
	
	-- Data Exchange Between Screens ------------------------------------------
	
	-- decryption code from read code screen to read screen
	signal rc_enable_reg : STD_LOGIC;
	signal rc_data_out_reg : STD_LOGIC;
	signal rc_addr_reg : STD_LOGIC_VECTOR (2 downto 0);
	signal rc_data_reg : STD_LOGIC_VECTOR (3 downto 0);

	-- encryption code from write code screen to write screen
	signal wc_enable_reg : STD_LOGIC;
	signal wc_data_out_reg : STD_LOGIC;
	signal wc_addr_reg : STD_LOGIC_VECTOR (2 downto 0);
	signal wc_data_reg : STD_LOGIC_VECTOR (3 downto 0);

	-- encrypted letter from main screen to read screen
	signal rl_enable_reg : STD_LOGIC;
	signal rl_data_out_reg : STD_LOGIC;
	signal rl_addr_reg : STD_LOGIC_VECTOR (4 downto 0);
	signal rl_data_reg : STD_LOGIC_VECTOR (7 downto 0);

	-- encrypted letter from write screen to main screen
	signal sl_enable_reg : STD_LOGIC;
	signal sl_data_out_reg : STD_LOGIC;
	signal sl_addr_reg : STD_LOGIC_VECTOR (4 downto 0);
	signal sl_data_reg : STD_LOGIC_VECTOR (7 downto 0);
	
	---------------------------------------------------------------------------
	
	
	-- Display Data -----------------------------------------------------------
	
	-- lcd display data from current screen to display module
	signal lcd_w_enable_reg : std_logic;
	signal lcd_data_out_reg : std_logic;
	signal lcd_addr_reg : std_logic_vector(4 downto 0);
	signal lcd_data_reg : std_logic_vector(7 downto 0);

	-- 7 segments display data from current screen to display module
	signal seg_w_enable_reg : std_logic;
	signal seg_data_out_reg : std_logic;
	signal seg_addr_reg : std_logic_vector(2 downto 0);
	signal seg_data_reg : std_logic_vector(3 downto 0);

	-- lcd display data from each screen
	signal lcd_w_enable_reg_arr : std_logic_vector(4 downto 0);
	signal lcd_data_out_reg_arr : std_logic_vector(4 downto 0);
	type t_lcd_addr_reg_arr is array(0 to 4) of std_logic_vector(4 downto 0);
	signal lcd_addr_reg_arr : t_lcd_addr_reg_arr;
	type t_lcd_data_reg_arr is array(0 to 4) of std_logic_vector(7 downto 0);
	signal lcd_data_reg_arr : t_lcd_data_reg_arr;

	-- 7 segments display data from each screen
	signal seg_w_enable_reg_arr : std_logic_vector(4 downto 0);
	signal seg_data_out_reg_arr : std_logic_vector(4 downto 0);
	type t_seg_addr_reg_arr is array(0 to 4) of std_logic_vector(2 downto 0);
	signal seg_addr_reg_arr : t_seg_addr_reg_arr;
	type t_seg_data_reg_arr is array(0 to 4) of std_logic_vector(3 downto 0);
	signal seg_data_reg_arr : t_seg_data_reg_arr;
	
	--------------------------------------------------------------------------
	
	signal clk_clone : std_logic;
begin
	clk_clone <= CLK;

	-- �� ���ǵ� ������ component�� �ϳ��� moduleȭ --
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
	
	-- Screen ���� Process
	-- Current screen���� �� display data�� display module�� ����
	-- Current screen���� screen_out �����Ͱ� ���� �̸� current screen���� ����
	process(FPGA_RSTB, CLK)
	begin
		if(FPGA_RSTB = '0') then
			-- reset button�� ������ main screen�� current screen���� ����
			screen_in_reg <= "000";
		elsif(rising_edge (CLK)) then
			-- current screen�� main screen�̸�,
			if screen_in_reg = "000" then
				-- main screen���� ����� lcd data�� display module�� ����
				lcd_w_enable_reg_arr(0) <= lcd_w_enable_reg;
				lcd_data_out_reg <= lcd_data_out_reg_arr(0);
				lcd_addr_reg <= lcd_addr_reg_arr(0);
				lcd_data_reg <= lcd_data_reg_arr(0);
				
				-- main screen���� ����� 7 segments data�� display module�� ����
				seg_w_enable_reg_arr(0) <= seg_w_enable_reg;
				seg_data_out_reg <= seg_data_out_reg_arr(0);
				seg_addr_reg <= seg_addr_reg_arr(0);
				seg_data_reg <= seg_data_reg_arr(0);
				
				-- main screen���� screen_out �����Ͱ� ���� �̸� current screen���� ����
				screen_in_reg <= screen_out_reg_arr(0);
				
			-- ���� ���� --
			elsif screen_in_reg = "001" then -- read code screen
				lcd_w_enable_reg_arr(1) <= lcd_w_enable_reg;
				lcd_data_out_reg <= lcd_data_out_reg_arr(1);
				lcd_addr_reg <= lcd_addr_reg_arr(1);
				lcd_data_reg <= lcd_data_reg_arr(1);
				
				seg_w_enable_reg_arr(1) <= seg_w_enable_reg;
				seg_data_out_reg <= seg_data_out_reg_arr(1);
				seg_addr_reg <= seg_addr_reg_arr(1);
				seg_data_reg <= seg_data_reg_arr(1);
				
				screen_in_reg <= screen_out_reg_arr(1);
			elsif screen_in_reg = "010" then -- write code screen
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

