-- Wrapper to make sure every combinational block is included inside a register-logic-register path (by adding fictitious
-- registers to input/output ports when needed). This makes sure every potentially critical path is included in timing
-- constraints analysis

    library IEEE;
    use IEEE.std_logic_1164.all;    -- Required for standard logic and vectors

entity APB_bus_wrap is              -- Generics and ports match those of wrapped entity, found in file "src/APB_bridge.vhd"
    generic (
        DATA_WIDTH  : positive := 16;
        ADDR_WIDTH  : positive := 7
    );
    port (
        -- Ports corresponding to APB bridge
        pclk_in         : in std_logic;
        prstn_in        : in std_logic;
        mstr_data_in    : in std_logic_vector(2 downto 0);
        mstr_addr_in    : in std_logic_vector(ADDR_WIDTH - 1 downto 0);
        mstr_wbus_in    : in std_logic_vector(DATA_WIDTH - 1 downto 0);
        mstr_rbus_out   : out std_logic_vector(DATA_WIDTH - 1 downto 0);
        -- Ports corresponding to ROM interface
        rom_en_out      : out std_logic;
        rom_addr_out    : out std_logic_vector(5 downto 0);
        rom_data_in     : in std_logic_vector(15 downto 0);
        -- Ports corresponding to RAM interface
        ram_en_out      : out std_logic;
        ram_write_out   : out std_logic;
        ram_addr_out    : out std_logic_vector(6 downto 0);
        ram_wdata_out   : out std_logic_vector(7 downto 0);
        ram_rdata_in    : in std_logic_vector(7 downto 0) 
    );
end entity;

architecture rtl of APB_bus_wrap is
    -- System constant
    constant DATABUS_WD : positive := 16;   -- Data bus dimension
    constant ADDRBUS_WD : positive := 7;    -- Address bus dimension
    -- Entities to be wrapped
    component APB_bridge is                 -- AMBA APB system bridge, found in file "src/AMBA_APB.vhd"
        generic (
        DATA_WIDTH  : positive;
        ADDR_WIDTH  : positive
    );
        port (                              -- Ports details can be found in source VHDL file
            pclk_in         : in std_logic;
            prstn_in        : in std_logic;
            mstr_data_in    : in std_logic_vector(2 downto 0);
            mstr_addr_in    : in std_logic_vector(ADDR_WIDTH - 1 downto 0);
            mstr_wbus_in    : in std_logic_vector(DATA_WIDTH - 1 downto 0);
            mstr_rbus_out   : out std_logic_vector(DATA_WIDTH - 1 downto 0);
            prdata_in       : in std_logic_vector(DATA_WIDTH - 1 downto 0);
            pwdata_out      : out std_logic_vector(DATA_WIDTH - 1 downto 0);
            paddr_out       : out std_logic_vector(ADDR_WIDTH - 1 downto 0);
            pwrite_out      : out std_logic;
            penable_out     : out std_logic;
            psel1_out       : out std_logic;
            psel2_out       : out std_logic;
            state_curr_out  : out integer range 0 to 2;
            state_next_out  : out integer range 0 to 2
        );
    end component;
    component APB_slave_ROM_interface is        -- AMBA APB connections to Slave N° 1: 64x16 ROM
        port (                                  -- Ports details can be found in source VHDL files
            prstn_in        : in std_logic;
            penable_in      : in std_logic;
            psel_in         : in std_logic;
            pwrite_in       : in std_logic;
            paddr_in        : in std_logic_vector(6 downto 0);
            pwdata_in       : in std_logic_vector(15 downto 0);
            prdata_out	    : out std_logic_vector(15 downto 0);
            rom_en_out      : out std_logic;
            rom_addr_out    : out std_logic_vector(5 downto 0);
            rom_data_in     : in std_logic_vector(15 downto 0)                
        );
    end component;
    component APB_slave_RAM_interface is        -- AMBA APB connections to Slave N° 2: 128x8 RAM
        port (                                  -- Ports details can be found in source VHDL files
            prstn_in        : in std_logic;
            penable_in      : in std_logic;
            psel_in         : in std_logic;
            pwrite_in       : in std_logic;
            paddr_in        : in std_logic_vector(6 downto 0);
            pwdata_in       : in std_logic_vector(15 downto 0);
            prdata_out	    : out std_logic_vector(15 downto 0);
            ram_en_out      : out std_logic;
            ram_write_out   : out std_logic;
            ram_addr_out    : out std_logic_vector(6 downto 0);
            ram_wdata_out   : out std_logic_vector(7 downto 0);
            ram_rdata_in    : in std_logic_vector(7 downto 0)                
        );
    end component;
    -- SIGNALS FOR BUS CONNECTIONS
    signal penable_int      : std_logic;
    signal psel1_int        : std_logic;
    signal psel2_int        : std_logic;
    signal pwrite_int       : std_logic;
    signal prdata_int       : std_logic_vector(DATA_WIDTH - 1 downto 0);
    signal pwdata_int       : std_logic_vector(DATA_WIDTH - 1 downto 0);
    signal paddr_int        : std_logic_vector(ADDR_WIDTH - 1 downto 0);
    -- SIGNALS TO BE SYNCHRONISED
    -- Signals moving through APB bridge combinational logic from input to bridge registers
    signal mstr_data_syn    : std_logic_vector(2 downto 0);
    signal mstr_addr_syn    : std_logic_vector(ADDR_WIDTH - 1 downto 0);
    signal mstr_wbus_syn    : std_logic_vector(DATA_WIDTH - 1 downto 0);
    -- Signals moving through ROM interface combinational logic from bridge output registers to output
    signal rom_en_syn       : std_logic;
    signal rom_addr_syn     : std_logic_vector(5 downto 0);
    -- Signals moving through RAM interface combinational logic from bridge output registers to output
    signal ram_en_syn       : std_logic;
    signal ram_write_syn    : std_logic;
    signal ram_addr_syn     : std_logic_vector(6 downto 0);
    signal ram_wdata_syn    : std_logic_vector(7 downto 0);
    -- Signals moving through APB bus combinational logic from input to output
    signal rom_data_syn     : std_logic_vector(15 downto 0);
    signal ram_rdata_syn    : std_logic_vector(7 downto 0);
    signal mstr_rbus_syn    : std_logic_vector(15 downto 0);

