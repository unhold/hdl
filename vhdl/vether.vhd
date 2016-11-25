library ieee;
use ieee.numeric_bit.all;


-- Ethernet 10BASE-T
-- IEEE802.3-2008 clauses 3, 7
package vether is

	subtype octet_t is bit_vector(7 downto 0);
	type data_t is array(natural range <>) of octet_t;
	subtype mac_addr_t is unsigned(47 downto 0);

	-- word/data conversion, high byte first:
	function to_data(word : unsigned) return data_t;
	function to_word(data : data_t) return unsigned;

	-- frame types of the sublayers:
	subtype mac_t is data_t;     -- Media Access Control frame
	subtype pls_t is bit_vector; -- Physical Layer Symbol frame
	subtype pma_t is bit_vector; -- Physical Media Attachment frame

	-- encapsulate data into MAC frame, calculate FCS.
	function to_mac(dst, src : mac_addr_t; data : data_t) return mac_t;

	-- covert to PLS frame: serialize, add preamble, SFD and ETD.
	function to_pls(mac : data_t) return pls_t;

	-- convert to PMA frame: Manchester-encode.
	-- can also be done with clock-XOR.
	function to_pma(pls : pls_t) return pma_t;

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

	function repeat(data : bit_vector; count : natural)
		return bit_vector is
	begin
		if count = 0 then
			return "";
		else
			return data & repeat(data, count-1);
		end if;
	end;

	function to_pma(pls : pls_t) return pma_t is
	begin
		if pls'length = 0 then
			return "";
		else
			return to_manchester(pls(pls'left))
				& to_pma(pls(pls'left+1 to pls'right));
		end if;
	end function;

	function to_pls_data(mac : mac_t) return pls_t is
	begin
		assert mac'length <= 1500;
		if mac'length = 0 then
			return "";
		else
			-- LSB first
			return reverse(mac(mac'left))
				& to_pls_data(mac(mac'left+1 to mac'right));
		end if;
	end;

	function to_pls(mac : mac_t) return pls_t is
		constant pls_preamble_and_sfd : pls_t := repeat("10", 62/2) & "11";
		constant pls_data : pls_t := to_pls_data(mac);
	begin
		assert pls_preamble_and_sfd'length = 64
			report "to_pls: pls_preamble_and_sfd has wrong length";
		assert pls_data'length = mac'length * 8;
			report "to_pls: pls_data has wrong length";
		return pls_preamble_and_sfd & pls_data;
	end;

	function to_data(word : unsigned) return data_t is
	begin
		if word'length = 8 then
			return data_t'(0 => octet_t(word));
		else
			return to_data(word(word'high downto word'high-7)) &
				to_data(word(word'high-8 downto word'low));
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

	function to_mac_without_fcs(dst, src : mac_addr_t; data : data_t)
		return mac_t is
	begin
		return to_data(dst) & to_data(src)
			& to_data(to_unsigned(data'length, 16)) & data;
	end;

	function fcs(data : data_t) return mac_t is
	begin
		report "fcs: not implemented, returns 0";
		return to_data(to_unsigned(0, 32));
	end;

	function to_mac(dst, src : mac_addr_t; data : data_t) return mac_t is
		constant mac_without_fcs : mac_t := to_mac_without_fcs(dst, src, data);
	begin
		assert mac_without_fcs'length = data'length + 14
			report "to_mac: length check error";
		return mac_without_fcs & fcs(mac_without_fcs);
	end;

end;


use work.vether.all;


entity vether_tx is
	port (
		rst_ni : in bit := '1';
		clk_i : in bit;
		stb_i : in bit;
		tx_po,
		tx_no,
		run_o : out bit);
end;


architecture rtl of vether_tx is
	constant addr : mac_addr_t := x"010203040506";
	constant data : data_t := to_data(addr);
	constant mac : mac_t := to_mac(addr, addr, data);
	constant pls : pls_t := to_pls(mac);
	constant pma : pma_t := to_pma(pls);
	signal run : bit := '1';
	signal idx : integer range pma'range := pma'left;
begin
	assert mac'length = data'length + 18 report "mac: length error";
	assert pls'length = mac'length * 8 + 64 report "pls: length error";
	assert pma'length = pls'length * 2 report "pma: length error";
	process(rst_ni, clk_i)
	begin
		if rst_ni = '0' then
			run <= '1';
			idx <= pma'left;
			tx_po <= '0';
			tx_no <= '0';
		elsif rising_edge(clk_i) then
			if run = '1' then
				if idx = pma'right then
					run <= '0';
					idx <= pma'left;
					tx_po <= '0';
					tx_no <= '0';
				else
					idx <= idx + 1;
				end if;
				tx_po <= pma(idx);
				tx_no <= not pma(idx);
			elsif stb_i = '1' then
				run <= '1';
			end if;
		end if;
	end process;
	run_o <= run;
end;
