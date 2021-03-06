library ieee;
use ieee.std_logic_1164.all;

--! Higher order bits transfered first.
entity gearbox is
	generic (
		a_width_g : positive;
		b_width_g : positive;
		fifo_depth_order_g : positive);
	port (
		a_reset_i : in std_ulogic := '0';
		a_clock_i : in std_ulogic;
		a_data_i : in std_ulogic_vector(a_width_g-1 downto 0);

		b_reset_i : in std_ulogic := '0';
		b_clock_i : in std_ulogic;
		b_data_o : out std_ulogic_vector(b_width_g-1 downto 0));
end;

library work;
use work.rtl_pack.all;

architecture rtl_fast of gearbox is

	constant check_a_wider_b : boolean := check(a_width_g > b_width_g, "a>b");

	signal b_fifo_read : std_ulogic;
	signal b_fifo_prefill_reached : std_ulogic;
	signal b_fifo_data : std_ulogic_vector(a_width_g-1 downto 0);

	signal b_buffer : std_ulogic_vector(a_width_g+b_width_g-2 downto 0);
	signal b_index : natural range 0 to a_width_g-1 := a_width_g - b_width_g;

begin

	fifo : entity work.fifo
	generic map (
		depth_order_g => fifo_depth_order_g,
		data_width_g => a_width_g,
		prefill_g => 2**(fifo_depth_order_g-1) - 2 * b_width_g / a_width_g)
	port map (
		a_reset_i => a_reset_i,
		a_clock_i => a_clock_i,
		a_data_i => a_data_i,
		b_reset_i => b_reset_i,
		b_clock_i => b_clock_i,
		b_read_i => b_fifo_read,
		b_prefill_reached_o => b_fifo_prefill_reached,
		b_data_o => b_fifo_data);

	b_fifo_read <= to_stdulogic(b_index < b_width_g) and b_fifo_prefill_reached;

	b_sync : process(b_reset_i, b_clock_i)
	begin
		if b_reset_i = '1' then
			b_buffer <= (others => '-');
			b_index <= a_width_g - b_width_g;
			b_data_o <= (others => '0');
		elsif rising_edge(b_clock_i) then
			b_data_o <= b_buffer(b_index+b_width_g-1 downto b_index);
			if b_fifo_read = '1' then
				b_buffer(a_width_g-1 downto 0) <= b_fifo_data;
				b_buffer(a_width_g+b_width_g-2 downto a_width_g) <= b_buffer(b_width_g-2 downto 0);
			end if;
			b_index <= (b_index - b_width_g) mod a_width_g;
		end if;
	end process;

end;

library work;
use work.rtl_pack.all;

architecture rtl_slow of gearbox is

	constant check_b_wider_a : boolean := check(b_width_g > a_width_g, "b>a");

	signal a_fifo_data : std_ulogic_vector(b_width_g-1 downto 0);
	signal b_fifo_prefill_reached : std_ulogic;

	signal a_fifo_write : std_ulogic := '0';
	signal a_buffer : std_ulogic_vector(a_width_g+b_width_g-2 downto 0);
	signal a_index : natural range 0 to b_width_g-1 := b_width_g - 1;

begin

	fifo : entity work.fifo
	generic map (
		depth_order_g => fifo_depth_order_g,
		data_width_g => b_width_g,
		prefill_g => 2**(fifo_depth_order_g-1) - 2 * a_width_g / b_width_g)
	port map (
		a_reset_i => a_reset_i,
		a_clock_i => a_clock_i,
		a_write_i => a_fifo_write,
		a_data_i => a_fifo_data,
		b_reset_i => b_reset_i,
		b_clock_i => b_clock_i,
		b_read_i => b_fifo_prefill_reached,
		b_prefill_reached_o => b_fifo_prefill_reached,
		b_data_o => b_data_o);

	a_fifo_data <= a_buffer(a_width_g+b_width_g-2 downto a_width_g-1);

	a_sync : process(a_reset_i, a_clock_i)
	begin
		if a_reset_i = '1' then
			a_fifo_write <= '0';
			a_buffer <= (others => '-');
			a_index <= b_width_g - 1;
		elsif rising_edge(a_clock_i) then
			if a_fifo_write = '1' then
				a_buffer <= (others => '-');
				if a_index /= b_width_g - 1 then
					a_buffer(a_width_g+b_width_g-2 downto a_width_g+a_index)
						<= a_buffer(a_width_g-2 downto a_width_g+a_index-b_width_g);
				end if;
			end if;
			a_fifo_write <= to_stdulogic(a_index < a_width_g);
			a_buffer(a_index+a_width_g-1 downto a_index) <= a_data_i;
			a_index <= (a_index - a_width_g) mod b_width_g;
		end if;
	end process;

end;

library work;
use work.rtl_pack.all;

architecture rtl of gearbox is

	constant check_a_nequal_b : boolean := check(a_width_g /= b_width_g, "a/=b");

begin

	gen_fast : if a_width_g > b_width_g generate
		gearbox_fast : entity work.gearbox(rtl_fast)
		generic map (
			a_width_g => a_width_g,
			b_width_g => b_width_g,
			fifo_depth_order_g => fifo_depth_order_g)
		port map (
			a_reset_i => a_reset_i,
			a_clock_i => a_clock_i,
			a_data_i => a_data_i,
			b_reset_i => b_reset_i,
			b_clock_i => b_clock_i,
			b_data_o => b_data_o);
	end generate;

	gen_slow : if b_width_g > a_width_g generate
		gearbox_slow : entity work.gearbox(rtl_slow)
		generic map (
			a_width_g => a_width_g,
			b_width_g => b_width_g,
			fifo_depth_order_g => fifo_depth_order_g)
		port map (
			a_reset_i => a_reset_i,
			a_clock_i => a_clock_i,
			a_data_i => a_data_i,
			b_reset_i => b_reset_i,
			b_clock_i => b_clock_i,
			b_data_o => b_data_o);
	end generate;

end;