library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.rtl_pack.all;
use work.tb_pack.all;

entity gearbox_tb is
end;

architecture tb of gearbox_tb is

	constant a_width_g : positive := 4;
	constant b_width_g : positive := 3;
	constant fifo_depth_order_g : positive := 4;

	signal run : boolean := true;
	signal reset : std_ulogic := '1';
	signal a_reset_i : std_ulogic;
	signal a_clock_i : std_ulogic;
	signal a_data_i, a_data_o : std_ulogic_vector(a_width_g-1 downto 0);
	signal b_reset_i : std_ulogic;
	signal b_clock_i : std_ulogic;
	signal b_data : std_ulogic_vector(b_width_g-1 downto 0);
	signal pll_lock : std_ulogic;

begin

	clk_gen(a_clock_i, run);

	pll : entity work.pll
	generic map (
		multiplier_g => a_width_g,
		divider_g => b_width_g)
	port map (
		run_i => run,
		clock_i => a_clock_i,
		clock_o => b_clock_i,
		lock_o => pll_lock);

	reset_a_sync : entity work.sync
	generic map (
		reset_value_g => '1')
	port map (
		reset_i => reset,
		clock_i => a_clock_i,
		data_i(0) => reset,
		data_o(0) => a_reset_i);

	reset_b_sync : entity work.sync
	generic map (
		reset_value_g => '1')
	port map (
		reset_i => reset,
		clock_i => b_clock_i,
		data_i(0) => reset,
		data_o(0) => b_reset_i);

	gearbox_a_b : entity work.gearbox
	generic map (
	    a_width_g => a_width_g,
	    b_width_g => b_width_g,
	    fifo_depth_order_g => fifo_depth_order_g)
	port map (
	    a_reset_i => a_reset_i,
	    a_clock_i => a_clock_i,
	    a_data_i => a_data_i,
	    b_reset_i => b_reset_i,
	    b_clock_i => b_clock_i,
	    b_data_o => b_data);

	gearbox_b_a : entity work.gearbox
	generic map (
	    a_width_g => b_width_g,
	    b_width_g => a_width_g,
	    fifo_depth_order_g => fifo_depth_order_g)
	port map (
	    a_reset_i => b_reset_i,
	    a_clock_i => b_clock_i,
	    a_data_i => b_data,
	    b_reset_i => a_reset_i,
	    b_clock_i => a_clock_i,
	    b_data_o => a_data_o);

	stim : process
	begin
		rst_gen(reset);
		wait until (a_reset_i or b_reset_i) = '0';
		for i in 0 to 2**a_width_g-1 loop
			a_data_i <= std_ulogic_vector(to_unsigned(i, a_width_g));
			wait_clk(a_clock_i);
		end loop;
		wait_clk(a_clock_i, 2**(fifo_depth_order_g+1));
		run <= false;
		wait;
	end process;

end;