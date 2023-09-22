-- Asynchronous 64x16 ROM with enable signal, automatically generated with pyhton script "scripts/ROM_generation.py" (code comments were added manually)

library IEEE;
  use IEEE.std_logic_1164.all;	-- Required for standard logic and vectors
  use IEEE.numeric_std.all;		-- Required for unsigned and integer conversion functions

entity ROM_64x16 is
	port (
		en_in		: in std_logic;						-- Chip select (enable) signal, to avoid conflicts on outer bus
		addr_in		: in  std_logic_vector(5 downto 0);	-- Address of location to be read
		data_out	: out std_logic_vector(15 downto 0)	-- Data read from memory
	);
end entity;

architecture rtl of ROM_64x16 is

	-- Initialisation with random values whose last 6 bits contain address of cell (easier to test)
	type ROM_t is array (natural range 0 to 63) of integer;		-- Content of the ROM
	constant ROM_c	: ROM_t := (
		5824, 52289, 64002, 52355, 62916, 62981, 58694, 47559, 
		22600, 54089, 11274, 2251, 51212, 4237, 51662, 2191, 
		61328, 62033, 59474, 31699, 38036, 49493, 9686, 62295, 
		32536, 32473, 38426, 13147, 38748, 10909, 41630, 63967, 
		60512, 17185, 49506, 15971, 36900, 40933, 58150, 31911, 
		41128, 13225, 28330, 11499, 9132, 14253, 2158, 46191, 
		21360, 52081, 25714, 60915, 51828, 39093, 4470, 46007, 
		45368, 37369, 49274, 38651, 44028, 60797, 53822, 42047
		);
	-- Signal corresponding to output port, for better readability of code and simulation waveform, and also pre-2008 VHDL compatible
	signal data_s	: std_logic_vector(15 downto 0);

begin

	-- Read from address when requested
	data_s <= std_logic_vector(to_unsigned(ROM_c(to_integer(unsigned(addr_in))), 16)) when en_in = '1' else (others => 'Z');
	-- Output port receives its corresponding output signal
	data_out <= data_s;

end architecture;
