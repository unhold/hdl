library ieee;
use ieee.std_logic_1164.all;

entity sync is
	generic (
		width_g : positive := 1;
		stages_g : positive := 2;
		reset_value_g : std_ulogic := '-');
	port (
		reset_i : in std_ulogic;
		clock_i : in std_ulogic;
		data_i : in std_ulogic_vector(width_g-1 downto 0);
		data_o : out std_ulogic_vector(width_g-1 downto 0));
end;

architecture rtl of sync is
	type sync_t is array(stages_g-2 downto 0) of std_ulogic_vector(width_g-1 downto 0);
	sync_r : sync_t := (others => (others => reset_value_g));
begin
	process(reset_i, clock_i)
	begin
		if reset_i = '1' then
			sync_r <= (others => (others => reset_value_g));
		elsif rising_edge(clock_i) then
			sync_r <= sync_r(sync_r'high-1 downto sync_r'low) & data_i;
			data_o <= sync_r(sync_r'high);
		end if;
	end process;
end;