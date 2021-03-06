library ieee;
use ieee.std_logic_1164.all;

package ethernet_10g is

	subtype octet_t is std_ulogic_vector(7 downto 0);
	type octet_vec_t is array(natural range <>) of octet_t;

	-- Standard IEEE802.3-2015 section 4 clause 46:
	-- Reconciliation Sublayer (RS) and 10 Gigabit Media Independent Interface (XGMII)
	type xgmii_t is record
		clock : std_logic; -- XGMII_TX_CLK, XGMII_RX_CLK
		data : std_ulogic_vector(31 downto 0); -- XGMII_TXD, XGMII_RXD
		control : std_ulogic_vector(3 downto 0); -- XGMII_TXC, XGMII_RXC
	end record;

	type xgmii_vec_t is array(natural range <>) of xgmii_t;

	constant xgmii_idle_c : xgmii_t := (
		clock => 'X',
		data => x"07070707", -- idle
		control => "1111");

	constant xgmii_octet_idle_c : octet_t := x"07";
	constant xgmii_octet_start_c : octet_t := x"fb";
	constant xgmii_octet_terminate_c : octet_t := x"fd";

	-- Standard IEEE802.3-2015 section 4 clause 51:
	-- Physical Medium Attachment (PMA) sublayer, type Serial
	-- 10 Gigabit sixteen bit interface
	type xsbi_t is record
		clock : std_logic;
		data : std_ulogic_vector(15 downto 0);
	end record;

	subtype code66_t is std_ulogic_vector(65 downto 0);

	-- Standard IEEE802.3-2015 section 4 clause 49:
	-- Physical Coding Sublayer (PCS) for 64/66b, type 10GBASE-R
	-- Encode and decoding according to 49.2.4 -- 64B/66B transmission code
	function encode_6466b(first, second : xgmii_t) return code66_t;
	function decode_6466b(code : code66_t) return xgmii_vec_t;

end;

