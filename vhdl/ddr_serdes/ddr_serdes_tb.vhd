library ieee;
use ieee.std_logic_1164.all;


entity ddr_serdes_tb is
end;


architecture tb of ddr_serdes_tb is

	constant clk_period_c : time := 5 ns;
	constant data_width_g : positive := 12;
	constant delay_g : time := clk_period_c/4;

	signal clk_i, reset_ni : std_ulogic := '0';
	signal data_i, data_o : std_ulogic_vector(data_width_g-1 downto 0);
	signal start_stb_i : std_ulogic := '0';
	signal valid_stb_o,
		busy_o,
		ddr_data,
		bit_clk,
		frame_clk : std_ulogic;

begin

	clk_i <= not clk_i after clk_period_c/2;

	process
	begin
		reset_ni <= '0';
		wait until rising_edge(clk_i);
		reset_ni <= '1';
		wait until rising_edge(clk_i);
		wait until rising_edge(clk_i);
		wait until rising_edge(clk_i);
		data_i <= "101010110011";
		start_stb_i <= '1';
		wait until rising_edge(clk_i);
		start_stb_i <= '0';
		data_i <= (others => 'X');
		for i in 2 to data_width_g/2 loop
			wait until rising_edge(clk_i);
		end loop;
		data_i <= "111000100010";
		start_stb_i <= '1';
		wait until rising_edge(clk_i);
		start_stb_i <= '0';
		data_i <= (others => 'X');
		wait until rising_edge(clk_i) and busy_o = '0';
		data_i <= "011110100111";
		start_stb_i <= '1';
		wait until rising_edge(clk_i);
		start_stb_i <= '0';
		data_i <= (others => 'X');
		wait until rising_edge(clk_i) and busy_o = '0';

		wait;
	end process;

	ser : entity work.ddr_ser
		generic map (
			data_width_g => data_width_g,
			delay_g => delay_g)
		port map (
			clk_i => clk_i,
			reset_ni => reset_ni,
			data_i => data_i,
			start_stb_i => start_stb_i,
			busy_o => busy_o,
			ddr_data_o => ddr_data,
			bit_clk_o => bit_clk,
			frame_clk_o => frame_clk);

	des : entity work.ddr_des
		generic map (
			data_width_g => data_width_g)
		port map (
			clk_i => clk_i,
			reset_ni => reset_ni,
			data_o => data_o,
			valid_stb_o => valid_stb_o,
			ddr_data_i => ddr_data,
			bit_clk_i => bit_clk,
			frame_clk_i => frame_clk);

end;
