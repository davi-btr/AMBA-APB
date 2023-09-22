-- Wrapper to make sure every combinational block is included inside a register-logic-register path (by adding fictitious
-- registers to input/output ports when needed). This makes sure every potentially critical path is included in timing
-- constraints analysis

library IEEE;
    use IEEE.std_logic_1164.all;    -- Required for standard logic and vectors

entity APB_bridge_wrap is           -- Generics and ports match those of wrapped entity, found in file "src/APB_bridge.vhd"
    generic (
        DATA_WIDTH  : positive := 16;
        ADDR_WIDTH  : positive := 7
    );
    port (
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
        psel2_out       : out std_logic
        --state_curr_out  : out integer range 0 to 2;
        --state_next_out  : out integer range 0 to 2
    );
end entity;

architecture rtl of APB_bridge_wrap is
    -- System constant
    constant DATABUS_WD : positive := 16;   -- Data bus dimension
    constant ADDRBUS_WD : positive := 7;    -- Address bus dimension
    -- Entity to be wrapped
    component APB_bridge is
        generic (
        DATA_WIDTH  : positive;
        ADDR_WIDTH  : positive
    );
        port (
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
    -- Signals moving through combinational logic from input to register
    signal mstr_data_syn    : std_logic_vector(2 downto 0);
    signal mstr_addr_syn    : std_logic_vector(ADDR_WIDTH - 1 downto 0);
    signal mstr_wbus_syn    : std_logic_vector(DATA_WIDTH - 1 downto 0);

begin
    -- Component instantiation
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
        mstr_rbus_out   => mstr_rbus_out,
        prdata_in       => prdata_in,
        -- Outputs of sequential
        pwdata_out      => pwdata_out,
        paddr_out       => paddr_out,
        pwrite_out      => pwrite_out,
        penable_out     => penable_out,
        psel1_out       => psel1_out,
        psel2_out       => psel2_out,
        -- Auxiliary outputs (simulation only)
        state_curr_out  => open,
        state_next_out  => open
    );
    -- Synchronising process
    SYNC_P: process(pclk_in)
    begin
        if rising_edge(pclk_in) then
            mstr_data_syn <= mstr_data_in;
            mstr_addr_syn <= mstr_addr_in;
            mstr_wbus_syn <= mstr_wbus_in;
        end if;
    end process;

end architecture;