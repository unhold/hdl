library ieee;
use ieee.std_logic_1164.all;


--- DDR deserializer.
entity ddr_des is
	generic (
		data_width_g : positive);
	port (
		clk_i,
		reset_ni : in std_ulogic;
		data_o : out std_ulogic_vector(data_width_g-1 downto 0);
		valid_stb_o : out std_ulogic;
		ddr_data_i,
		bit_clk_i,
		frame_clk_i : in std_ulogic);
end;


architecture rtl of ddr_des is

	signal data_rising : std_ulogic;
	signal shift_reg : std_ulogic_vector(data_width_g-1 downto 0);

	-- clk_i domain: 2 sync FFs, 1 for edge detect
	signal prev_frame_clk : std_ulogic_vector(2 downto 0);

begin

	process(bit_clk_i)
	begin
		if rising_edge(bit_clk_i) then
			data_rising <= ddr_data_i;
		end if;
	end process;

	process(bit_clk_i)
	begin
		if falling_edge(bit_clk_i) then
			shift_reg <= ddr_data_i & data_rising & shift_reg(shift_reg'left downto 2);
		end if;
	end process;

	process(frame_clk_i)
	begin
		if falling_edge(frame_clk_i) then
			data_o <= shift_reg;
		end if;
	end process;

	-- valid_stb_o: detect falling edge on sync'ed frame_clk_i
	process(clk_i, reset_ni)
	begin
		if reset_ni = '0' then
			prev_frame_clk <= (others => '0');
		elsif rising_edge(clk_i) then
			prev_frame_clk <= frame_clk_i & prev_frame_clk(prev_frame_clk'left downto 1);
		end if;
	end process;
	valid_stb_o <= prev_frame_clk(0) and not prev_frame_clk(1);

end;
