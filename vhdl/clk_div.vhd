library ieee;
use ieee.std_logic_1164.all;

entity clk_div is
	generic (
		period_g : in positive);
	port  (
		rst_i : in std_ulogic := '0';
		clk_i : in std_ulogic;
		clk_o : out std_ulogic);
begin
	assert period_g >= 2 and period_g mod 2 = 0
		report "clk_div: invalid period_g";
end;


architecture rtl of clk_div is
	signal clk : std_ulogic := '0';
	signal cnt : natural range 0 to period_g/2 - 1 := 0;
begin
	process(rst_i, clk_i)
	begin
		if rst_i = '1' then
			clk <= '0';
			cnt <= 0;
		elsif rising_edge(clk_i) then
			if cnt = period_g/2 - 1 then
				clk <= not clk;
				cnt <= 0;
			else
				cnt <= cnt + 1;
			end if;
		end if;
	end process;
	clk_o <= clk;
end;
