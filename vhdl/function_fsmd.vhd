-- Demonstration of a functional FSMD coding style.
entity function_fsmd is
	port(
		signal clk,
			reset : in bit;
		signal a, b : in bit;
		signal x, y : out bit);
end;


architecture rtl of function_fsmd is

	type seq_t is (idle, start, run);

	type state_t is record
		seq : seq_t;
		x : bit;
	end record;

	constant c_resestate_t : state_t := (
		seq => idle,
		x => '0');

	signal r : state_t;

	impure function delta(r : state_t) return state_t is
		variable n : state_t := r;
	begin
		case r.seq is
			when idle =>
				if a = '1' then
					n.seq := start;
				end if;
			when start =>
				n.seq := run;
				n.x := '1';
			when run =>
				if b = '1' then
					n.seq := idle;
					n.x := '0';
				end if;
		end case;
		return n;
	end;

begin

	sync : process(clk, reset)
	begin
		if reset = '1' then
			r <= c_resestate_t;
		elsif rising_edge(clk) then
			r <= delta(r);
		end if;
	end process;

	x <= r.x;

end;
