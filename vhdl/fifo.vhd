library ieee;
use ieee.std_logic_1164.all;

entity fifo is
	generic (
		address_width_g : positive;
		data_width_g : positive);
	port (
		a_reset_i : in std_ulogic;
		a_clock_i : in std_ulogic;
		a_ready_o : out std_ulogic;
		a_valid_i : in std_ulogic;
		a_data_i : in std_ulogic_vector(data_width_g-1 downto 0);
		b_reset_i : in std_ulogic;
		b_clock_i : in std_ulogic;
		b_ready_i : in std_ulogic;
		b_valid_o : out std_ulogic;
		b_data_o : out std_ulogic_vector(data_width_g-1 downto 0));
end;

library ieee;
use ieee.numeric_std.all;

library work;
use work.rtl_pack.all;

architecture bhv of fifo is

	subtype address_t is unsigned(address_width_g downto 0);
	signal a_write_address, b_read_address : address_t := (others => '0');
	signal empty, full, read : std_ulogic;

begin

	empty <= to_stdulogic(a_write_address = b_read_address);
	full <= to_stdulogic(a_write_address = not b_read_address(address_width_g) & b_read_address(address_width_g-1 downto 0));

	a_ready_o <= not full;
	b_valid_o <= not empty;

	dual_port_ram : entity work.dual_port_ram
		generic map (
			address_width_g => address_width_g,
			data_width_g => data_width_g)
		port map (
			a_clock_i => a_clock_i,
			a_address_i => std_ulogic_vector(a_write_address(address_width_g-1 downto 0)),
			a_write_i => a_valid_i,
			a_data_i => a_data_i,
			b_clock_i => b_clock_i,
			b_address_i => std_ulogic_vector(b_read_address(address_width_g-1 downto 0)),
			b_read_i => '1',
			b_data_o => b_data_o);

	a_write : process(a_reset_i, a_clock_i)
	begin
		if a_reset_i = '1' then
			a_write_address <= (others => '0');
		elsif rising_edge(a_clock_i) then
			if (a_valid_i and not full) = '1' then
				a_write_address <= a_write_address + 1;
			end if;
		end if;
	end process;

	b_read : process(b_reset_i, b_clock_i)
	begin
		if b_reset_i = '1' then
			b_read_address <= (others => '0');
		elsif rising_edge(b_clock_i) then
			if (b_ready_i and not empty) = '1' then
				b_read_address <= b_read_address + 1;
			end if;
		end if;
	end process;

end;

library work;
use work.rtl_pack.all;
use work.greycode.all;

architecture rtl of fifo is

	subtype address_t is greycode_t(address_width_g downto 0);
	signal a_write_address, b_read_address, b_write_address, a_read_address : address_t := (others => '0');
	signal a_ready, b_valid : std_ulogic;

begin

	dual_port_ram : entity work.dual_port_ram
		generic map (
			address_width_g => address_width_g,
			data_width_g => data_width_g)
		port map (
			a_clock_i => a_clock_i,
			a_address_i => a_write_address(address_width_g-1 downto 0),
			a_write_i => a_valid_i,
			a_data_i => a_data_i,
			b_clock_i => b_clock_i,
			b_address_i => b_read_address(address_width_g-1 downto 0),
			b_read_i => '1',
			b_data_o => b_data_o);

	a_write : process(a_reset_i, a_clock_i)
	begin
		if a_reset_i = '1' then
			a_write_address <= (others => '0');
		elsif rising_edge(a_clock_i) then
			a_ready <= to_stdulogic(increment(a_write_address) /= a_read_address);
			if (a_valid_i and a_ready) = '1' then
				a_write_address <= increment(a_write_address);
			end if;
		end if;
	end process;

	a_ready_o <= a_ready;

	sync_write_address_a_b : entity work.sync
		generic map (
			width_g => address_width_g,
			reset_value_g => '0')
		port map (
			reset_i => b_reset_i,
			clock_i => b_clock_i,
			data_i => a_write_address,
			data_o => b_write_address);

	b_read : process(b_reset_i, b_clock_i)
	begin
		if b_reset_i = '1' then
			b_read_address <= (others => '0');
		elsif rising_edge(b_clock_i) then
			b_valid <= to_stdulogic(increment(b_read_address) /= b_write_address);
			if (b_ready_i and b_valid) = '1' then
				b_read_address <= increment(b_read_address);
			end if;
		end if;
	end process;

	b_valid_o <= b_valid;

	sync_read_address_b_a : entity work.sync
		generic map (
			width_g => address_width_g,
			reset_value_g => '0')
		port map (
			reset_i => a_reset_i,
			clock_i => a_clock_i,
			data_i => b_read_address,
			data_o => a_read_address);

end;