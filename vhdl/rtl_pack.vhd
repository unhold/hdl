library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

--! General purpose definitions and functions for RTL code.
package rtl_pack is

	function to_bit(value : boolean) return bit;
	function to_stdulogic(value : boolean) return std_ulogic;

	subtype base_t is natural range 2 to natural'high;

	--! Calculate the logarithm of 'number' to given 'base', rounding up.
	function log_ceil(number : positive; base : base_t := 2) return natural;

	--! Round 'number' up to the next multiple of 'factor'.
	function next_multiple(number : natural; factor : positive) return natural;

	--! Reverse the bits of a vector.
	--! The Direction of the range stays the same.
	function reverse(vector : std_ulogic_vector) return std_ulogic_vector;

	--! Count the number of '1's in a vector.
	function one_count(vector : std_ulogic_vector) return natural;

	--! Check constant conditions in declarative sections.
	function check(
		condition : boolean;
		name : string := "(unnamed)";
		sl : severity_level := error) return boolean;

	function maximum(a, b : integer) return integer;
	function minimum(a, b : integer) return integer;

end;

package body rtl_pack is

	function to_bit(value : boolean) return bit is
	begin
		if value then return '1';
		else          return '0';
		end if;
	end;

	function to_stdulogic(value : boolean) return std_ulogic is
	begin
		if value then return '1';
		else          return '0';
		end if;
	end;

	function log_ceil(number : positive; base : base_t := 2) return natural is
		variable climb : positive := 1;
		variable result : natural := 0;
	begin
		while climb < number loop
			climb := climb * base;
			result := result + 1;
		end loop;
		return result;
	end;

	function next_multiple(number : natural; factor : positive) return natural is
		variable result : natural := 0;
	begin
		while result < number loop
			result := result + factor;
		end loop;
		return result;
	end;

	function reverse(vector : std_ulogic_vector) return std_ulogic_vector is
		alias renumbered : std_ulogic_vector(vector'reverse_range) is vector;
		variable result : std_ulogic_vector(vector'range);
	begin
		for i in vector'range loop
			result(i) := renumbered(i);
		end loop;
		return result;
	end;

	function one_count(vector : std_ulogic_vector) return natural is
		variable result : natural := 0;
	begin
		for i in vector'range loop
			if to_X01(vector(i)) = '1' then
				result := result + 1;
			end if;
		end loop;
		return result;
	end;

	function check(
		condition : boolean;
		name : string := "(unnamed)";
		sl : severity_level := error) return boolean is
	begin
		assert condition report "rtl_pack.check failed: " & name severity sl;
		return condition;
	end;

	function maximum(a, b : integer) return integer is
	begin
		if a > b then return a;
		else return b;
		end if;
	end;

	function minimum(a, b : integer) return integer is
	begin
		if a < b then return a;
		else return b;
		end if;
	end;

end;