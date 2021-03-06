library ieee;
use ieee.std_logic_1164.all;

library work;
use work.rtl_pack.all;

entity fifo is
	generic (
		depth_order_g : positive;
		data_width_g : positive;
		prefill_g : natural := 0);
	port (
		a_reset_i : in std_ulogic := '0';
		a_clock_i : in std_ulogic;
		a_full_o : out std_ulogic;
		a_write_i : in std_ulogic := '1';
		a_data_i : in std_ulogic_vector(data_width_g-1 downto 0);

		b_reset_i : in std_ulogic := '0';
		b_clock_i : in std_ulogic;
		b_read_i : in std_ulogic := '1';
		b_empty_o : out std_ulogic;
		b_prefill_reached_o : out std_ulogic;
		b_data_o : out std_ulogic_vector(data_width_g-1 downto 0));

	constant check_prefill : boolean := check(prefill_g < 2**depth_order_g);

end;

library ieee;
use ieee.numeric_std.all;

library work;
use work.greycode_pack.all;

architecture rtl of fifo is

	constant sync_stages_c : positive := 2;

	-- Compensate for sync and pipeline delay.
	-- This assumes that fifo will be written continuously, once writing started.
	constant b_prefill_c : natural :=  maximum(prefill_g - sync_stages_c - 1, 1);

	subtype address_t is greycode_t(depth_order_g-1 downto 0);

	signal a_write_address, b_read_address : address_t := (others => '0');
	signal b_prefill_reached : std_ulogic := '0';

	signal b_write_address, a_read_address : address_t;
	signal a_full, b_empty : std_ulogic;
	signal b_next_read_address : address_t;
	signal b_next_prefill_reached : std_ulogic;

	signal async_fill : integer range 0 to 2**depth_order_g-1;

begin

	dual_port_ram : entity work.dual_port_ram
		generic map (
			address_width_g => depth_order_g,
			data_width_g => data_width_g)
		port map (
			a_clock_i => a_clock_i,
			a_address_i => a_write_address,
			a_write_i => a_write_i,
			a_data_i => a_data_i,
			b_clock_i => b_clock_i,
			b_address_i => b_next_read_address,
			b_read_i => '1',
			b_data_o => b_data_o);

	a_full <= to_stdulogic(a_write_address + 1 = a_read_address);
	a_full_o <= a_full;

	a_write : process(a_reset_i, a_clock_i)
	begin
		if a_reset_i = '1' then
			a_write_address <= (others => '0');
		elsif rising_edge(a_clock_i) then
			assert (a_write_i and a_full) = '0' report "fifo: write full fifo";
			if (a_write_i and not a_full) = '1' then
				a_write_address <= a_write_address + 1;
			end if;
		end if;
	end process;

	sync_write_address_a_b : entity work.sync
		generic map (
			width_g => depth_order_g,
			stages_g => sync_stages_c,
			reset_value_g => '0')
		port map (
			reset_i => b_reset_i,
			clock_i => b_clock_i,
			data_i => a_write_address,
			data_o => b_write_address);

	b_empty <= to_stdulogic(b_read_address = b_write_address) or not b_prefill_reached;
	b_next_read_address <= b_read_address + 1 when (b_read_i and not b_empty) = '1' else b_read_address;
	b_next_prefill_reached <= b_prefill_reached or to_stdulogic(to_integer(unsigned(to_binary(b_write_address))) >= b_prefill_c);
		-- Cannot only use equal, because values may be lost in the sync.
	b_empty_o <= b_empty;
	b_prefill_reached_o <= b_prefill_reached;

	b_read_sync : process(b_reset_i, b_clock_i)
	begin
		if b_reset_i = '1' then
			b_read_address <= (others => '0');
			b_prefill_reached <= to_stdulogic(prefill_g = 0);
		elsif rising_edge(b_clock_i) then
			b_read_address <= b_next_read_address;
			b_prefill_reached <= b_next_prefill_reached;
		end if;
	end process;

	sync_read_address_b_a : entity work.sync
		generic map (
			width_g => depth_order_g,
			reset_value_g => '0')
		port map (
			reset_i => a_reset_i,
			clock_i => a_clock_i,
			data_i => b_read_address,
			data_o => a_read_address);

	async_fill <= (to_integer(unsigned(to_binary(a_write_address))) - to_integer(unsigned(to_binary(b_read_address)))) mod 2**depth_order_g;

end;