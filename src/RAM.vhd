-- Asynchronous 128x8 RAM with enable. There is no implementation of bidirectional data bus because it is not required

library IEEE;
  use IEEE.std_logic_1164.all;  -- Required for standard logic and vectors
  use IEEE.numeric_std.all;     -- Required for unsigned and integer conversion functions

entity RAM_128x8 is
	port (
        en_in       : in std_logic;                     -- Enable signal
        write_in    : in std_logic;                     -- Access mode flag (read or write)
		addr_in		: in std_logic_vector(6 downto 0);  -- Address of location to be read
		data_in     : in std_logic_vector(7 downto 0);  -- Data to write to memory
		data_out	: out std_logic_vector(7 downto 0)  -- Data read from memory
	);
end entity;

architecture rtl of RAM_128x8 is
    -- Representation of interal architecture of RAM (array of cells)
    subtype word_t is std_logic_vector(7 downto 0);
	type RAM_128x8_t is array (natural range 0 to 127) of word_t;
	signal cells_s      : RAM_128x8_t := (others => (others => '0'));       -- Actual content of RAM, initialised to zeroes
    signal addr_store_s : std_logic_vector(6 downto 0) := (others => '0');  -- Storing address throughout operations (register is manually assigned default value for simulation but is not included in synthesis, or it may cause issues)
	-- Signal corresponding to output port, for better readability of code and simulation waveform, and also pre-2008 VHDL compatible
	signal data_s       : std_logic_vector(7 downto 0);

begin
    -- Access to memory: performs read or write operation at rising edge of enable
    ACCESS_P: process(en_in)
    begin
        if rising_edge(en_in) then 
            if write_in = '1' then              -- Write access
                cells_s(to_integer(unsigned(addr_in))) <= data_in;  -- Stores new data in target cell
            end if;
            addr_store_s <= addr_in;
        end if;
    end process;

    -- Updates output bus with data while reading
    data_s <= cells_s(to_integer(unsigned(addr_store_s))) when write_in = '0' and en_in = '1' else (others => 'Z');
    -- Output port receives its corresponding output signal
    data_out <= data_s;

end architecture;
