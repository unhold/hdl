library ieee;
use ieee.std_logic_1164.all;

library work;
use work.tb_pack.all;


entity vether_tb is
	port (
		tx_po,
		tx_no : out std_ulogic;
		led_no : out std_ulogic_vector(7 downto 0));
end;


architecture tbd of vether_tb is

	constant clk_freq : natural := 20_460e3;
	signal clk : std_ulogic := '0';
	signal stb, run : std_ulogic;

begin

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
		tx_po => tx_po,
		tx_no => tx_no,
		run_o => run);

	led_no <= not ("000000" & stb & run);

end;