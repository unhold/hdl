library ieee;
use ieee.std_logic_1164.all;

library machxo2;
use machxo2.components;


entity vether_xo2 is
	port (
		tx_po,
		tx_no : out std_ulogic;
		led_no : out std_ulogic_vector(7 downto 0));
end;


architecture tbd of vether_xo2 is

	constant clk_freq : natural := 20_460e3;
	signal clk : std_ulogic := '0';
	signal stb, run, tx_p, tx_n, run_pulse : std_ulogic;

begin

	osch : component machxo2.components.osch
	generic map (
		nom_freq => "20.46")
	port map (
		stdby => '0',
		osc => clk);

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
