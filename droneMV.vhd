library IEEE;
use IEEE.STD_LOGIC_1164.ALL;


entity droneMV is
	Port (
		SensRight: in 		std_logic;
		SensLeft: in 		std_logic;
		Start_Stop: in 	std_logic;
		Reset: in 			std_logic;
		Clk_50MHz: in 		std_logic;
		MotorRight: out 	std_logic;
		MotorLeft: out 	std_logic;
		Display: out 		std_logic_vector (6 downto 0);
		AN: out 				std_logic_vector (3 downto 0)
	);
end droneMV;

architecture Behavioral of droneMV is
	type state_1 is (stop, move, wait_move, wait_stop);
	type state_2 is (straight, left, right, lost);
	
	signal pre_state_1, next_state_1: state_1;
	signal pre_state_2, next_state_2: state_2;
	
	signal run: std_logic; -- internal signal
	
	signal count_1: integer range 0 to 19999;
	signal Rythm_5khz: std_logic;
	signal PWMcnt: integer range 0 to 99;
	
	signal PWM_R, PWM_L: std_logic;
	
	signal count_1k: integer range 0 to 99999;
	signal Rythm_1khz: std_logic;
	signal digit_select: integer range 0 to 3;
	signal disp_left: integer range 0 to 2;
	signal disp_right: integer range 0 to 2;
	
	
