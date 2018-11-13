library ieee;
use ieee.std_logic_1164.all;

package greycode_pack is
	subtype greycode_t is std_ulogic_vector;
	function to_greycode(binary : std_ulogic_vector) return greycode_t;
	function to_binary(greycode : greycode_t) return std_ulogic_vector;
	function "+"(lhs : greycode_t; rhs : integer) return greycode_t;
end;

library ieee;
use ieee.numeric_std.all;
use ieee.numeric_std_unsigned.all;

library work;
use work.rtl_pack;

package body greycode_pack is

	function to_greycode_bitwise(binary : std_ulogic_vector) return greycode_t is
		variable greycode : greycode_t(binary'range);
	begin
		greycode(binary'high) := binary(binary'high);
		for i in binary'high-1 downto binary'low loop
			greycode(i) := binary(i+1) xor binary(i);
		end loop;
		return greycode;
	end;

	-- Same logic as to_greycode_bitwise, but shorter.
	function to_greycode(binary : std_ulogic_vector) return greycode_t is
		variable greycode : greycode_t(binary'range);
	begin
		return binary xor shift_right(binary, 1);
	end;

	-- Simple implementation with least XORs (b-1) and most logic depth (b-1).
	function to_binary_linear(greycode : greycode_t) return std_ulogic_vector is
		variable binary : std_ulogic_vector(greycode'range);
	begin
		binary(greycode'high) := greycode(greycode'high);
		for i in greycode'high-1 downto greycode'low loop
			binary(i) := binary(i+1) xor greycode(i);
		end loop;
		return binary;
	end;

	-- Convoluted implementation with depth log_ceil(b) but more resources.
	function to_binary(greycode : greycode_t) return std_ulogic_vector is
		variable shift : natural := rtl_pack.log_ceil(greycode'length);
		variable result : std_ulogic_vector(greycode'range) := greycode;
	begin
		while shift /= 0 loop
			result := result xor shift_right(result, 2**shift);
		end loop;
		return result;
	end;

	function "+"(lhs : greycode_t; rhs : integer) return greycode_t is
	begin
		return to_greycode(std_ulogic_vector(unsigned(to_binary(lhs)) + rhs));
	end;

end;