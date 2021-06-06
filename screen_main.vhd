library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

-- main screen

entity screen_main is
    Port ( 
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
end screen_main;

architecture Behavioral of screen_main is
	-- lcd ���� ���� signal --
	type lcd_reg is array( 0 to 31 ) of std_logic_vector( 7 downto 0 );
	signal lcd_reg_file : lcd_reg;
	signal lcd_cnt : std_logic_vector(4 downto 0);
	
	-- 7 segments ���� ���� signal --
	type seg_reg is array( 0 to 8 ) of std_logic_vector( 3 downto 0 );
	signal seg_reg_file : seg_reg;
	signal seg_cnt : std_logic_vector(2 downto 0);
	
	-- ��ȣȭ�� ���� ���� memory �Ҵ� / 32�� ASCII
	type letter_reg is array( 0 to 31 ) of std_logic_vector( 7 downto 0 );
	signal letter_1 : letter_reg; -- ����
	signal letter_1_exist : std_logic; -- ������ �ִ��� Ȯ��
	signal letter_2 : letter_reg;
	signal letter_2_exist : std_logic;
	
	-- ���� ���� ���� signal --
	signal rl_cnt : std_logic_vector(4 downto 0);
	signal sl_cnt : std_logic_vector(4 downto 0);
	signal sl_enable_reg : std_logic;
	
	-- ���õ� ���� ��ȣ
	signal letter_num : std_logic_vector(2 downto 0);
begin
	-- Input ó�� process ���� --
	process(FPGA_RSTB, CLK)
	begin
		if FPGA_RSTB ='0' then -- �ʱ�ȭ
			screen_out <= "000";
			letter_num <= "000";
			
			-- lcd: 1�� 2��
			for i in 0 to 31 loop
				lcd_reg_file(i) <= X"20";
			end loop;
			
			lcd_reg_file(0) <= x"31";
			lcd_reg_file(1) <= x"DB";
			lcd_reg_file(3) <= x"32";
			lcd_reg_file(4) <= x"DB";
			
			-- 7seg: "000000"
			for i in 0 to 8 loop
				seg_reg_file(i) <= X"0";
			end loop;
			
		elsif CLK='1' and CLK'event then
			if screen_in /= "000" then -- screen�� �Ѿ�� ��, �ٽ� setting �ϴ� �κ�
				screen_out <= "000";
			elsif screen_in = "000" then -- current screen�� ��, ���� ����
				
				-- ���� ������ ������ ���� ����� ���������� �ٲ�
				if(letter_1_exist = '1') then
					lcd_reg_file(1) <= x"FF";
				end if;
				if(letter_2_exist = '1') then
					lcd_reg_file(4) <= x"FF";
				end if;
				
				if push_uc = '0' then -- up-center button�� ������ Read ���
					-- letter_num�� ���� 4bit binary�� ����
					letter_num <= binary(2 downto 0); 
					-- read code screen���� �̵�
					screen_out <= "001";
				elsif push_ur = '0' then -- up-right button�� ������ Write ���
					-- letter_num�� ���� 4bit binary�� ����
					letter_num <= binary(2 downto 0);
					-- write code screen���� �̵�
					screen_out <= "010";
				end if;
			end if;
		end if;
	end process;
	
	-- read screen���� ���õ� ������ �����ִ� process
	process(FPGA_RSTB, CLK)
	Begin
		if FPGA_RSTB ='0' then
			rl_cnt <= (others => '0');
			rl_data_out <= '0';
		elsif CLK='1' and CLK'event then
			if screen_in = "011" then
				rl_data_out <= '1';
				
				-- letter_num�� ���� ������ �����ؼ� ����
				case letter_num is
					when "001" => rl_data <= letter_1(conv_integer(rl_cnt));
					when "010" => rl_data <= letter_2(conv_integer(rl_cnt));
					when others => rl_data <= X"20";
				end case;
				rl_addr <= rl_cnt;
				
				if rl_cnt= X"1F" then -- 31
					rl_cnt <= (others =>'0');
				else
					rl_cnt <= rl_cnt + 1;
				end if;
			else
				rl_data_out <= '0';
			end if;
		end if;
	end process;
	
	-- write screen���� ���õ� ��ġ�� ������ �о�鿩 �����ϴ� process
	process(FPGA_RSTB, CLK)
	Begin
		if FPGA_RSTB ='0' then -- ���� �ʱ�ȭ
			letter_1_exist <= '0';
			letter_2_exist <= '0';

			for i in 0 to 31 loop
				letter_1(i) <= X"20";
			end loop;
			
			for i in 0 to 31 loop
				letter_2(i) <= X"20";
			end loop;
			
			sl_enable_reg <= '0';
		elsif CLK'event and CLK='1' then
			-- write scree �� �� �� ���� reading Ȱ��ȭ
			if screen_in = "100" then
				sl_enable_reg <= '1';
			else
				sl_enable_reg <= '0';
			end if;

			-- letter_num�� ���� �ش� ������ ���� write screen���� ���� �����͸� �����ϰ� exist�� '1'�� ǥ��
			if sl_enable_reg = '1' and sl_data_out ='1' then
				case letter_num is
					when "001" => 
						letter_1(conv_integer(sl_addr)) <= sl_data;
						letter_1_exist <= '1';
					when "010" => 
						letter_2(conv_integer(sl_addr)) <= sl_data;
						letter_2_exist <= '1';
					when others => letter_1 <= (others => X"20");
				end case;
			end if;
		end if;
	end process;
	sl_enable <= sl_enable_reg;

	-- display module�� lcd ������ ����
	process(FPGA_RSTB, CLK)
	Begin
		if FPGA_RSTB ='0' then
			lcd_cnt <= (others => '0');
			lcd_data_out <= '0';
		elsif CLK='1' and CLK'event then
			if lcd_w_enable = '1' then
				lcd_data <= lcd_reg_file(conv_integer (lcd_cnt));
				lcd_addr <= lcd_cnt;
				lcd_data_out <= '1';
				
				if lcd_cnt= X"1F" then -- 3110
					lcd_cnt <= (others =>'0');
				else
					lcd_cnt <= lcd_cnt + 1;
				end if;
			else
				lcd_data_out <= '0'; -- do not write
			end if;
		end if;
	end process;
	
	-- display module�� 7 seg ������ ����
	process(FPGA_RSTB, CLK)
	Begin
		if FPGA_RSTB ='0' then
			seg_cnt <= (others => '0');
			seg_data_out <= '0';
		elsif CLK='1' and CLK'event then
			seg_data <= seg_reg_file(conv_integer (seg_cnt));
			seg_addr <= seg_cnt;
			seg_data_out <= '1';
			
			if seg_cnt= "101" then
				seg_cnt <= (others =>'0');
			else
				seg_cnt <= seg_cnt + 1;
			end if;
		end if;
	end process;
	
end Behavioral;