begin 

	
	process (Clk_50MHz)
	begin
		if rising_edge(Clk_50MHz) then
			if count_1k = 99999 then
				count_1k <= 0;
				Rythm_1khz <= '1';
			else
				Rythm_1khz <= '0';
				count_1k <= count_1k + 1;
			end if;
		end if;
	end process;
	
	process (Clk_50MHz)
	begin
		if rising_edge(Clk_50MHz) then
			if (Rythm_1khz = '1') then
				case digit_select is
					when 0 =>
						AN <= "1110";
						digit_select <= digit_select + 1;
						if (run = '0') then
							Display <= "1111110";
						else
							case disp_right is
								when 0 =>
									Display <= "0010010";
								when 1 =>
									Display <= "0000001";				
								when 2 =>
									Display <= "0000100";
							end case;
						end if;
						
					when 1 =>
						AN <= "1101";
						digit_select <= digit_select + 1;
						if (run = '0') then
							Display <= "1111110";
						else
							case disp_right is
								when 0 =>
									Display <= "0000001";
								when 1 =>
									Display <= "1001111";				
								when 2 =>
									Display <= "0000100";
							end case;
						end if;
					
					when 2 =>
						AN <= "1011";
						digit_select <= digit_select + 1;
						if (run = '0') then
							Display <= "1111110";
						else
							case disp_left is
								when 0 =>
									Display <= "0010010";
								when 1 =>
									Display <= "0000001";				
								when 2 =>
									Display <= "0000100";
							end case;
						end if;
					
					when 3 =>
						AN <= "0111";
						digit_select <= 0;
						if (run = '0') then
							Display <= "1111110";
						else
							case disp_left is
								when 0 =>
									Display <= "0000001";
								when 1 =>
									Display <= "1001111";				
								when 2 =>
									Display <= "0000100";
							end case;
						end if;
					
				end case;
			end if;
		end if;
	end process;
	

	process (Clk_50MHz)
	begin
		if rising_edge(Clk_50MHz) then
			if (PWMcnt = 99) then
				PWMcnt <= 0;
			elsif (Rythm_5khz = '1') then
				PWMcnt <= PWMcnt + 1;
			end if;
		end if;
	end process;

	process (Clk_50MHz)
	begin
		if rising_edge(Clk_50MHz) then
			if count_1 = 19999 then
				count_1 <= 0;
				Rythm_5khz <= '1';
			else
				Rythm_5khz <= '0';
				count_1 <= count_1 + 1;
			end if;
		end if;
	end process;

	-- Start_Stop_Machine 
	process (Reset, Clk_50MHz)
	begin
		if (Reset='1') then
			pre_state_1 <= stop;
		elsif (Clk_50MHz'event and Clk_50MHz='1') then
			pre_state_1 <= next_state_1;
		end if;
	end process;
	
	process (Start_Stop, pre_state_1)
	begin
		case pre_state_1 is
			when stop =>
				if (Start_Stop = '1') then
					next_state_1 <= wait_move;
				else 
					next_state_1 <= pre_state_1;
				end if;
			
			when move =>
				if (Start_Stop = '1') then
					next_state_1 <= wait_stop;
				else 
					next_state_1 <= pre_state_1;
				end if;
				
			when wait_move =>
				if (Start_Stop = '0') then
						next_state_1 <= move;
				else 
					next_state_1 <= pre_state_1;
				end if;
				
			when wait_stop =>
				if (Start_Stop = '0') then
						next_state_1 <= stop;
				else 
					next_state_1 <= pre_state_1;
				end if;
			end case;
	end process;
	
	run <= '1' when pre_state_1 = move else '0';
	
	-- Direction_Control_Machine 
	process (Reset, Clk_50MHz)
	begin
		if (Reset='1') then
			pre_state_2 <= straight;
		elsif (Clk_50MHz'event and Clk_50MHz='1') then
			pre_state_2 <= next_state_2;
		end if;
	end process;
	
	process (SensRight, SensLeft, pre_state_2)
	begin
		case pre_state_2 is
			when straight =>
				if (SensLeft = '0' and SensRight = '1') then
					next_state_2 <= right;
				elsif (SensLeft = '1' and SensRight = '0') then
					next_state_2 <= left;
				elsif (SensLeft = '1' and SensRight = '1') then
					next_state_2 <= lost;
				else
					next_state_2 <= pre_state_2;
				end if;
			
			when left =>
				if (SensLeft = '0' and SensRight = '0') then
					next_state_2 <= straight;
				elsif (SensLeft = '1' and SensRight = '1') then
					next_state_2 <= lost;
				else
					next_state_2 <= pre_state_2;
				end if;
				
			when right =>
				if (SensLeft = '0' and SensRight = '0') then
					next_state_2 <= straight;
				elsif (SensLeft = '1' and SensRight = '1') then
					next_state_2 <= lost;
				else
					next_state_2 <= pre_state_2;
				end if;
				
			when lost =>
				if (SensLeft = '1' and SensRight = '0') then
					next_state_2 <= left;
				elsif (SensLeft = '0' and SensRight = '1') then
					next_state_2 <= right;
				else
					next_state_2 <= pre_state_2;
				end if;
			end case;
	end process;
	
	process (pre_state_2, PWMcnt)
	begin
		case pre_state_2 is
			when straight =>
				if (PWMcnt<99) then
					PWM_R <= '1';
					PWM_L <= '1';
				else 
					PWM_R <= '0';
					PWM_L <= '0';
				end if;
				disp_left <= 2;
				disp_right <= 2;
				
			when left =>
				if (PWMcnt<2) then
					PWM_L <= '1';
				else 
					PWM_L <= '0';
				end if;
				if (PWMcnt<99) then
					PWM_R <= '1';
				else 
					PWM_R <= '0';
				end if;
				disp_left <= 1;
				disp_right <= 2;
				
			when right =>
				if (PWMcnt<2) then
					PWM_R <= '1';
				else 
					PWM_R <= '0';
				end if;
				if (PWMcnt<99) then
					PWM_L <= '1';
				else 
					PWM_L <= '0';
				end if;
				disp_left <= 2;
				disp_right <= 1;
				
			when lost =>
				if (PWMcnt<10) then
					PWM_R <= '1';
					PWM_L <= '1';
				else 
					PWM_R <= '0';
					PWM_L <= '0';
				end if;
				disp_left <= 0;
				disp_right <= 0;
			end case;
	end process;
	
	MotorRight <= run AND PWM_R;
	MotorLeft <= run AND PWM_L;

end Behavioral;

