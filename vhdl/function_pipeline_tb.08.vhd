library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;


entity function_pipeline_tb is
end;


architecture tb of function_pipeline_tb is

	subtype my_datai_t is unsigned(3 downto 0);
	subtype my_datao_t is unsigned(4 downto 0);

	function fun(my_datai : my_datai_t) return my_datao_t is
	begin
		return resize(my_datai * 2 - 2, 5);
	end function;

	constant max_stages_c : natural := 3;

	signal clk : bit;

	signal datai : my_datai_t := (others => '0');

	type my_datao_vec_t is array(natural range <>) of my_datao_t;
	signal datao_op, datao_ip : my_datao_vec_t(0 to max_stages_c);

	--psl default clock is rising_edge(clk);

begin

	clk <= not clk after 1 ns;

	process(clk)
	begin
		if rising_edge(clk) then
			datai <= datai + 1;
		end if;
	end process;

	gen_dut : for i in 0 to max_stages_c generate

		dut_op : entity work.function_pipeline(output_pipeline)
			generic map (
				datai_t => my_datai_t,
				datao_t => my_datao_t,
				fun => fun,
				stages_c => i)
			port map (
				clk_i => clk,
				datai_i => datai,
				datao_o => datao_op(i));

		--psl assert next[i] (always datao_op(i) = fun(prev(datai, i)));

		dut_ip : entity work.function_pipeline(input_pipeline)
			generic map (
				datai_t => my_datai_t,
				datao_t => my_datao_t,
				fun => fun,
				stages_c => i)
			port map (
				clk_i => clk,
				datai_i => datai,
				datao_o => datao_ip(i));

		--psl assert next[i] (always datao_ip(i) = fun(prev(datai, i)));

	end generate;

end;
