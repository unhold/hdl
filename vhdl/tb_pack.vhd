library std;
use std.textio.all;

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.std_logic_textio.all;

--! General purpose definitions and functions for testbenches.
package tb_pack is

	--! Default clock frequency.
	constant clk_freq_c : positive := 100e6;

	--! Default clock time.
	constant clk_time_c : delay_length := 1 sec / clk_freq_c;

	--! Default reset time.
	constant rst_time_c : delay_length := 20 ns;

	function to_hstring(number : natural)          return string;
	function to_hstring(value : std_ulogic_vector) return string;
	function to_hstring(value : std_logic_vector)  return string;
	function to_hstring(value : unsigned)          return string;
	function to_hstring(value : signed)            return string;

	procedure clk_gen(signal clk: inout std_ulogic; run : in boolean := true; clk_freq : in positive);
	procedure clk_gen(signal clk: inout std_ulogic; run : in boolean := true; clk_time : in delay_length := clk_time_c);

	procedure rst_gen(signal rst: out std_ulogic; rst_time : in delay_length := rst_time_c);

	--! Wait for 'count' clock ticks.
	procedure wait_clk(signal clk : in std_ulogic; count : in natural := 1);

	--! Wait until 'condition' is true.
	procedure wait_clk(signal clk : in std_ulogic; signal condition : in boolean);

	--! Wait until 'condition' is '1' or 'H'.
	procedure wait_clk(signal clk : in std_ulogic; signal condition : in std_ulogic);

end;

package body tb_pack is

	function to_hstring(number : natural) return string is
		variable l : line;
		variable width : natural;
	begin
		return to_hstring(to_unsigned(number, binary_log(number+1)));
	end;

	function to_hstring(value : std_ulogic_vector) return string is
		variable l : line;
	begin
		if value'length mod 4 /= 0 then
			return to_hstring("0" & value);
		else
			hwrite(l, value);
			return l.all;
		end if;
	end;

	function to_hstring(value : std_logic_vector) return string is
	begin return to_hstring(std_ulogic_vector(value)); end;

	function to_hstring(value : unsigned) return string is
	begin return to_hstring(std_ulogic_vector(value)); end;

	function to_hstring(value : signed) return string is
	begin return to_hstring(std_ulogic_vector(value)); end;

	procedure clk_gen(signal clk: inout std_ulogic; run : in boolean := true; clk_freq : in positive) is
	begin
		clk_gen(clk, run, 1 sec / clk_freq);
	end;

	procedure clk_gen(signal clk: inout std_ulogic; run : in boolean := true; clk_time : in delay_length := clk_time_c) is
	begin
		if is_x(clk) then
			clk <= '0';
		elsif run then
			clk <= not clk after clk_time / 2;
		end if;
	end;

	procedure rst_gen(signal rst: out std_ulogic; rst_time : in delay_length := rst_time_c) is
	begin
		rst <= '1', '0' after rst_time;
	end;

	procedure wait_clk(signal clk : in std_ulogic; count : in natural := 1) is
	begin
		if count > 0 then
			for n in 1 to count loop
				wait until rising_edge(clk);
			end loop;
		end if;
	end;

	procedure wait_clk(signal clk : in std_ulogic; signal condition : in boolean) is
	begin
		wait until rising_edge(clk) and condition;
	end;

	procedure wait_clk(signal clk : in std_ulogic; signal condition : in std_ulogic) is
	begin
		wait until rising_edge(clk) and to_x01(condition) = '1';
	end;

end;
