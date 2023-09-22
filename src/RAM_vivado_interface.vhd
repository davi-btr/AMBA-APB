-- Equivalent to "src/APB_RAM_wr.vhd" but it does not include RAM device as a component, so this interface
-- can be included in Vivado synthesis without involving devices external to the system (i.e. peripherals)

library IEEE;
  use IEEE.std_logic_1164.all;  -- Required for standard logic and vectors

entity APB_slave_RAM_interface is
	port (
        -- APB interface (protocol-defined signals for APB slave)
        prstn_in        : in std_logic;
        penable_in      : in std_logic;
        psel_in         : in std_logic;
        pwrite_in       : in std_logic;
		paddr_in        : in std_logic_vector(6 downto 0);
		pwdata_in       : in std_logic_vector(15 downto 0);
		prdata_out	    : out std_logic_vector(15 downto 0);
        -- RAM device specific interface (further details can be found in file "src/RAM.vhd")
        ram_en_out      : out std_logic;
        ram_write_out   : out std_logic;
        ram_addr_out	: out std_logic_vector(6 downto 0);
        ram_wdata_out   : out std_logic_vector(7 downto 0);
        ram_rdata_in    : in std_logic_vector(7 downto 0)             
	);
end entity;

architecture rtl of APB_slave_RAM_interface is
    -- Signals corresponding to output ports (better visibility and backwards compatibility with pre-2008 VHDL)
    signal ram_en_s     : std_logic;
    signal ram_write_s  : std_logic;
    signal ram_addr_s   : std_logic_vector(6 downto 0);
    signal ram_wdata_s  : std_logic_vector(7 downto 0);
    signal prdata_s     : std_logic_vector(15 downto 0);
begin
    -- Map APB signals to RAM interface
    ram_en_s <= penable_in and psel_in;                                         -- Actual enable signal (inactive when chip is deselected to reduce conflicts and power dissipation)
    ram_write_s <= pwrite_in;                                                   -- Write signal is transaparent
    ram_addr_s <= paddr_in;                                                     -- Address has no mismatch
    ram_wdata_s <= pwdata_in(7 downto 0);                                       -- Valid part of "pwdata" bus
    prdata_s(15 downto 8) <= (others => '0') when psel_in = '1' and penable_in = '1' and pwrite_in = '0' else (others => 'Z');  -- Most significant byte of result is set to zero while peripheral is sending valid data
    prdata_s(7 downto 0) <= ram_rdata_in when psel_in = '1' else (others => 'Z');  -- Output data bus is controlled by peripheral only when it is selected
    -- Connect output ports to respective signals
    ram_en_out <= ram_en_s;
    ram_write_out <= ram_write_s;
    ram_addr_out <= ram_addr_s;
    ram_wdata_out <= ram_wdata_s;
    prdata_out <= prdata_s;

end architecture;