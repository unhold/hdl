library ieee;
use ieee.std_logic_1164.all;

entity pulse_gen is
	generic (
		duration_g : positive);
	port (
		rst_i : in std_ulogic := '0';
		clk_i : in std_ulogic;
		stb_i : in std_ulogic;
		pulse_o : out std_ulogic);
end;

architecture rtl of pulse_gen is
	signal pulse : std_ulogic := '0';
	signal cnt : natural range 0 to duration_g-1 := 0;
begin
	process(rst_i, clk_i)
	begin
		if rst_i = '1' then
			pulse <= '0';
			cnt <= 0;
		elsif rising_edge(clk_i) then
			if pulse = '1' then
				if cnt = duration_g-1 then
					pulse <= '0';
					cnt <= 0;
				else
					cnt <= cnt + 1;
				end if;
			end if;
			if stb_i = '1' then
				pulse <= '1';
				cnt <= 0;
			end if;
		end if;
	end process;
	pulse_o <= pulse;
end;

