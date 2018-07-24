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

    attribute frequency_pin_clkos : string;
    attribute frequency_pin_clkos of pll : label is "19.950000";
    attribute frequency_pin_clki : string;
    attribute frequency_pin_clki of pll : label is "133.000000";
    attribute icp_current : string;
    attribute icp_current of pll : label is "9";
    attribute lpf_resistor : string;
    attribute lpf_resistor of pll : label is "72";

	constant clk_freq : natural := 19_950e3;
	signal clk133, clk, lock, rst, stb, run, tx_p, tx_n, run_pulse : std_ulogic;

begin

	osc : component machxo2.components.osch
	generic map (
		nom_freq => "133.0")
	port map (
		stdby => '0',
		osc => clk133);

	pll : component machxo2.components.ehxpllj
	generic map (
		clki_div => 16,
		clkfb_div => 3,
		clkop_div => 20,
		clkos_div => 25,
		clkop_cphase => 19,
		clkos_cphase => 24,
		clkos2_enable => "DISABLED",
		clkos3_enable => "DISABLED",
		feedbk_path => "INT_DIVA")
	port map (
		clki => clk133,
		clkos => clk,
		lock => lock);

	rst <= not lock;

	stb_gen : entity work.stb_gen
	generic map (
		period_g => clk_freq) -- 1 sec
	port map (
		rst_i => rst,
		clk_i => clk,
		stb_o => stb);

	vether_tx : entity work.vether_tx
	generic map (
		clk_freq_g => clk_freq)
	port map (
		rst_i => rst,
		clk_i => clk,
		stb_i => stb,
		tx_po => tx_p,
		tx_no => tx_n,
		run_o => run);

	run_pulse_gen : entity work.pulse_gen
	generic map (
		duration_g => clk_freq/10) -- 100 ms
	port map (
		rst_i => rst,
		clk_i => clk,
		stb_i => run,
		pulse_o => run_pulse);

	led_no <= not ("00000" & tx_p & tx_n & run_pulse);
	tx_po <= tx_p;
	tx_no <= tx_n;

end;