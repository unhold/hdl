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

architecture tb of vether_tb is

	procedure write(filename : string; data : data_t) is
		file f : text is out filename;
		variable l : line;
	begin
		for i in data'range loop
			write(l, to_hstring(data(i)));
			writeline(f, l);
		end loop;
	end;

	constant clk_freq : natural := 20_460e3;
	signal clk : std_ulogic := '0';
	signal stb, run, tx_p, tx_n, run_pulse : std_ulogic;

	constant ref_frame : mac_t := (
		x"00", x"10", x"A4", x"7B", x"EA", x"80", -- dst
		x"00", x"12", x"34", x"56", x"78", x"90", -- src
		x"08", x"00", -- ethertype
		x"45", x"00", x"00", x"2E", x"B3", x"FE", x"00",
		x"00", x"80", x"11", x"05", x"40", x"C0", x"A8", x"00", x"2C",
		x"C0", x"A8", x"00", x"04", x"04", x"00", x"04", x"00", x"00",
		x"1A", x"2D", x"E8", x"00", x"01", x"02", x"03", x"04", x"05",
		x"06", x"07", x"08", x"09", x"0A", x"0B", x"0C", x"0D", x"0E",
		x"0F", x"10", x"11", -- data
		x"B3", x"31", x"88", x"1B"); -- fcs

	constant gen_frame : mac_t := to_mac(x"0010A47BEA80", x"001234567890", (
		x"45", x"00", x"00", x"2E", x"B3", x"FE", x"00",
		x"00", x"80", x"11", x"05", x"40", x"C0", x"A8", x"00", x"2C",
		x"C0", x"A8", x"00", x"04", x"04", x"00", x"04", x"00", x"00",
		x"1A", x"2D", x"E8", x"00", x"01", x"02", x"03", x"04", x"05",
		x"06", x"07", x"08", x"09", x"0A", x"0B", x"0C", x"0D", x"0E",
		x"0F", x"10", x"11"));

begin

	process
	begin
		write("ref_frame.dat", ref_frame);
		write("gen_frame.dat", gen_frame);
		assert ref_frame = gen_frame report "frame mismatch";
		wait;
	end process;

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
