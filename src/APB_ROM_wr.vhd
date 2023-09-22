-- Wrapper to ensure ROM component is compatible with AMBA Advanced Peripheral Bus protocol
-- and it can be connected to the system (16 bit read and write bus, 7 bit address bus)

library IEEE;
  use IEEE.std_logic_1164.all;  -- Required for standard logic and vectors

entity APB_slave_ROM is
	port (
        prstn_in    : in std_logic;                     -- Reset signal, active LOW
        penable_in  : in std_logic;                     -- Enable signal
        psel_in     : in std_logic;                     -- Chip select signal, to avoid conflicts and dynamic power consumption
        pwrite_in   : in std_logic;                     -- Differentiates read and write access mode
		paddr_in    : in std_logic_vector(6 downto 0);  -- Address of location to be read
		pwdata_in   : in std_logic_vector(15 downto 0); -- Data to write to memory
		prdata_out	: out std_logic_vector(15 downto 0) -- Data read from memory
	);
end entity;

architecture rtl of APB_slave_ROM is
    component ROM_64x16 is          -- Entity from "src/ROM.vhd"
        port (
            en_in       : in std_logic;
            addr_in		: in std_logic_vector(5 downto 0);
            data_out	: out std_logic_vector(15 downto 0)
        );
    end component;
    -- Auxiliary signals
    signal rom_out_s    : std_logic_vector(15 downto 0);    -- ROM output data
    signal en_s         : std_logic;                        -- ROM input enable signal
begin
    -- Map APB signals to ROM interface
    ROM_I: ROM_64x16 port map(
        en_in => en_s,
        addr_in => paddr_in(5 downto 0),                    -- Valid part of "paddr" bus
        data_out => rom_out_s
    );

    -- Actual enable signal (inactive when chip is deselected to reduce power dissipation)
    en_s <= penable_in and psel_in and not pwrite_in;
    -- Connect output to ROM, keeping in mind the APB bus is shared among peripherals
    prdata_out <= rom_out_s when psel_in = '1' else (others => 'Z');

end architecture;