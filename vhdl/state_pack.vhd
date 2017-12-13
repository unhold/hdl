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