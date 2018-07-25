library ieee;
use ieee.std_logic_1164.all;

library work;
use work.state_pack.all;

-- Example for a unit implementing a safe state machine using state_pack.
entity safe_state_machine is
	generic (
		encoding : encoding_t);
	port (
		clock_i : in std_logic;
		reset_i : in std_logic := '0'; -- Asynchronous reset, default value indicates that this unit can work without initial reset, for FPGA designs.
		enable_i : in std_logic := '1'; -- Clock enable, may be used to divide the clock.
		error_o : out std_logic;
		state_inject_i : in inject_t := inject_off_c);
end;

architecture rtl of safe_state_machine is

	type my_enum_t is (a, b, c);
	constant my_enum_len_c : natural := my_enum_t'pos(my_enum_t'right) + 1;
	subtype my_enum_code_t is code_t(code_length(my_enum_len_c, encoding)-1 downto 0);

	type state_t is record
		my_enum_code : my_enum_code_t;
	end record;

	constant reset_state_c : state_t := (
		my_enum_code => encode(my_enum_t'pos(a), my_enum_len_c, encoding));

	-- If your implementation tool is smart enough to for sequential optimizations,
	-- you have to set the appropirate attribute to avoid recoding of the state!
	-- This may be a VHDL attribute, a TCL command or another tool-specific setting.
	-- Using the state_inject_i input and making it externally controllabe
	-- will also avoid optimizations and preserve the state encoding.
	signal state, next_state : state_t := reset_state_c;
		-- Initial value required for FPGA designs without reset.

	-- Disable sequential optimizations for Synopsys and Synplicity.
	attribute syn_preserve : boolean;
	attribute syn_preserve of state : signal is true;

begin

	process(clock_i, reset_i)
	begin
		if reset_i = '1' then
			state <= reset_state_c;
		elsif rising_edge(clock_i) then
			if enable_i = '1' then
				state <= next_state;
			end if;
		end if;
	end process;

	process(state, state_inject_i)
		variable my_enum_v, next_my_enum_v : my_enum_t;
	begin

		error_o <= '0';
		if error(state.my_enum_code, encoding) then
			-- Handle uncorrectable errors.
			-- Optional, as only some encodings can have errors that are detectable but not correctable.
			my_enum_v := a;
			error_o <= '1';
		else
			-- Decode.
			my_enum_v := my_enum_t'val(decode(state.my_enum_code, encoding));
		end if;

		-- State machine logic.
		case my_enum_v is
			when a => next_my_enum_v := b;
			when b => next_my_enum_v := c;
			when c => next_my_enum_v := a;
		end case;

		-- Encode and handle state injection.
		next_state <= (
			my_enum_code => handle_inject(
				encode(my_enum_t'pos(next_my_enum_v), my_enum_len_c, encoding),
				state_inject_i));
	end process;

end;


entity safe_state_machine_tb is
end;

library ieee;
use ieee.std_logic_1164.all;

library work;
use work.state_pack.all;
use work.tb_pack.all;

architecture tb of safe_state_machine_tb is

	signal run : boolean := true;
	signal clock_i : std_ulogic;
	signal state_inject_i : inject_t;

begin

	clk_gen(clock_i, run);

	ssme_gen : for encoding in encoding_t generate
		ssme : entity work.safe_state_machine
			generic map (
				encoding => encoding)
			port map (
				clock_i => clock_i,
				state_inject_i => state_inject_i);
	end generate;

	process
	begin
		wait_clk(clock_i, 5);

		state_inject_i <= (
			index => 1,
			write => true);
		wait_clk(clock_i, 1);
		state_inject_i <= inject_off_c;
		wait_clk(clock_i, 1);

		state_inject_i <= (
			index => 1,
			write => true);
		wait_clk(clock_i, 1);
		state_inject_i <= inject_off_c;
		wait_clk(clock_i, 1);

		wait_clk(clock_i, 5);
		run <= false;
		wait;
	end process;

end;