library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.rtl_pack.all;

-- Proposal for a generic state encoding/decoding and error injection package,
-- using only VHDL-93.
package state_pack is

	-- Generic natural encoding/decoding, e.g. for states.
	-- Use the attributes t'val and t'pos to use it with enumeration types.
	-- TODO: Add correctable encodings, e.g. Hamming code.

	type encoding_t is (binary, onehot);
	subtype code_t is std_ulogic_vector;

	function code_length(length : natural; encoding : encoding_t) return natural;
	function encode(value, length : natural; encoding : encoding_t) return code_t;
	function decode(code : code_t; encoding : encoding_t) return natural;
	function error(code : code_t; encoding : encoding_t) return boolean;

	-- Generic value injection into codes, e.g. for error injection into states.
	-- In this implementation it can handle only single bit errors,
	-- but the record and function could be changed without impacting user code.

	type inject_t is record
		index : natural;
		write : boolean;
	end record;

	constant inject_off_c : inject_t := (
		index => 0,
		write => false);

	function handle_inject(code : code_t; inject : inject_t) return code_t;

end;

-- Don't read the boring package body, skip to the example below!
package body state_pack is

	function code_length(length : natural; encoding : encoding_t) return natural is
	begin
		case encoding is
			when binary => return binary_log(length);
			when onehot => return length;
		end case;
	end;

	function encode_onehot(value, length : natural) return code_t is
		variable code : code_t(length-1 downto 0);
	begin
		code := (others => '0');
		code(value) := '1';
		return code;
	end;

	function encode(value, length : natural; encoding : encoding_t) return code_t is
	begin
		case encoding is
			when binary =>
				return std_ulogic_vector(to_unsigned(value, code_length(length, encoding)));
			when onehot =>
				return encode_onehot(value, length);
		end case;
	end;

	function decode(code : code_t; encoding : encoding_t) return integer is
	begin
		if is_x(code) then
			return -1;
		else
			case encoding is
				when binary =>
					return to_integer(unsigned(code));
				when onehot =>
					if one_count(code) /= 1 then
						return -1;
					else
						return binary_log(to_integer(unsigned(code)));
					end if;
			end case;
		end if;
	end;

	function error(code : code_t; encoding : encoding_t) return boolean is
	begin
		return decode(code, encoding) = -1;
	end;

	function handle_inject(code : code_t; inject : inject_t) return code_t is
		variable result : code_t(code'high downto code'low);
	begin
		if inject.write and inject.index >= code'low and inject.index <= code'high then
			result := code;
			result(inject.index) := not result(inject.index);
			return result;
		else
			return code;
		end if;
	end;

end;


library ieee;
use ieee.std_logic_1164.all;

library work;
use work.state_pack.all;

-- Example for a unit implementing a safe state machine using state_pack.
entity safe_state_machine_example is
	generic (
		encoding : encoding_t);
	port (
		clock_i : in std_logic;
		reset_i : in std_logic := '0'; -- Default value indicates that this unit can work without initial reset, for FPGA designs.
		enable_i : in std_logic := '1'; -- Clock enable, may be used to divide the clock.
		error_o : out std_logic;
		state_inject_i : in inject_t := inject_off_c);
end;

architecture rtl of safe_state_machine_example is

	type my_enum_t is (a, b, c);
	constant my_enum_len_c : natural := my_enum_t'pos(my_enum_t'right) + 1;
	subtype my_enum_code_t is code_t(code_length(my_enum_len_c, encoding)-1 downto 0);

	type state_t is record
		my_enum_code : my_enum_code_t;
	end record;
	-- attribute??

	constant reset_state_c : state_t := (
		my_enum_code => encode(my_enum_t'pos(a), my_enum_len_c, encoding));

	signal state, next_state : state_t := reset_state_c;
		-- Initial value required for FPGA designs without reset.

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

	process(state)
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


library ieee;
use ieee.std_logic_1164.all;

library work;
use work.state_pack.all;
use work.tb_pack.all;

entity safe_state_machine_example_check is
end;

architecture bhv of safe_state_machine_example_check is

	signal run : boolean := true;
	signal clock_i : std_ulogic;
	signal state_inject_i : inject_t;

begin

	clk_gen(clock_i, run);

	ssme_gen : for encoding in encoding_t generate
		ssme : entity work.safe_state_machine_example
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