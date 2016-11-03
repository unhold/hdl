library ieee;
use ieee.std_logic_1164.all;


--- DDR serializer.
entity ddr_ser is
	generic (
		data_width_g : positive;
		delay_g : time);
	port (
		clk_i,
		reset_ni : in std_ulogic;
		data_i : in std_ulogic_vector(data_width_g-1 downto 0);
		start_stb_i : in std_ulogic;
		busy_o : out std_ulogic;
		ddr_data_o,
		bit_clk_o,
		frame_clk_o : out std_ulogic);
end;


architecture bhv of ddr_ser is

	type state_t is record
		shift_reg : std_ulogic_vector(data_width_g-1 downto 0);
		count_down : integer range 0 to data_width_g;
		busy,
			frame_clk : std_ulogic;
	end record;

	constant state_reset_c : state_t := (
		shift_reg => (others => '0'),
		count_down => 0,
		busy => '0',
		frame_clk => '0');

	signal s, n : state_t;
	signal data_even,
		data_odd,
		data_mux,
		clk_delay,
		clk_trans : std_ulogic;

begin

	sync : process(clk_i, reset_ni)
	begin
		if reset_ni = '0' then
			s <= state_reset_c;
		elsif rising_edge(clk_i) then
			s <= n;
		end if;
	end process;

	comb : process(data_i, start_stb_i, s)
	begin
		n <= s;
		if s.count_down /= 0 then
			n.shift_reg <= "00" & s.shift_reg(s.shift_reg'left downto 2);
			n.count_down <= s.count_down - 2;
		end if;
		if s.count_down = data_width_g/2 + 2 then
			n.frame_clk <= '1';
		end if;
		if s.count_down <= 2 then
			n.busy <= '0';
			n.frame_clk <= '0';
		end if;
		if start_stb_i = '1' then
			n.shift_reg <= data_i;
			n.count_down <= data_width_g;
			n.busy <= '1';
		end if;
		busy_o <= s.busy;
	end process;

	odd_ff : process(clk_i, reset_ni)
	begin
		if reset_ni = '0' then
			data_odd <= '0';
		elsif rising_edge(clk_i) then
			if s.busy = '1' then
				data_odd <= s.shift_reg(1);
			else
				data_odd <= '0';
			end if;
		end if;
	end process;

	even_ff : process(clk_i, reset_ni)
	begin
		if reset_ni = '0' then
			data_even <= '0';
		elsif falling_edge(clk_i) then
			if s.busy = '1' then
				data_even <= s.shift_reg(0);
			else
				data_even <= '0';
			end if;
		end if;
	end process;

	mux : with clk_i select data_mux <=
		s.shift_reg(1) when '0',
		s.shift_reg(0) when '1',
		'X'  when others;

	-- replace with delay element(s) or tuned delay line
	clk_delay <= clk_i after delay_g;

	clk_trans <= clk_i xor clk_delay;

	bit_clk_o <= not clk_i and s.busy;

	latch_with_reset : process(reset_ni, clk_trans, data_mux, s)
	begin
		if reset_ni = '0' then
			ddr_data_o <= '0';
			frame_clk_o <= '0';
		elsif clk_trans = '0' then
			ddr_data_o <= data_mux;
			frame_clk_o <= s.frame_clk;
		end if;
	end process;

end;
