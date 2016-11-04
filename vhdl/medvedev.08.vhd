--- Generic Medvedev state machine.
entity medvedev is

	generic (
		type input_t;
		type state_t;
		constant reset_state_c : state_t;
		function delta(state : state_t; input : input_t) return state_t);

	port(
		signal clk_i,
			reset_i : in bit;
		signal input_i : in input_t;
		signal state_o : out state_t);

end;


architecture rtl of medvedev is

	signal state : state_t;

begin

	sync : process(clk_i, reset_i)
	begin
		if reset_i = '1' then
			state <= reset_state_c;
		elsif rising_edge(clk_i) then
			state <= delta(state, input_i);
		end if;
	end process;

	state_o <= state;

end;


entity medvedev_user is
	port (
		signal clk_i, reset_i : in bit;
		signal a_i, b_i : in bit;
		signal x_o, y_o, z_o : out bit);
end;


architecture rtl of medvedev_user is

	type input_t is record
		a, b : bit;
	end record;

	type seq_t is (idle, start, run);

	type state_t is record
		seq : seq_t;
		x : bit;
	end record;

	signal state : state_t;

	constant reset_state_c : state_t := (
		seq => idle,
		x => '0');

	function delta(s : state_t; i : input_t) return state_t is
		variable n : state_t := s;
	begin
		case s.seq is
			when idle =>
				if i.a = '1' then
					n.seq := start;
				end if;
			when start =>
				n.seq := run;
				n.x := '1';
			when run =>
				if i.b = '1' then
					n.seq := idle;
					n.x := '0';
				end if;
		end case;
		return n;
	end;

begin

	medvedev : entity work.medvedev
		generic map (
			input_t, state_t, reset_state_c, delta)
		port map (
			clk_i => clk_i,
			reset_i => reset_i,
			input_i => input_t'(a => a_i, b => b_i),
			state_o => state);

	medvedev_output : x_o <= state.x;

	moore_lambda : y_o <= '1' when state.seq = start else '0';

	mealy_lambda : z_o <= state.x and a_i;

end;
