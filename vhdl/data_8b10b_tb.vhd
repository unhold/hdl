library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.tb_pack.all;
use work.codec_8b10b_pack.all;

entity data_8b10b_tb is
end;

architecture tb of data_8b10b_tb is
begin

	process is
		variable b8_i : b8_t;
		variable b10_o : b10_t;
		variable rd_o : rd_t;
	begin
		for i in 0 to 255 loop
			b8_i := b8_t(to_unsigned(i, 8));
			data_8b10b(b8_i, minus1, b10_o, rd_o);
			report "data_8b10b(0x" & to_hstring(b8_i) & ", minus1) => 0x" &
				to_hstring(b10_o) & ", " & rd_t'image(rd_o);
		end loop;
		wait;
	end process;

end;
