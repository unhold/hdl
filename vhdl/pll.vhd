library ieee;
use ieee.std_logic_1164.all;

entity pll is
	generic (
		multiplier_g : positive;
		divider_g : positive);
	port (
		run_i : in boolean := true;
		clock_i : in std_ulogic;
		clock_o : out std_ulogic;
		lock_o : out std_ulogic);
end;

architecture bhv of pll is
	signal pll_clock : std_ulogic := '0';
	signal clock_rising, pll_period : delay_length := 1 sec;
begin
	measure : process(clock_i)
	begin
		if rising_edge(clock_i) then
			if clock_rising < now then
				pll_period <= (now - clock_rising) * divider_g / multiplier_g;
			end if;
			clock_rising <= now;
		end if;
	end process;
	oscillate : process(pll_period, pll_clock)
	begin
		if run_i and now > 0 ns then
			pll_clock <= transport not pll_clock after pll_period / 2;
		end if;
	end process;
	clock_o <= pll_clock;
end;


library ieee;
use ieee.std_logic_1164.all;

library work;
use work.tb_pack.all;

entity pll_tb is
end;

architecture tb of pll_tb is

	signal clock_time : delay_length := 10 ns;
	signal clock_i, clock_o : std_ulogic;
	signal run : boolean := true;

begin

	pll : entity work.pll(bhv)
		generic map (
			multiplier_g => 66,
			divider_g => 16)
		port map (
			run_i => run,
			clock_i => clock_i,
			clock_o => clock_o);

	clk_gen(clock_i, run, clock_time);

	test : process
	begin
		clock_time <= 10 ns;
		wait for 1 sec;
		wait_clk(clock_i, 200);
		clock_time <= 1000 ns / 32;
		wait_clk(clock_i, 200);
		clock_time <= 10 ns;
		wait_clk(clock_i, 200);
		run <= false;
		wait;
	end process;

end;