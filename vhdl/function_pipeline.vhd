--- Pipeline a function, using synthesis register retiming feature.
entity function_pipeline is

	generic (
		type datai_t;
		type datao_t;
		function fun(datai : datai_t) return datao_t;
		constant stages_c : natural);

	port (
		signal clk_i : in bit;
		signal datai_i : in datai_t;
		signal datao_o : out datao_t);

end;


architecture output_pipeline of function_pipeline is

	type pipeline_t is array(stages_c-1 downto 0) of datao_t;
	signal pl : pipeline_t;

begin

	gen_pipeline : if stages_c > 0 generate

		process(clk_i)
		begin
			if rising_edge(clk_i) then
				pl <= pl(pl'left-1 downto 0) & fun(datai_i);
			end if;
		end process;

		datao_o <= pl(pl'left);

	else generate

		datao_o <= fun(datai_i);

	end generate;

end;


architecture input_pipeline of function_pipeline is

	type pipeline_t is array(stages_c-2 downto 0) of datai_t;
	signal pl : pipeline_t;

begin

	gen_pipeline : if stages_c > 0 generate

		process(clk_i)
		begin
			if rising_edge(clk_i) then
				if stages_c > 1 then
					pl <= pl(pl'left-1 downto 0) & datai_i;
					datao_o <= fun(pl(pl'left));
				else
					datao_o <= fun(datai_i);
				end if;
			end if;
		end process;

	else generate

		datao_o <= fun(datai_i);

	end generate;

end;
