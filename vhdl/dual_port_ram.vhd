library ieee;
use ieee.std_logic_1164.all;

-- True dual-port, dual-clock RAM. Inference of Intel and Xilinx RAM blocks.
-- Can also be used as single-port, single-clock, with a read-only and a write-only port.
entity dual_port_ram is
	generic (
		address_width_g : positive;
		data_width_g : positive);
	port (
		a_clock_i : in std_ulogic;
		a_address_i : in std_ulogic_vector(address_width_g-1 downto 0);
		a_write_i : in std_ulogic;
		a_data_i : in std_ulogic_vector(data_width_g-1 downto 0);
		a_read_i : in std_ulogic := '0';
		a_data_o : out std_ulogic_vector(data_width_g-1 downto 0);

		b_clock_i : in std_ulogic := '0';
		b_address_i : in std_ulogic_vector(address_width_g-1 downto 0) := (others => 'X');
		b_write_i : in std_ulogic := '0';
		b_data_i : in std_ulogic_vector(data_width_g-1 downto 0) := (others => 'X');
		b_read_i : in std_ulogic := '0';
		b_data_o : out std_ulogic_vector(data_width_g-1 downto 0));
end;

library ieee;
use ieee.numeric_std.all;

architecture rtl of dual_port_ram is

	function to_index(slv : std_ulogic_vector) return natural is
	begin
		return to_integer(unsigned(slv));
	end;

	subtype data_t is std_ulogic_vector(data_width_g-1 downto 0);
	type ram_t is array(0 to 2**address_width_g-1) of data_t;
	shared variable ram_v : ram_t;

begin

	a_port : process(a_clock_i)
	begin
		if rising_edge(a_clock_i) then
			if a_read_i = '1' and not is_x(a_address_i) then
				a_data_o <= ram_v(to_index(a_address_i));
			else
				a_data_o <= (others => 'X');
			end if;
			if a_write_i = '1' then
				if not is_x(a_address_i) then
					ram_v(to_index(a_address_i)) := a_data_i;
				else
					ram_v := (others => (others => 'X'));
				end if;
			end if;
		end if;
	end process;

	b_port : process(b_clock_i)
	begin
		if rising_edge(b_clock_i) then
			if b_read_i = '1' and not is_x(b_address_i) then
				b_data_o <= ram_v(to_index(b_address_i));
			else
				b_data_o <= (others => 'X');
			end if;
			if b_write_i = '1' then
				if not is_x(b_address_i) then
					ram_v(to_index(b_address_i)) := b_data_i;
				else
					ram_v := (others => (others => 'X'));
				end if;
			end if;
		end if;
	end process;

	write_contention : block is

		signal a_write_r, b_write_r : std_ulogic;

	begin

		a_write_contention : process(a_clock_i)
		begin
			if rising_edge(a_clock_i) then
				a_write_r <= a_write_i;
				if (a_write_i = '1' and a_address_i = b_address_i and
						(b_write_r = '1' or
							(rising_edge(b_clock_i) and b_write_i = '1'))) then
					report "dual_port_ram: write contention" severity warning;
					ram_v(to_index(a_address_i)) := (others => 'X');
				end if;
			end if;
		end process;

		b_write_contention : process(b_clock_i)
		begin
			if rising_edge(b_clock_i) then
				b_write_r <= b_write_i;
				if b_write_i = '1' and a_write_r = '1' and b_address_i = a_address_i then
						report "dual_port_ram: write contention" severity warning;
						ram_v(to_index(b_address_i)) := (others => 'X');
				end if;
			end if;
		end process;

	end block;

end;