begin
    -- APB bridge instantiation
    APB_BRIDGE_I: APB_bridge
    generic map(
        DATA_WIDTH => DATABUS_WD,
        ADDR_WIDTH => ADDRBUS_WD
    )
    port map(
        -- Inputs to sequential logic
        pclk_in         => pclk_in,
        prstn_in        => prstn_in,
        -- Inputs to combinational logic (need synchronisation)
        mstr_data_in    => mstr_data_syn,
        mstr_addr_in    => mstr_addr_syn,
        mstr_wbus_in    => mstr_wbus_syn,
        mstr_rbus_out   => mstr_rbus_syn,
        -- Signals from internal bus
        prdata_in       => prdata_int,
        -- Outputs of sequential
        pwdata_out      => pwdata_int,
        paddr_out       => paddr_int,
        pwrite_out      => pwrite_int,
        penable_out     => penable_int,
        psel1_out       => psel1_int,
        psel2_out       => psel2_int,
        -- Auxiliary outputs (simulation only)
        state_curr_out  => open,
        state_next_out  => open
    );
    -- APB Slave N° 1 instantiation
    SLAVE1_INTERFACE_I: APB_slave_ROM_interface
    port map(
        -- Signals from internal bus
        prstn_in        => prstn_in,
        penable_in      => penable_int,
        psel_in         => psel1_int,
        pwrite_in       => pwrite_int,
        paddr_in        => paddr_int,
        pwdata_in       => pwdata_int,
        prdata_out      => prdata_int,
        -- Outputs from combinational logic (need synchronisation)
        rom_en_out      => rom_en_syn,
        rom_addr_out    => rom_addr_syn,
        rom_data_in     => rom_data_syn             
    );
    -- APB Slave N° 2 instantiation
    SLAVE2_INTERFACE_I: APB_slave_RAM_interface
    port map(
        -- Signals from internal bus
        prstn_in        => prstn_in,
        penable_in      => penable_int,
        psel_in         => psel2_int,
        pwrite_in       => pwrite_int,
        paddr_in        => paddr_int,
        pwdata_in       => pwdata_int,
        prdata_out	    => prdata_int,
        -- Outputs from combinational logic (need synchronisation)
        ram_en_out      => ram_en_syn,
        ram_write_out   => ram_write_syn,
        ram_addr_out    => ram_addr_syn,
        ram_wdata_out   => ram_wdata_syn,
        -- Inputs to combinational logic
        ram_rdata_in    => ram_rdata_syn               
    );

    -- Synchronising process
    SYNC_P: process(pclk_in)
    begin
        if rising_edge(pclk_in) then
            -- Input signals to bridge
            mstr_data_syn <= mstr_data_in;
            mstr_addr_syn <= mstr_addr_in;
            mstr_wbus_syn <= mstr_wbus_in;
            -- Output signals from bridge
            mstr_rbus_out <= mstr_rbus_syn;
            -- Input signals from ROM
            rom_data_syn <= rom_data_in;
            -- Output signals to ROM
            rom_en_out <= rom_en_syn;
            rom_addr_out <= rom_addr_syn;
            -- Input signals to RAM
            ram_rdata_syn <= ram_rdata_in;
            -- Output signals to RAM
            ram_en_out <= ram_en_syn;
            ram_addr_out <= ram_addr_syn;
            ram_write_out <= ram_write_syn;
            ram_wdata_out <= ram_wdata_syn;
        end if;
    end process;

end architecture;