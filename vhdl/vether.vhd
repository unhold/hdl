library ieee;
use ieee.numeric_bit.all;

--! Ethernet 10BASE-T,
--! IEEE802.3-2008 clauses 3, 7.
package vether is

	subtype octet_t is unsigned(7 downto 0);
	type data_t is array(natural range <>) of octet_t;
	subtype mac_addr_t is unsigned(47 downto 0);

	function repeat(data : data_t; count : positive) return data_t;

	--- Word/data conversion, high byte first:
	function to_data(word : unsigned) return data_t;
	function to_word(data : data_t) return unsigned;

	--- Frame types of the sublayers:
	subtype mac_t is data_t;     --! Media Access Control frame
		--! TODO: change to record?
	subtype pls_t is bit_vector; --! Physical Layer Symbol frame
	subtype pma_t is bit_vector; --! Physical Media Attachment frame

	--! Encapsulate data into MAC frame, calculate FCS.
	function to_mac(dst, src : mac_addr_t; data : data_t) return mac_t;
		--! TODO: add padding?
		--! TODO: add ethertype I/II options

	--! Covert to PLS frame: serialize, add preamble, SFD and ETD.
	function to_pls(mac : mac_t) return pls_t;

	--! Convert to PMA frame: Manchester-encode.
	--! May also be done with clock-XOR.
	function to_pma(pls : pls_t) return pma_t;

	constant crc32_polynomial : unsigned(31 downto 0) := (
		26 => '1', 23 => '1', 22 => '1', 16 => '1', 12 => '1',
		11 => '1', 10 => '1',  8 => '1',  7 => '1',  5 => '1',
		 4 => '1',  2 => '1',  1 => '1',  0 => '1', others => '0');

	constant addr : mac_addr_t := x"123456789ABC";
	constant data : data_t;
	constant mac : mac_t;
	constant pls : pls_t;
	constant pma : pma_t;

end;

