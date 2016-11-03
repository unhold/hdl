library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;


package codec_8b10b_pack is

	subtype b8_t is std_ulogic_vector(7 downto 0);
	subtype b10_t is std_ulogic_vector(9 downto 0);

	type rd_t is (undef, plus1, minus1);

	procedure data_8b10b(
		b8_i : in b8_t;
		rd_i : in rd_t;
		b10_o : out b10_t;
		rd_o : out rd_t);

end;


package body codec_8b10b_pack is

	type rd_change_t is (undef, minus2, unchanged, plus2);

	function to_rd_change(n : integer) return rd_change_t is
	begin
		case n is
			when -2 => return minus2;
			when 0 => return unchanged;
			when 2 => return plus2;
			when others => return undef;
		end case;
	end;

	function "+"(rd : rd_t; rd_change : rd_change_t) return rd_t is
	begin
		case rd_change is
			when unchanged => return rd;
			when minus2 =>
				if rd = plus1 then return minus1;
				else return undef;
				end if;
			when plus2 =>
				if rd = minus1 then return plus1;
				else return undef;
				end if;
			when undef => return undef;
		end case;
	end;

	function rd_change(d : std_ulogic_vector) return rd_change_t is
		variable n : integer;
	begin
		n := 0;
		for i in d'range loop
			case to_x01(d(i)) is
				when '0' => n := n - 1;
				when '1' => n := n + 1;
				when others =>
					return undef;
			end case;
		end loop;
		return to_rd_change(n);
	end;

	subtype b5_t is std_ulogic_vector(4 downto 0);
	subtype b6_t is std_ulogic_vector(5 downto 0);
	type code_5b6b_t is array(0 to 1) of b6_t;
	type table_5b6b_t is array(0 to 31) of code_5b6b_t;

	constant table_5b6b : table_5b6b_t := (
		 0 => (0 => "100111", 1 => "011000"),
		 1 => (0 => "011101", 1 => "100010"),
		 2 => (0 => "101101", 1 => "010010"),
		 3 => (0 => "110001", 1 => "110001"),
		 4 => (0 => "110101", 1 => "001010"),
		 5 => (0 => "101001", 1 => "101001"),
		 6 => (0 => "011001", 1 => "011001"),
		 7 => (0 => "111000", 1 => "000111"),
		 8 => (0 => "111001", 1 => "000110"),
		 9 => (0 => "100101", 1 => "100101"),
		10 => (0 => "010101", 1 => "010101"),
		11 => (0 => "110100", 1 => "110100"),
		12 => (0 => "001101", 1 => "001101"),
		13 => (0 => "101100", 1 => "101100"),
		14 => (0 => "011100", 1 => "011100"),
		15 => (0 => "010111", 1 => "101000"),
		16 => (0 => "011011", 1 => "100100"),
		17 => (0 => "100011", 1 => "100011"),
		18 => (0 => "010011", 1 => "010011"),
		19 => (0 => "110010", 1 => "110010"),
		20 => (0 => "001011", 1 => "001011"),
		21 => (0 => "101010", 1 => "101010"),
		22 => (0 => "011010", 1 => "011010"),
		23 => (0 => "111010", 1 => "000101"),
		24 => (0 => "110011", 1 => "001100"),
		25 => (0 => "100110", 1 => "100110"),
		26 => (0 => "010110", 1 => "010110"),
		27 => (0 => "110110", 1 => "001001"),
		28 => (0 => "001110", 1 => "001110"),
		29 => (0 => "101110", 1 => "010001"),
		30 => (0 => "011110", 1 => "100001"),
		31 => (0 => "101011", 1 => "010100"));

	procedure data_5b6b(
		b5_i : in b5_t;
		rd_i : in rd_t;
		b6_o : out b6_t;
		rd_o : out rd_t) is
 variable b6 : b6_t;
	begin
		case rd_i is
			when minus1 => b6 := table_5b6b(to_integer(unsigned(b5_i)))(0);
			when plus1 => b6 := table_5b6b(to_integer(unsigned(b5_i)))(1);
			when others =>
				b6_o := (others => 'X');
				rd_o := undef;
				return;
		end case;
		b6_o := b6;
		rd_o := rd_i + rd_change(b6);
	end;

	function data_6b5b(b6_i : in b6_t) return b5_t is
	begin
		for i in table_5b6b'range loop
			if b6_i = table_5b6b(i)(0) or b6_i = table_5b6b(i)(1) then
				return b5_t(to_unsigned(i, 5));
			end if;
		end loop;
		return (others => 'X');
	end;

	subtype b3_t is std_ulogic_vector(2 downto 0);
	subtype b4_t is std_ulogic_vector(3 downto 0);
	type code_3b4b_t is array(0 to 1) of b4_t;
	type table_3b4b_t is array(0 to 6) of code_3b4b_t;

	constant table_3b4b : table_3b4b_t := (
		0 => (0 => "1011", 1 => "0100"),
		1 => (0 => "1001", 1 => "1001"),
		2 => (0 => "0101", 1 => "0101"),
		3 => (0 => "1100", 1 => "0011"),
		4 => (0 => "1101", 1 => "0010"),
		5 => (0 => "1010", 1 => "1010"),
		6 => (0 => "0110", 1 => "0110"));
		-- 7 is a special case

	procedure data_3b4b(
		b3_i : in b3_t;
		b6_i : in b6_t;
		rd_i : in rd_t;
		b4_o : out b4_t;
		rd_o : out rd_t) is
 variable b4 : b4_t;
	begin
		b4 := (others => 'X');
		if not is_x(b3_i) then
			case rd_i is
				when minus1 =>
					if b3_i = "111" then
						case b6_i(0) is
							when '0' => b4 := "1110";
							when '1' => b4 := "0111";
							when others => null;
						end case;
					else
						b4 := table_3b4b(to_integer(unsigned(b3_i)))(0);
					end if;
				when plus1 =>
					if b3_i = "111" then
						case b6_i(0) is
							when '0' => b4 := "1000";
							when '1' => b4 := "0001";
							when others => null;
						end case;
					else
						b4 := table_3b4b(to_integer(unsigned(b3_i)))(1);
					end if;
				when others => null;
			end case;
		end if;
		b4_o := b4;
		rd_o := rd_i + rd_change(b4);
	end procedure;

	procedure data_8b10b(
		b8_i : in b8_t;
		rd_i : in rd_t;
		b10_o : out b10_t;
		rd_o : out rd_t) is
			variable b6 : b6_t;
			variable b4 : b4_t;
			variable rd : rd_t;
	begin
		data_5b6b(b8_i(4 downto 0), rd_i, b6, rd);
		data_3b4b(b8_i(7 downto 5), b6, rd, b4, rd_o);
		b10_o := b6 & b4;
	end;

end;