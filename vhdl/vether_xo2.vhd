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
	signal clk, stb, run : std_ulogic;

begin

	osch : component machxo2.components.osch
	generic map (
		nom_freq => "20.46")
	port map (
		stdby => '0',
		osc => clk,
		sedstdby => open);

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
		tx_po => tx_po,
		tx_no => tx_no,
		run_o => run);

	led_no <= not ("000000" & stb & run);

end;

