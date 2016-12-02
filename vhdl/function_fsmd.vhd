-- Demonstration of a_i functional FSMD coding style.
entity function_fsmd is
	port(
		clk_i,
		reset_i : in bit;
		a_i, b_i : in bit;
		x_o, y_o : out bit);
end;


architecture rtl of function_fsmd is

	type seq_t is (idle, start, run);

	type state_t is record
		seq : seq_t;
		x : bit;
	end record;

	constant reset_state_c : state_t := (
		seq => idle,
		x => '0');

	signal r : state_t;

	impure function delta(r : state_t) return state_t is
		variable n : state_t := r;
	begin
		case r.seq is
			when idle =>
				if a_i = '1' then
					n.seq := start;
				end if;
			when start =>
				n.seq := run;
				n.x := '1';
			when run =>
				if b_i = '1' then
					n.seq := idle;
					n.x := '0';
				end if;
		end case;
		return n;
	end;

begin

	sync : process(clk_i, reset_i)
	begin
		if reset_i = '1' then
			r <= reset_state_c;
		elsif rising_edge(clk_i) then
			r <= delta(r);
		end if;
	end process;

	lambda : process(r, b_i)
	begin
		x_o <= r.x;
		if r.seq = idle then
			y_o <= b_i;
		else
			y_o <= '0';
		end if;
	end process;

end;
