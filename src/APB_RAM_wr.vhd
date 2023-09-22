-- Wrapper to ensure RAM component is compatible with AMBA Advanced Peripheral Bus protocol
-- and it can be connected to the system (16 bit read and write bus, 7 bit address bus)

library IEEE;
  use IEEE.std_logic_1164.all;
  use IEEE.numeric_std.all;

entity APB_slave_RAM is
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

architecture rtl of APB_slave_RAM is
    component RAM_128x8 is          -- Entity from "src/RAM.vhd"
        port (
            en_in       : in std_logic;
            write_in    : in std_logic;
            addr_in		: in std_logic_vector(6 downto 0);
            data_in     : in std_logic_vector(7 downto 0);
            data_out	: out std_logic_vector(7 downto 0)
        );
    end component;
    -- Auxiliary signals
    signal ram_out_s    : std_logic_vector(7 downto 0); -- RAM output to handle different bus widths and easier to read during test phase
    signal en_s         : std_logic;                    -- RAM input enable signal

begin
    -- Map APB signals to RAM interface
    RAM_I: RAM_128x8 port map(
        en_in => en_s,
        write_in => pwrite_in,
        addr_in => paddr_in,
        data_in => pwdata_in(7 downto 0),
        data_out => ram_out_s
    );

    -- Actual enable signal (inactive when chip is deselected to reduce power dissipation)
    en_s <= penable_in and psel_in;
    -- Most significant byte of result is set to zero while peripheral is sending valid data
    prdata_out(15 downto 8) <= (others => '0') when psel_in = '1' and penable_in = '1' and pwrite_in = '0' else (others => 'Z');
    -- Output data bus is controlled by peripheral only when it is selected
    prdata_out(7 downto 0) <= ram_out_s when psel_in = '1' else (others => 'Z');


end architecture;