package body ethernet_10g is

	subtype ccode_t is std_ulogic_vector(6 downto 0);
	subtype ocode_t is std_ulogic_vector(3 downto 0);

	function to_octet(data : std_ulogic_vector) return octet_vec_t is
		alias data_to : std_ulogic_vector(0 to data'length-1) is data;
		variable octet_vec : octet_vec_t(0 to 0) := (0 => data_to(0 to 7));
	begin
		if data_to'length = 8 then
			return octet_vec;
		else
			return octet_vec & to_octet(
				data_to(8 to data_to'high));
		end if;
	end;

	function to_suv(octet_vec : octet_vec_t) return std_ulogic_vector is
		alias octet_vec_to : octet_vec_t(octet_vec'low to octet_vec'high) is octet_vec;
	begin
		if octet_vec_to'length = 0 then
			return "";
		else
			return octet_vec_to(octet_vec_to'left) & to_suv(
				octet_vec_to(octet_vec_to'left+1 to octet_vec_to'right));
		end if;
	end;

	function to_ccode(octet : octet_t) return ccode_t is
		variable ccode8 : octet_t := (others => 'X');
	begin
		case octet is
			when x"07" => ccode8 := x"00"; -- idle, /I/
			when x"06" => ccode8 := x"06"; -- LPI, /LI/
			when x"1c" => ccode8 := x"2d"; -- reserved0, /R/
			when x"3c" => ccode8 := x"33"; -- reserved1
			when x"7c" => ccode8 := x"4b"; -- reserved2, /A/
			when x"bc" => ccode8 := x"55"; -- reserved3, /K/
			when x"dc" => ccode8 := x"66"; -- reserved4
			when x"f7" => ccode8 := x"78"; -- reserved5
			when others => null;
		end case;
		return ccode8(6 downto 0);
	end;

	function is_ccode(octet : octet_t) return boolean is
	begin
		return not is_x(to_ccode(octet));
	end;

	function ccode_to_octet(ccode : ccode_t) return octet_t is
		constant ccode8 : octet_t := '0' & ccode;
	begin
		case ccode8 is
			when x"00" => return x"07"; -- idle, /I/
			when x"06" => return x"06"; -- LPI, /LI/
			when x"2d" => return x"1c"; -- reserved0, /R/
			when x"33" => return x"3c"; -- reserved1
			when x"4b" => return x"7c"; -- reserved2, /A/
			when x"55" => return x"bc"; -- reserved3, /K/
			when x"66" => return x"dc"; -- reserved4
			when x"78" => return x"f7"; -- reserved5
			when others => return (others => 'X');
		end case;
	end;

	function to_ccode(octet_vec : octet_vec_t) return std_ulogic_vector is
		alias octet_vec_to : octet_vec_t(octet_vec'low to octet_vec'high) is octet_vec;
		constant empty_suv_c : std_ulogic_vector := "";
	begin
		if octet_vec_to'length = 0 then
			return empty_suv_c;
		else
			return to_ccode(octet_vec_to(octet_vec_to'left)) & to_ccode(
				octet_vec_to(octet_vec_to'left+1 to octet_vec_to'right));
		end if;
	end;

	function to_ocode(octet : octet_t) return ocode_t is
	begin
		case octet is
			when x"9c" => return x"0"; -- Sequence ordered set, /Q/
			when x"5c" => return x"F"; -- Signal ordered set, /Fsig/
			when others => return (others => 'X');
		end case;
	end;

	function is_ocode(octet : octet_t) return boolean is
	begin
		return not is_x(to_ocode(octet));
	end;

	function ocode_to_octet(ocode : ocode_t) return octet_t is
	begin
		case ocode is
			when x"0" => return x"9c"; -- Sequence ordered set, /Q/
			when x"F" => return x"5c"; -- Signal ordered set, /Fsig/
			when others => return (others => 'X');
		end case;
	end;

	function to_string(octet : octet_t; control : std_ulogic) return string is
	begin
		if control = '1' then
			if octet = xgmii_octet_start_c then
				return "S";
			elsif octet = xgmii_octet_terminate_c then
				return "T";
			elsif is_ccode(octet) then
				return "C";
			elsif is_ocode(octet) then
				return "O";
			else
				return "X";
			end if;
		elsif control = '0' then
			return "D";
		else
			return "X";
		end if;
	end;

	function to_string(octets : octet_vec_t; control : std_ulogic_vector; from_index : natural := 0) return string is
	begin
		if from_index > octets'high then
			return "";
		else
			return to_string(octets(from_index), control(from_index)) & integer'image(from_index) & " " & to_string(
				octets, control, from_index+1);
		end if;
	end;

	function to_string(first, second : xgmii_t) return string is
		constant data : std_ulogic_vector := first.data & second.data;
		constant control : std_ulogic_vector := first.control & second.control;
		constant octets : octet_vec_t := to_octet(data);
	begin
		return to_string(octets, control);
	end;



	function encode_6466b(first, second : xgmii_t) return code66_t is	
		constant data : std_ulogic_vector(63 downto 0) := second.data & first.data;
		constant control : std_ulogic_vector(7 downto 0) := second.control & first.control;
		constant octets : octet_vec_t(7 downto 0) := to_octet(data);
		variable pl : std_ulogic_vector(63 downto 0) := (others => '-'); -- payload
	begin
		case control is
			when "00000000" => -- D0 D1 D2 D3/D4 D5 D6 D7
				return code66_t'(data & "10");
			when "11111111" =>
				if octets(0) = xgmii_octet_terminate_c then -- T0 C1 C2 C3/C4 C5 C6 C7
					pl := to_ccode(octets(7 downto 1)) & "0000000" & x"87";
				else -- C0 C1 C2 C3/C4 C5 C6 C7
					pl := to_ccode(octets) & x"1e";
				end if;
			when "11111000" =>
				if is_ocode(octets(4)) then -- C0 C1 C2 C3/O4 D5 D6 D7
					pl := to_suv(octets(7 downto 5)) & to_ocode(octets(4)) & to_ccode(octets(4 downto 0)) & x"2d";
				elsif octets(4) = xgmii_octet_start_c then -- C0 C1 C2 C3/S4 D5 D6 D7
					pl := to_suv(octets(7 downto 5)) & "0000" & to_ccode(octets(4 downto 0)) & x"33";
				end if;
			when "10001000" =>
				if octets(4) = xgmii_octet_start_c then -- O0 D1 D2 D3/S4 D5 D6 D7
					pl := to_suv(octets(7 downto 5)) & "0000" & to_ocode(octets(0)) & to_suv(octets(4 downto 1)) & x"66";
				elsif is_ocode(octets(4)) then -- O0 D1 D2 D3/O4 D5 D6 D7
					pl := to_suv(octets(7 downto 5)) & to_ocode(octets(4)) & to_ocode(octets(0)) & to_suv(octets(3 downto 1)) & x"55";
				end if;
			when "10000000" => -- S0 D1 D2 D3/D4 D5 D6 D7
				if octets(0) = xgmii_octet_start_c then
					pl := to_suv(octets(7 downto 1)) & x"78";
				end if;
			when "10001111" => -- O0 D1 D2 D3/C4 C5 C6 C7
				pl := to_ccode(octets(7 downto 4)) & to_ocode(octets(0)) & to_suv(octets(3 downto 1)) & x"4b";
			when "01111111" =>
				if octets(1) = xgmii_octet_terminate_c then -- D0 T1 C2 C3/C4 C5 C6 C7
					pl := to_ccode(octets(7 downto 2)) & "000000" & octets(0) & x"99";
				end if;
			when "00111111" =>
				if octets(2) = xgmii_octet_terminate_c then -- D0 D1 T2 C3/C4 C5 C6 C7
					pl := to_ccode(octets(7 downto 2)) & "00000" & to_suv(octets(1 downto 0)) & x"aa";
				end if;
			when "00011111" =>
				if octets(3) = xgmii_octet_terminate_c then -- D0 D1 D2 T3/C4 C5 C6 C7
					pl := to_ccode(octets(7 downto 3)) & "0000" & to_suv(octets(2 downto 0)) & x"b4";
				end if;
			when "00001111" =>
				if octets(4) = xgmii_octet_terminate_c then -- D0 D1 D2 D3/T4 C5 C6 C7
					pl := to_ccode(octets(7 downto 4)) & "00" & to_suv(octets(3 downto 0)) & x"cc";
				end if;
			when "00000111" =>
				if octets(5) = xgmii_octet_terminate_c then -- D0 D1 D2 D3/D4 T5 C6 C7
					pl := to_ccode(octets(7 downto 5)) & "00" & to_suv(octets(4 downto 0)) & x"d2";
				end if;
			when "00000011" =>
				if octets(6) = xgmii_octet_terminate_c then -- D0 D1 D2 D3/D4 D5 T6 C7
					pl := to_ccode(octets(7 downto 6)) & "0" & to_suv(octets(5 downto 0)) & x"e1";
				end if;
			when "00000001" =>
				if octets(7) = xgmii_octet_terminate_c then -- D0 D1 D2 D3/D4 D5 D6 T7
					pl := to_suv(octets(6 downto 0)) & x"ff";
				end if;
			when others => null;
		end case;
		assert not is_x(pl) report "encode_6466b: invalid input data block format " & to_string(first, second) severity warning;
		return code66_t'(pl & "10");
	end;

	function decode_6466b(code : code66_t) return xgmii_vec_t is
	
		type code_type_t is ('D', 'C', 'O', 'S', 'T', 'X');
		type code_type_vec_t is array(natural range<>) of code_type_t;
		type natural_vec_t is array(natural range<>) of natural;
		type control_block_format_t is record
			types : code_type_vec_t(0 to 7);
			starts : natural_vec_t(0 to 7);
		end record;

		-- Standard IEEE802.3-2015 section 4 clause 49:
		-- Code the table from Figure 49-7 -- 64B/66B block formats
		function field_to_format(field : octet_t) return control_block_format_t is
		begin
			case field is
				when x"1e" => return control_block_format_t'(types => "CCCCCCCC", starts => (10, 17, 24, 31, 38, 45, 52, 59));
				when x"2d" => return control_block_format_t'(types => "CCCCODDD", starts => (10, 17, 24, 31, 38, 42, 50, 58));
				when x"33" => return control_block_format_t'(types => "CCCCSDDD", starts => (10, 17, 24, 31, 66, 42, 50, 58));
				when x"66" => return control_block_format_t'(types => "ODDDSDDD", starts => (34, 10, 18, 26, 66, 42, 50, 58));
				when x"55" => return control_block_format_t'(types => "ODDDODDD", starts => (32, 10, 18, 24, 38, 40, 48, 56));
				when x"78" => return control_block_format_t'(types => "SDDDDDDD", starts => (66, 10, 18, 24, 32, 40, 48, 56));
				when x"4b" => return control_block_format_t'(types => "ODDDCCCC", starts => (32, 10, 18, 24, 38, 45, 52, 59));
				when x"87" => return control_block_format_t'(types => "TCCCCCCC", starts => (66, 17, 24, 31, 38, 45, 52, 59));
				when x"99" => return control_block_format_t'(types => "DTCCCCCC", starts => (10, 66, 24, 31, 38, 45, 52, 59));
				when x"aa" => return control_block_format_t'(types => "DDTCCCCC", starts => (10, 18, 66, 31, 38, 45, 52, 59));
				when x"b4" => return control_block_format_t'(types => "DDDTCCCC", starts => (10, 18, 24, 66, 38, 45, 52, 59));
				when x"cc" => return control_block_format_t'(types => "DDDDTCCC", starts => (10, 18, 24, 32, 66, 45, 52, 59));
				when x"d2" => return control_block_format_t'(types => "DDDDDTCC", starts => (10, 18, 24, 32, 40, 66, 52, 59));
				when x"e1" => return control_block_format_t'(types => "DDDDDDTC", starts => (10, 18, 24, 32, 40, 48, 66, 59));
				when x"ff" => return control_block_format_t'(types => "DDDDDDDT", starts => (10, 18, 24, 32, 40, 48, 56, 66));
				when others => return control_block_format_t'(types => "XXXXXXXX", starts => (others => 66));
			end case;
		end;		

		function decode_data(type_i : code_type_t; start_i : natural) return octet_t is
		begin
			case type_i is
				when 'D' => return octet_t(code(start_i+7 downto start_i));
				when 'C' => return ccode_to_octet(code(start_i+6 downto start_i));
				when 'O' => return ocode_to_octet(code(start_i+3 downto start_i));
				when 'S' => assert start_i = 66; return xgmii_octet_start_c;
				when 'T' => assert start_i = 66; return xgmii_octet_terminate_c;
				when 'X' => return (others => 'X');
			end case;
		end;
		function decode_control(type_i : code_type_t) return std_ulogic is
		begin
			case type_i is
				when 'D' => return '0';
				when 'C' | 'O' | 'S' | 'T' => return '1';
				when 'X' => return 'X';
			end case;
		end;
		variable data : octet_vec_t(7 downto 0) := (others => (others => 'X'));
		variable control : std_ulogic_vector(7 downto 0) := (others => 'X');
		variable format : control_block_format_t;
	begin
		case code(1 downto 0) is
		when "10" =>
			data := to_octet(code(65 downto 2));
			control := (others => '0');
		when "01" =>
			format := field_to_format(code(9 downto 2));
			for i in 0 to 7 loop
				data(i) := decode_data(format.types(i), format.starts(i));
				control(i) := decode_control(format.types(i));
			end loop;
		when others =>
			null;
		end case;
		return (
			0 => (clock => 'X', data => to_suv(data(3 downto 0)), control => control(3 downto 0)),
			1 => (clock => 'X', data => to_suv(data(7 downto 4)), control => control(7 downto 4)));
	end;
end;


library ieee;
use ieee.std_logic_1164.all;

entity scrambler_descrambler is
	generic (
		descramble_g : boolean);
	port (
		reset_i : in std_ulogic := '0';
		clock_i : in std_ulogic;
		bypass_i : in std_ulogic := '0';
		valid_i : in std_ulogic := '1';
		data_i : in std_ulogic_vector(65 downto 0);
		valid_o : out std_ulogic;
		data_o : out std_ulogic_vector(65 downto 0));
end;

architecture rtl of scrambler_descrambler is

	subtype state_t is std_ulogic_vector(57 downto 0);

	procedure scramble_descrambe(
		bit_i : in std_ulogic;
		bit_o : out std_ulogic;
		state_io : inout state_t;
		descramble_g : in boolean) is
		variable bit_v : std_ulogic;
	begin
		bit_v := bit_i xor state_io(38) xor state_io(57);
		bit_o := bit_v;
		if descramble_g then
			state_io := state_io(56 downto 0) & bit_v;
		else
			state_io := state_io(56 downto 0) & bit_i;
		end if;
	end;

	signal state_r : state_t := (others => '0');

begin

	sync : process(reset_i, clock_i)
		variable state_v : state_t;
		variable data_v : std_ulogic_vector(65 downto 0);
	begin
		if reset_i = '1' then
			state_r <= (others => '0');
			data_o <= (others => '-');
			valid_o <= '0';
		elsif rising_edge(clock_i) then
			if valid_i = '1' then
				state_v := state_r;
				-- No scrambling for the sync bits
				for i in 63 downto 0 loop -- TODO: direction?
					scramble_descrambe(data_i(i), data_v(i), state_v, descramble_g);
				end loop;
				state_r <= state_v;
				if bypass_i = '1' then
					data_o <= data_i;
				else
					data_v(65 downto 64) := data_i(65 downto 64);
					data_o <= data_v;
				end if;
			end if;
			valid_o <= valid_i;
		end if;
	end process;

end;


library ieee;
use ieee.std_logic_1164.all;

library work;
use work.ethernet_10g.all;

entity pcs_6466b_tx is
	port (
		xgmii_i : in xgmii_t;
		xsbi_o : out xsbi_t);
end;

architecture rtl of pcs_6466b_tx is

	signal last_xgmii_r : xgmii_t := xgmii_idle_c;
	signal encoder_valid_r : std_ulogic := '0';
	signal encoder_data_r : code66_t;
	signal scrambler_valid : std_ulogic;
	signal scrambler_data : code66_t;
	signal demux_data : std_ulogic_vector(32 downto 0);
	signal xsbi : xsbi_t;

begin

	encoder : process(xgmii_i)
	begin
		if rising_edge(xgmii_i.clock) then
			encoder_valid_r <= not encoder_valid_r;
			if encoder_valid_r = '1' then
				-- Could always be assigned, but this may safe power.
				last_xgmii_r <= xgmii_i;
			else
				encoder_data_r <= encode_6466b(xgmii_i, last_xgmii_r);
			end if;
		end if;
	end process;

	scrambler : entity work.scrambler_descrambler
		generic map (
			descramble_g => false)
		port map (
			clock_i => xgmii_i.clock,
			valid_i => encoder_valid_r,
			data_i => encoder_data_r,
			valid_o => scrambler_valid,
			data_o => scrambler_data);

	demux : process(xgmii_i)
	begin
		if rising_edge(xgmii_i.clock) then
			if scrambler_valid = '1' then
				demux_data <= scrambler_data(65 downto 33);
			else
				demux_data <= scrambler_data(32 downto 0);
			end if;
		end if;
	end process;

	pll : entity work.pll
		generic map (
			multiplier_g => 33,
			divider_g => 16)
		port map (
			clock_i => xgmii_i.clock,
			clock_o => xsbi.clock);

	-- The use of the intermediate signal xsbi may appear unnecessary,
	-- but this assignment order avoids clock/data delta-cycle race conditions.

	gearbox : entity work.gearbox
		generic map (
			a_width_g => 33,
			b_width_g => 16,
			fifo_depth_order_g => 4)
		port map (
			a_clock_i => xgmii_i.clock,
			a_data_i => demux_data,
			b_clock_i => xsbi.clock,
			b_data_o => xsbi.data);

	xsbi_o <= xsbi;

end;


library ieee;
use ieee.std_logic_1164.all;

library work;
use work.ethernet_10g.all;

entity pcs_6466b_rx is
	port (
		xsbi_i : in xsbi_t;
		xgmii_o : out xgmii_t);
end;

architecture rtl of pcs_6466b_rx is
begin


end;


library work;
use work.ethernet_10g.all;

-- Standard IEEE802.3-2015 section 4 clause 49:
-- Physical Coding Sublayer (PCS) for 64/66b, type 10GBASE-R
entity pcs_6466b is
	port (
		xgmii_tx_i : in xgmii_t;
		xsbi_tx_o : out xsbi_t;
		xsbi_rx_i : in xsbi_t;
		xgmii_rx_o : out xgmii_t);
end;

architecture rtl of pcs_6466b is
begin
	pcs_6466b_tx : entity work.pcs_6466b_tx
		port map (
			xgmii_i => xgmii_tx_i,
			xsbi_o => xsbi_tx_o);
	pcs_6466b_rx : entity work.pcs_6466b_rx
		port map (
			xsbi_i => xsbi_rx_i,
			xgmii_o => xgmii_rx_o);
end;