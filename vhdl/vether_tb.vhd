library std;
use std.textio.all;

library ieee;
use ieee.numeric_bit.all;
use ieee.std_logic_1164.all;

library work;
use work.tb_pack.all;
use work.vether.all;


entity vether_tb is
	port (
		tx_po,
		tx_no : out std_ulogic;
		led_no : out std_ulogic_vector(7 downto 0));
end;


architecture tbd of vether_tb is

	procedure write(filename : string; data : data_t) is
		file f : text is out filename;
		variable l : line;
	begin
		for i in data'range loop
			write(l, to_hstring(unsigned(data(i))));
			writeline(f, l);
		end loop;
	end;

	constant clk_freq : natural := 20_460e3;
	signal clk : std_ulogic := '0';
	signal stb, run, tx_p, tx_n, run_pulse : std_ulogic;

begin

	write("mac.dat", data_t(mac));

	clk_gen(clk, true, clk_freq);

	stb_gen : entity work.stb_gen
	generic map (
		period_g => clk_freq) -- 1 sec
	port map (
		clk_i => clk,
		stb_o => stb);

	vether_tx : entity work.vether_tx
	generic map (
		clk_freq_g => clk_freq)
	port map (
		clk_i => clk,
		stb_i => stb,
		tx_po => tx_p,
		tx_no => tx_n,
		run_o => run);

	run_pulse_gen : entity work.pulse_gen
	generic map (
		duration_g => clk_freq/10) -- 100 ms
	port map (
		clk_i => clk,
		stb_i => run,
		pulse_o => run_pulse);

	led_no <= not ("00000" & tx_p & tx_n & run_pulse);
	tx_po <= tx_p;
	tx_no <= tx_n;

end;
