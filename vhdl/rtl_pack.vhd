library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

--! General purpose definitions and functions for RTL code.
package rtl_pack is

	function to_bit(value : boolean) return bit;
	function to_stdulogic(value : boolean) return std_ulogic;

	--! Calculate the binary logarithm of 'number', rounding up. 0/1 yield 0.
	function binary_log(number : natural) return natural;

	--! Round 'number' up to the next multiple of 'factor'.
	function next_multiple(number : natural; factor : positive) return natural;

	--! Revese the bit-order of a vector. Direction stays the same.
	function bit_reverse(vector : std_ulogic_vector) return std_ulogic_vector;

	--! Count the number of '1's in a vector.
	function one_count(vector : std_ulogic_vector) return natural;

	--! Check constant conditions in declarative sections.
	function check(
		condition : boolean;
		message : string := "";
		sl : severity_level := error) return boolean;

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

	function binary_log(number : natural) return natural is
		variable climb : positive := 1;
		variable result : natural := 0;
	begin
		while climb < number loop
			climb := climb * 2;
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

	function bit_reverse(vector : std_ulogic_vector) return std_ulogic_vector is
		variable reverse : std_ulogic_vector(vector'reverse_range);
		variable result  : std_ulogic_vector(vector'range);
	begin
		for i in vector'range loop
			reverse(i) := vector(i);
		end loop;
		result := reverse;
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
		message : string := "";
		sl : severity_level := error) return boolean is
	begin
		assert condition report message severity sl;
		return condition;
	end;

end;
