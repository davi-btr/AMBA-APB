-- Equivalent to "src/APB_ROM_wr.vhd" but it does not include ROM device as a component, so this interface
-- can be included in Vivado synthesis without involving devices external to the system (i.e. peripherals)

library IEEE;
  use IEEE.std_logic_1164.all;  -- Required for standard logic and vectors

entity APB_slave_ROM_interface is
	port (
        -- APB interface (protocol-defined signals for APB slave)
        prstn_in        : in std_logic;
        penable_in      : in std_logic;
        psel_in         : in std_logic;
        pwrite_in       : in std_logic;
		paddr_in        : in std_logic_vector(6 downto 0);
		pwdata_in       : in std_logic_vector(15 downto 0);
		prdata_out	    : out std_logic_vector(15 downto 0);
        -- ROM device specific interface (further details can be found in file "src/ROM.vhd")
        rom_en_out      : out std_logic;
        rom_addr_out    : out std_logic_vector(5 downto 0);
        rom_data_in     : in std_logic_vector(15 downto 0)                
	);
end entity;

architecture rtl of APB_slave_ROM_interface is
    -- Signals corresponding to output ports (better visibility and backwards compatibility with pre-2008 VHDL)
    signal rom_en_s     : std_logic;
    signal rom_addr_s   : std_logic_vector(5 downto 0);
    signal prdata_s     : std_logic_vector(15 downto 0);
begin
    -- Map APB signals to ROM interface
    rom_en_s <= penable_in and psel_in and not pwrite_in;               -- Actual enable signal (inactive when chip is deselected to reduce conflicts and power dissipation)
    rom_addr_s <= paddr_in(5 downto 0);                                 -- Valid part of "paddr" bus
    prdata_s <= rom_data_in when psel_in = '1' else (others => 'Z');    -- Connect output to ROM, keeping in mind the APB bus is shared among peripherals
    -- Connect output ports to respective signals
    rom_en_out <= rom_en_s;
    rom_addr_out <= rom_addr_s;
    prdata_out <= prdata_s;

end architecture;