package body vether is

	function to_manchester(pls_bit : bit) return pma_t is
	begin
		case pls_bit is
			when '0' => return "10";
			when '1' => return "01";
		end case;
	end function;

	function reverse(data : bit_vector) return bit_vector is
		constant data_reverse : bit_vector(data'reverse_range) := data;
		variable result : bit_vector(data'range);
	begin
		for i in result'range loop
			result(i) := data_reverse(i);
		end loop;
		return result;
	end;

	function repeat(data : bit_vector; count : positive)
		return bit_vector is
	begin
		if count = 1 then
			return data;
		else
			return data & repeat(data, count-1);
		end if;
	end;

	function repeat(data : data_t; count : positive) return data_t is
	begin
		if count = 1 then
			return data;
		else
			return data & repeat(data, count-1);
		end if;
	end;

	function to_pma_data(pls : pls_t) return pma_t is
	begin
		if pls'length = 0 then
			return "";
		-- Could do without the elsif, directly in the else,
		-- but this avoids warnings about the empty range.
		elsif pls'length = 1 then
			return to_manchester(pls(pls'left));
		else
			return to_manchester(pls(pls'left))
				& to_pma_data(pls(pls'left+1 to pls'right));
		end if;
	end;

	function to_pma(pls : pls_t) return pma_t is
		constant cd0 : pls_t := to_manchester('0');
		constant cd1 : pls_t := to_manchester('1');
		constant preamble : pls_t := repeat(cd1 & cd0, 28);
		constant sfd : pls_t := repeat(cd1 & cd0, 3) & cd1 & cd1;
		constant data : pls_t := to_pma_data(pls);
		constant idl : pls_t := "1111";
	begin
		assert preamble'length = 7 * 8 * 2;
		assert sfd'length = 1 * 8 * 2;
		assert data'length = pls'length * 2;
		assert idl'length = 4;
		return preamble & sfd & data & idl;
	end;

	function to_pls(mac : mac_t) return pls_t is
	begin
		assert mac'length <= 1500;
		if mac'length = 0 then
			return "";
		-- Could do without the elsif, directly in the else,
		-- but it avoids warnings about the empty range.
		elsif mac'length = 1 then
			return reverse(bit_vector(mac(mac'left)));
		else
			-- LSB first
			return reverse(bit_vector(mac(mac'left)))
				& to_pls(mac(mac'left+1 to mac'right));
		end if;
	end;

	function to_data(word : unsigned) return data_t is
		constant desc : unsigned(word'high downto word'low) := word;
	begin
		assert desc'length mod 8 = 0
			report "to_data: Word length must be multiple of 8.";
		if desc'length = 8 then
			return data_t'(0 => octet_t(desc));
		else
			return to_data(desc(desc'high downto desc'high-7)) &
				to_data(desc(desc'high-8 downto desc'low));
		end if;
	end;

	function to_word(data : data_t) return unsigned is
	begin
		if data'length = 0 then
			return "";
		else
			return unsigned(data(data'left))
				& to_word(data(data'left+1 to data'right));
		end if;
	end;

	function fcs(pls : pls_t) return pls_t is
		variable crc : pls_t(31 downto 0) := (others => '1');
		variable msb : bit;
	begin
		for i in pls'range loop
			msb := crc(31);
			crc := crc(30 downto 0) & '0';
			if (pls(i) xor msb) = '1' then
				crc := crc xor pls_t(crc32_polynomial);
			end if;
		end loop;
		return not crc;
	end;

	function fcs(mac_without_fcs : mac_t) return mac_t is
		constant crc : pls_t(31 downto 0) :=
			fcs(to_pls(mac_without_fcs));
	begin
		-- FCS is sent out MSB first, as opposed to all other data,
		-- so bit-reverse it on byte level.
		return data_t'(
			0 => octet_t(reverse(crc(31 downto 24))),
			1 => octet_t(reverse(crc(23 downto 16))),
			2 => octet_t(reverse(crc(15 downto  8))),
			3 => octet_t(reverse(crc( 7 downto  0))));
	end;

	function to_mac(dst, src : mac_addr_t; data : data_t) return mac_t is
		constant mac_without_fcs : mac_t :=
			to_data(dst) &
			to_data(src) &
			--to_data(to_unsigned(data'length, 16)) &
			--	-- Ethernet Type I
			to_data(x"0800") & -- Ethernet Type II
			data;
	begin
		return mac_without_fcs & fcs(mac_without_fcs);
	end;

	constant data : data_t := to_data(addr);
	constant mac : mac_t := to_mac(addr, addr, data);
	constant pls : pls_t := to_pls(mac);
	constant pma : pma_t := to_pma(pls);

end;


library ieee;
use ieee.std_logic_1164.all;

library work;
use work.rtl_pack.all;
use work.vether.all;

entity vether_tx is
	generic (
		clk_freq_g : natural);
	port (
		rst_i : in std_ulogic := '0';
		clk_i,
		stb_i : in std_ulogic;
		tx_po,
		tx_no,
		run_o : out std_ulogic);
end;

architecture rtl of vether_tx is

	constant addr : mac_addr_t := x"123456789ABC";
	constant data : data_t := repeat(to_data(addr), 8);
	constant mac : mac_t := to_mac(addr, addr, data);
	constant pls : pls_t := to_pls(mac);
	constant pma : pma_t := to_pma(pls);

	signal run : std_ulogic := '1';
	signal idx : integer range pma'range := pma'left;
	signal lp_stb, lp : std_ulogic;

begin

	assert mac'length = 18 + data'length
		report "mac: Length error.";
	assert pls'length = mac'length * 8
		report "pls: Length error.";
	assert pma'length = 128 + pls'length * 2 + 4
		report "pma: Length error.";

	process(rst_i, clk_i)
	begin
		if rst_i = '1' then
			run <= '1';
			idx <= pma'left;
			tx_po <= '0';
			tx_no <= '0';
		elsif rising_edge(clk_i) then
			if run = '1' or stb_i = '1' then
				if idx = pma'right then
					run <= '0';
					idx <= pma'left;
					tx_po <= '0';
					tx_no <= '0';
				else
					run <= '1';
					idx <= idx + 1;
				end if;
				tx_po <= to_stdulogic(pma(idx));
				tx_no <= to_stdulogic(not pma(idx));
			elsif lp = '1' then
				tx_po <= '1';
				tx_no <= '0';
			else
				tx_po <= '0';
				tx_no <= '0';
			end if;
		end if;
	end process;

	lp_stb_gen : entity work.stb_gen
	generic map (
		period_g => clk_freq_g * 16 / 1000)
	port map (
		rst_i => rst_i,
		clk_i => clk_i,
		sync_rst_i => run,
		stb_o => lp_stb);

	lp_gen : entity work.pulse_gen
	generic map (
		duration_g => 2)
	port map (
		rst_i => rst_i,
		clk_i => clk_i,
		stb_i => lp_stb,
		pulse_o => lp);

	run_o <= run;

end;

