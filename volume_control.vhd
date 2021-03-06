LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
use ieee.numeric_std.all;

ENTITY volume_control IS 
	GENERIC (clk_div	: integer := 1000000);
	PORT
	(
		reset				: IN std_logic;
		music_L			: IN signed(15 DOWNTO 0);
		music_R			: IN signed(15 DOWNTO 0);
		speak				: IN std_logic;
		clock				: IN std_logic;
		volume			: IN integer RANGE 0 TO 100;
		
		vol				: OUT integer RANGE 0 TO 100;
		scaled_music_L	: OUT signed(15 DOWNTO 0);
		scaled_music_R	: OUT signed(15 DOWNTO 0)
	);
END volume_control;

ARCHITECTURE bhv OF volume_control IS
--local signals.
signal scalar		: integer RANGE 0 TO 128;
signal spoken		: std_logic;
signal clk_count	: integer RANGE 0 TO clk_div;
signal count		: integer RANGE 0 TO 3;
signal scaled_vol	: integer RANGE 0 TO 255;

BEGIN
	PROCESS (music_L, music_R, speak, reset, clock)
	BEGIN
		IF reset = '0' THEN
			--reset stops audio output.
			scaled_music_L 		<= "0000000000000000";
			scaled_music_R 		<= "0000000000000000";
			scalar			<= 128;
			spoken			<= '0';
			clk_count		<= 0;
			vol			<= volume;
			scaled_vol		<= volume;
			
		ELSIF rising_edge(clock) THEN
			-- reducing the clock speed
			clk_count	<= clk_count + 1;
			scaled_vol	<= scaled_vol;
			
			IF clk_count = clk_div-1 THEN
				clk_count <= 0;
				
				IF speak = '1' THEN
					-- total volume is slowly scaled, in 0.64 sec (32 slagen).
					spoken <= '1';
					IF scalar > 64 THEN
						scalar <= scalar - 2;
					ELSE
						scalar <= 64;
					END IF;
				ELSIF spoken = '1' THEN
					-- turn volume back slowly, 3.84 sec (192 slagen)
					IF count = 2 THEN
						count <= 0;
						IF scalar < 128 THEN
							scalar <= scalar + 1;
						ELSE
							scalar <= 128;
							spoken <= '0';
						END IF;
					ELSE
						count <= count + 1;
					END IF;
				END IF;
				
			END IF;
			-- use volume on the music channels.
			scaled_vol	<= to_integer(shift_right(to_unsigned((volume) * scalar, 16), 7));
			vol 			<= scaled_vol;
			scaled_music_L	<= resize(shift_right(music_L * to_signed(scaled_vol, 16), 7), 16);
			scaled_music_R	<= resize(shift_right(music_R * to_signed(scaled_vol, 16), 7), 16);
		END IF;
	END PROCESS;
	
END bhv;
