LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
 
ENTITY vt_secret_letters IS
END vt_secret_letters;
 
ARCHITECTURE behavior OF vt_secret_letters IS 
 
    COMPONENT secret_letters
    PORT(
         FPGA_RSTB : IN  std_logic;
         CLK : IN  std_logic;
         LCD_A : OUT  std_logic_vector(1 downto 0);
         LCD_EN : OUT  std_logic;
         LCD_D : OUT  std_logic_vector(7 downto 0);
         DIGIT : OUT  std_logic_vector(6 downto 1);
         SEG_A : OUT  std_logic;
         SEG_B : OUT  std_logic;
         SEG_C : OUT  std_logic;
         SEG_D : OUT  std_logic;
         SEG_E : OUT  std_logic;
         SEG_F : OUT  std_logic;
         SEG_G : OUT  std_logic;
         SEG_DP : OUT  std_logic;
         PUSH_UL : IN  std_logic;
         PUSH_UC : IN  std_logic;
         PUSH_UR : IN  std_logic;
         PUSH_DL : IN  std_logic;
         PUSH_DC : IN  std_logic;
         PUSH_DR : IN  std_logic;
         BINARY : IN  std_logic_vector(3 downto 0)
        );
    END COMPONENT;
    

   --Inputs
   signal FPGA_RSTB : std_logic := '0';
   signal CLK : std_logic := '0';
   signal PUSH_UL : std_logic := '0';
   signal PUSH_UC : std_logic := '0';
   signal PUSH_UR : std_logic := '0';
   signal PUSH_DL : std_logic := '0';
   signal PUSH_DC : std_logic := '0';
   signal PUSH_DR : std_logic := '0';
   signal BINARY : std_logic_vector(3 downto 0) := (others => '0');

 	--Outputs
   signal LCD_A : std_logic_vector(1 downto 0);
   signal LCD_EN : std_logic;
   signal LCD_D : std_logic_vector(7 downto 0);
   signal DIGIT : std_logic_vector(6 downto 1);
   signal SEG_A : std_logic;
   signal SEG_B : std_logic;
   signal SEG_C : std_logic;
   signal SEG_D : std_logic;
   signal SEG_E : std_logic;
   signal SEG_F : std_logic;
   signal SEG_G : std_logic;
   signal SEG_DP : std_logic;

   -- Clock period definitions
   constant CLK_period : time := 250 ns;
 
BEGIN
 
	-- Instantiate the Unit Under Test (UUT)
   uut: secret_letters PORT MAP (
          FPGA_RSTB => FPGA_RSTB,
          CLK => CLK,
          LCD_A => LCD_A,
          LCD_EN => LCD_EN,
          LCD_D => LCD_D,
          DIGIT => DIGIT,
          SEG_A => SEG_A,
          SEG_B => SEG_B,
          SEG_C => SEG_C,
          SEG_D => SEG_D,
          SEG_E => SEG_E,
          SEG_F => SEG_F,
          SEG_G => SEG_G,
          SEG_DP => SEG_DP,
          PUSH_UL => PUSH_UL,
          PUSH_UC => PUSH_UC,
          PUSH_UR => PUSH_UR,
          PUSH_DL => PUSH_DL,
          PUSH_DC => PUSH_DC,
          PUSH_DR => PUSH_DR,
          BINARY => BINARY
        );

   -- Clock process definitions
   CLK_process :process
   begin
		CLK <= '0';
		wait for CLK_period/2;
		CLK <= '1';
		wait for CLK_period/2;
   end process;
 

   -- Stimulus process
   stim_proc: process
   begin		
      -- hold reset state for 100 ns.
      wait for 100 ns;	

      wait for CLK_period*10;

      -- insert stimulus here 
		
		FPGA_RSTB <= '0';
		PUSH_UL <= '1';
		PUSH_UC <= '1';
		PUSH_UR <= '1';
		PUSH_DL <= '1';
		PUSH_DC <= '1';
		PUSH_DR <= '1';
		
		wait for 1ms;
		
		FPGA_RSTB <= '1';
		

      wait;
   end process;

END;
