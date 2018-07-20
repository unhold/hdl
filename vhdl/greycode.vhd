library ieee;
use ieee.std_logic_1164.all;

package greycode is
	subtype greycode_t is std_ulogic_vector;
	function to_greycode(binary : std_ulogic_vector) return greycode_t;
	function to_binary(greycode : greycode_t) return std_ulogic_vector;
	function increment(greycode : greycode_t) return greycode_t;
end;

library ieee;
use ieee.numeric_std.all;

package body greycode is
	function to_greycode(binary : std_ulogic_vector) return std_ulogic_vector is
		variable greycode : std_ulogic_vector(binary'range);
	begin
		greycode(binary'high) := binary(binary'high);
		for i in binary'high-1 downto binary'low loop
			greycode(i) := binary(i+1) xor binary(i);
		end loop;
		return greycode;
	end;
	function to_binary(greycode : std_ulogic_vector) return std_ulogic_vector is
		variable binary : std_ulogic_vector(greycode'range);
	begin
		binary(greycode'high) := greycode(greycode'high);
		for i in greycode'high-1 downto greycode'low loop
			binary(i) := binary(i+1) xor greycode(i);
		end loop;
		return binary;
	end;
	function increment(greycode : greycode_t) return greycode_t is
	begin
		return to_greycode(to_binary(std_ulogic_vector(unsigned(greycode) + 1)));
	end;
end;