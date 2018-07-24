library ieee;
use ieee.std_logic_1164.all;

entity stb_gen is
	generic (
		period_g : in positive);
	port  (
		rst_i : in std_ulogic := '0';
		clk_i : in std_ulogic;
		sync_rst_i : in std_ulogic := '0';
		stb_i : in std_ulogic := '1';
		stb_o : out std_ulogic);
end;

architecture rtl of stb_gen is
	signal stb : std_ulogic := '0';
	signal cnt : natural range 0 to period_g-1 := 0;
begin
	process(rst_i, clk_i)
	begin
		if rst_i = '1' then
			stb <= '0';
			cnt <= 0;
		elsif rising_edge(clk_i) then
			stb <= '0';
			if sync_rst_i = '1' then
				cnt <= 0;
			elsif stb_i = '1' then
				if cnt = period_g-1 then
					stb <= '1';
					cnt <= 0;
				else
					cnt <= cnt + 1;
				end if;
			end if;
		end if;
	end process;
	stb_o <= stb;
end;
