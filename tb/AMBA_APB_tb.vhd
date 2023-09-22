-- Testbench file for APB system (APB bridge, slave ROM, slave RAM): simulates APB transactions requested from
-- external master and performed by APB bridge on slaves.
-- Single components code available inside "src/" directory

library IEEE;
    use ieee.std_logic_1164.all;            -- Required for standard logic and vectors 

entity APB_tb is                            -- Empty entity for testbench
end entity;

architecture rtl of APB_tb is               -- TB RTL architecture declaration
    -- TESTBENCH CONSTANTS
    constant CK_PERIOD  : time := 10 ns;    -- Clock frequency set to 100 MHz
    constant DATABUS_WD : positive := 16;   -- Data bus dimension
    constant ADDRBUS_WD : positive := 7;    -- Address bus dimension
    -- TESTBENCH COMPONENTS (system components: APB bridge, two APB slaves)
    component APB_bridge is                 -- Entity APB_bridge in file src/AMBA_APB.vhd
        generic (                           -- System dimensions set
        DATA_WIDTH  : positive := 16;
        ADDR_WIDTH  : positive := 7
        );
        port (                              -- Port details are documented in respective source file
        pclk_in         : in std_logic;
        prstn_in        : in std_logic;
        mstr_data_in    : in std_logic_vector(2 downto 0);  -- Message format (1st bit: require transaction, 2nd bit: slave select, 3rd bit: read/write)
        mstr_addr_in    : in std_logic_vector(ADDR_WIDTH - 1 downto 0);
        mstr_wbus_in    : in std_logic_vector(DATA_WIDTH - 1 downto 0);
        mstr_rbus_out   : out std_logic_vector(DATA_WIDTH - 1 downto 0);
        prdata_in       : in std_logic_vector(DATA_WIDTH - 1 downto 0);
        pwdata_out      : out std_logic_vector(DATA_WIDTH - 1 downto 0);
        paddr_out       : out std_logic_vector(ADDR_WIDTH - 1 downto 0);
        pwrite_out      : out std_logic;
        penable_out     : out std_logic;
        psel1_out       : out std_logic;    -- Slave N° 1: ROM
        psel2_out       : out std_logic;    -- Slave N° 2: RAM
        state_curr_out  : out integer range 0 to 2;
        state_next_out  : out integer range 0 to 2
        );
    end component;
    component APB_slave_ROM is              -- Entity APB_slave_ROM in file src/APB_ROM_wr.vhd
        port(                               -- Port details are documented in respective source file
            prstn_in    : in std_logic;
            penable_in  : in std_logic;
            psel_in     : in std_logic;
            pwrite_in   : in std_logic;
            paddr_in    : in std_logic_vector(ADDRBUS_WD - 1 downto 0);
            pwdata_in   : in std_logic_vector(DATABUS_WD - 1 downto 0);
            prdata_out	: out std_logic_vector(DATABUS_WD - 1 downto 0)
        );
    end component;
    component APB_slave_RAM is              -- Entity APB_slave_RAM in file src/APB_RAM_wr.vhd
        port(                               -- Port details are documented in respective source file
            prstn_in    : in std_logic;
            penable_in  : in std_logic;
            psel_in     : in std_logic;
            pwrite_in   : in std_logic;
            paddr_in    : in std_logic_vector(ADDRBUS_WD - 1 downto 0);
            pwdata_in   : in std_logic_vector(DATABUS_WD - 1 downto 0);
            prdata_out	: out std_logic_vector(DATABUS_WD - 1 downto 0)
        );
    end component;
    -- TESTBENCH SIGNALS DECLARATION AND INITIALISATION
    -- Simulation-related parameters
    signal testing  : boolean := true;                                                  -- Simulation flag, becomes false at the end of testing
    -- External inputs generated from TB to simulate normal functioning of APB system (clock oscillator, bus reset, transaction requests from master,...)
    signal pclk_ext         : std_logic := '0';                                         -- System clock, simulating external oscillator
    signal prstn_ext        : std_logic := '0';                                         -- External reset signal for the bus
    signal mstr_data_ext    : std_logic_vector(2 downto 0) := "000";                    -- Master control message. 1st MSB bit: require transaction, 2nd MSB bit: slave select, 3rd MSB bit: read/write
    signal mstr_addr_ext    : std_logic_vector(ADDRBUS_WD - 1 downto 0) := "0000000";   -- External input address bus, controlled by testbench
    signal mstr_wdata_ext   : std_logic_vector(DATABUS_WD - 1 downto 0) := x"0000";     -- External bus for data to write
    signal mstr_rdata_ext   : std_logic_vector(DATABUS_WD - 1 downto 0);                -- Output bus with data read
    -- Internal wires of the bus (interface between APB bridge and slaves)
    signal pwrite_int       : std_logic;                                                -- Signal pwrite line
    signal penable_int      : std_logic;                                                -- Signal penable line
    signal psel1_int        : std_logic;                                                -- Signal pselect line for first slave
    signal psel2_int        : std_logic;                                                -- Signal pselect line for second slave
    signal paddr_int        : std_logic_vector(ADDRBUS_WD - 1 downto 0);                -- Signal paddr internal bus
    signal pwdata_int       : std_logic_vector(DATABUS_WD - 1 downto 0);                -- Signal pwdata internal bus
    signal prdata_int       : std_logic_vector(DATABUS_WD - 1 downto 0);                -- Signal prdata internal bus
    -- Auxiliary signals for testing
    signal state_curr_tst   : integer range 0 to 2;                                     -- Internal FSM current state reported as output
    signal state_next_tst   : integer range 0 to 2;                                     -- Internal FSM next state reported as output
    type mode_t is (R, W, N);                                                           -- Read, write or none (mode)
    signal mode_s   : mode_t := N;                                                      -- Mode of current transaction
    type slave_t is (ROM, RAM, NON);                                                    -- ROM, RAM or none (target)
    signal slave_s   : slave_t := NON;                                                  -- Target of current transaction

    begin
    -- Clock activated while testing, period CK_PERIOD
    pclk_ext <= not pclk_ext after CK_PERIOD / 2 when testing else '0';
    -- This test signals allow to simplify the waveforms shown in simulation and make faster checks on them
    mode_s <= R when pwrite_int = '0' and (psel1_int = '1' or psel2_int = '1') else W when pwrite_int = '1' else N;  -- Display transaction type while accessing peripherals
    slave_s <= ROM when psel1_int = '1' else RAM when psel2_int = '1' else NON;         -- Display target of current transaction
    -- Components instantiation
    BUS_I: APB_bridge           -- APB bridge instantiation
    generic map(
        DATA_WIDTH => DATABUS_WD,
        ADDR_WIDTH => ADDRBUS_WD
    )
    port map(                   -- Master-interface ports associated with respective TB-generated signals; APB ports associated with respective bus wires
        pclk_in         => pclk_ext,
        prstn_in        => prstn_ext,
        mstr_data_in    => mstr_data_ext,
        mstr_addr_in    => mstr_addr_ext,
        mstr_wbus_in    => mstr_wdata_ext,
        mstr_rbus_out   => mstr_rdata_ext,
        prdata_in       => prdata_int,
        pwdata_out      => pwdata_int,
        paddr_out       => paddr_int,
        pwrite_out      => pwrite_int,
        penable_out     => penable_int,
        psel1_out       => psel1_int,
        psel2_out       => psel2_int,
        state_curr_out  => state_curr_tst,
        state_next_out  => state_next_tst
    );
    SLAVE1_I: APB_slave_ROM     -- APB slave N° 1 instantiation (64x16 ROM)
        port map(               -- All APB ports associated with respective internal wires
            prstn_in    => prstn_ext,
            penable_in  => penable_int,
            psel_in     => psel1_int,
            pwrite_in   => pwrite_int,
            paddr_in    => paddr_int,
            pwdata_in   => pwdata_int,
            prdata_out	=> prdata_int
        );
    SLAVE2_I: APB_slave_RAM     -- APB slave N° 2 instantiation (128x8 RAM)
        port map(               -- All APB ports associated with respective internal wires
            prstn_in    => prstn_ext,
            penable_in  => penable_int,
            psel_in     => psel2_int,
            pwrite_in   => pwrite_int,
            paddr_in    => paddr_int,
            pwdata_in   => pwdata_int,
            prdata_out	=> prdata_int
        );
    
    --------------------------------------------------------------------------------------------------------------
    -- ERROR PROCESSES: Series of processes meant to automatically stop simulation in case of inconsistency
    -- during transactions and especially their violation of the  APB specifications (signals on internal bus
    -- do not violate any APB timing constraint)
    --------------------------------------------------------------------------------------------------------------
    EN_CONSISTENCY_P: process(psel1_int, psel2_int, pwrite_int, pwdata_int)
    -- This process makes sure no APB signal is modified during access phase (enable is HIGH). This test is both
    -- for APB compliance and transaction consistency (peripherals should not ever see their instructions changed
    -- during actual access phase, to avoid spurious transactions and undefined conditions)
    begin
        if penable_int = '1' then   -- There has been an APB signal variation during access phase
            assert false report "---    ERROR 1: APB protocol violation     ---"
            severity failure;       -- Stop simulation with error message
        end if;
    end process;

    MULTIPLE_SEL_P: process(psel1_int, psel2_int)
    -- This process makes sure only one APB slave is selected at a time. This test is both for APB compliance and
    -- to ensure no unintended command is issued to wrong peripheral
    begin
        if psel1_int = '1' and psel2_int = '1' then   -- There has been an APB selection while other slave is already selected
            assert false report "---    ERROR 2:  Both slaves selected simultaneously     ---"
            severity failure;       -- Stop simulation with error message
        end if;
    end process;
    --------------------------------------------------------------------------------------------------------------------
    -- WARNING PROCESSES: Series of processes meant to automatically detect unintended behaviours during
    -- communications (i.e. illegal master requests, out-of-boundary addresses and data, ...)
    --------------------------------------------------------------------------------------------------------------------
    ROM_WRITE_P: process(pwrite_int, psel1_int)
    -- This process detects write attempts to ROM, which are designed to fail
    begin
        if psel1_int = '1' and pwrite_int = '1' then   -- ROM is being accessed in write mode
            assert false report "---    WARNING:  Illegal transaction attempted (Slave 1 is read-only)     ---"
            severity warning;
        end if;
    end process;

    ROM_ADDR_OF_P: process(pwrite_int, psel1_int)
    -- This process detects ROM address overflow, which would determine access to wrong cells due to different
    -- address dimension between peripherals 
    begin
        if psel1_int = '1' and paddr_int(ADDRBUS_WD - 1) = '1' then   -- invalid ROM cell is being accessed
            assert false report "---    WARNING:  Out-of-boundary access (Slave 1 has 6 bit address)     ---"
            severity warning;
        end if;
    end process;
    RAM_DATA_OF_P: process(pwrite_int, psel1_int)
    -- This process detects RAM data overflow, which would determine only partial data to be written due to
    -- different data bus dimension between peripherals 
    begin
        if psel2_int = '1' and pwdata_int(DATABUS_WD - 1 downto 8) /= x"00" then   -- RAM will only consider half the bus
            assert false report "---    WARNING:  Out-of-boundary data (Slave 2 has 8 bit data bus)     ---"
            severity warning;
        end if;
    end process;
    --------------------------------------------------------------------------------------------------------------
    -- STIMULI PROCESS: Simulates master commands to determine system behaviour. Verifications to be made:
    -- 1)  Master requests are correctly interpreted
    -- 2)  Internal bus is handled accordingly to transaction requested
    -- 3)  Signals on internal bus are consistent with APB protocol
    -- 4)  Peripherals are responsive to transaction requests
    -- 5)  Both slaves are accessible
    -- 6)  Read and write transactions are consistent with content of peripherals
    -- 7)  System intended functionality requirements are met (sped-up transactions with same peripheral)
    -- 8)  Reset stops communication and reinitialises system
    -- 9)  Master requests are not served during reset
    -- 10) Reset lift allows the system to function normally
    -- 11) Master requests are served only when sampled by a rising clock edge and system is ready to receive them
    -- 12) Running transactions (once accepted) are not disturbed by master activity (not regarding APB bus)
    -- 13) No data leakage (data is sent to master only when read transactions require it)
    -- 14) Output data bus to master is kept in high-Z when data is not valid (possibility of bus sharing)
    --------------------------------------------------------------------------------------------------------------
    TB_PROC: process
        procedure write_transaction(
            -- Simulates master request for a single write request to specified slave
            constant slv_p  : integer range 0 to 1;                         -- Requested slave index: 0 for ROM, 1 for RAM
            constant add_p  : std_logic_vector(ADDRBUS_WD - 1 downto 0);    -- Transaction address
            constant din_p  : std_logic_vector(DATABUS_WD - 1 downto 0)     -- Data to write
        ) is
        begin
            -- Setup signals
            mstr_addr_ext <= add_p;
            mstr_wdata_ext <= din_p;
            mstr_data_ext <= (2 => '1', 0 => '1', others => '0');
            if slv_p = 0 then
                mstr_data_ext(1) <= '0';
            else mstr_data_ext(1) <= '1';
            end if;
            -- Ensure APB system samples transaction request
            wait until rising_edge(pclk_ext);
            wait for 5 ns;                      -- Can be set to any time value, depends on master
            -- End of transaction request (transaction is requested only once)
            mstr_data_ext(2) <= '0';
        end procedure;

        procedure read_transaction(
            -- Simulates master request for a single read request from specified slave
            constant slv_p  : integer range 0 to 1;                         -- Requested slave index: 0 for ROM, 1 for RAM
            constant add_p  : std_logic_vector(ADDRBUS_WD - 1 downto 0)     -- Transaction address
        ) is
        begin
            -- Setup signals
            mstr_addr_ext <= add_p;
            mstr_data_ext <= (2 => '1', 0 => '0', others => '0');
            if slv_p = 0 then
                mstr_data_ext(1) <= '0';
            else mstr_data_ext(1) <= '1';
            end if;
            -- Ensure APB system samples transaction request
            wait until rising_edge(pclk_ext);
            wait for 5 ns;                      -- Can be set to any time value, depends on master
            -- End of transaction request (transaction is requested only once)
            mstr_data_ext(2) <= '0';
        end procedure;

        procedure sync_to_EOT is
            -- APB transactions require 2 clock cycles to complete (should be called right after transaction request)
        begin
            wait until rising_edge(pclk_ext);
            wait until rising_edge(pclk_ext);
            -- At this point access from previous transaction has been completed
        end procedure;

    begin
        wait for 15 ns;
        -- Lift reset and start testing
        prstn_ext <= '1';
        -- TEST FOR BASIC OPERATIONS (single read/write transactions):
        -- Long series of single transactions to read and write different cells from both slaves
        read_transaction(0, "0001010");
        sync_to_EOT;
        write_transaction(1, "1101010", x"00AC");
        sync_to_EOT;
        write_transaction(1, "1111111", x"00FF");
        sync_to_EOT;
        read_transaction(1, "1101010");
        sync_to_EOT;
        read_transaction(0, "0010101");
        sync_to_EOT;
        write_transaction(1, "1111000", x"BBAA");   -- Intended warning
        sync_to_EOT;
        read_transaction(1, "0011001");
        sync_to_EOT;
        write_transaction(0, "0000011", x"0013");   -- Intended warning
        sync_to_EOT;
        read_transaction(1, "1111000");
        sync_to_EOT;
        write_transaction(1, "0101011", x"0011");
        sync_to_EOT;
        read_transaction(0, "1101011");             -- Intended warning
        sync_to_EOT;
        -- TEST FOR OTHER INTENDED FUNCTIONALITIES (multiple sped-up transactions on single slave)
        read_transaction(0, "0111111");
        wait until rising_edge(pclk_ext);   -- First stage of transaction
        read_transaction(0, "0001111");    -- New transaction request is simultaneous with previous EOT (end of transaction)
        wait until rising_edge(pclk_ext);
        read_transaction(0, "0000000");    -- Once more
        sync_to_EOT;
        write_transaction(1, "1011111", x"0045");
        wait until rising_edge(pclk_ext);
        read_transaction(1, "1011111");
        wait until rising_edge(pclk_ext);
        sync_to_EOT;
        -- TEST FOR RESET
        read_transaction(1, "0100000");     -- Transaction abort by reset
        prstn_ext <= '0';
        read_transaction(0,"0011001");
        sync_to_EOT;
        write_transaction(1, "0011100", x"0056");
        sync_to_EOT;
        read_transaction(0, "0011100");
        sync_to_EOT;
        prstn_ext <= '1';
        mstr_data_ext(2) <= '1';
        wait until rising_edge(pclk_ext);   -- Transactions restart
        -- TEST FOR UNINTENDED BEHAVIOUR
        read_transaction(0, "0000011");     -- Transaction requested while other is still running
        wait until rising_edge(pclk_ext);
        wait until rising_edge(pclk_ext);
        wait for 3 ns;                      -- Desynchronise operations from testbench clock (to verify system sampling master commands)
        -- Commands accepted are the ones sampled by rising edge of clock
        mstr_data_ext <= "100";
        mstr_addr_ext <= "0000111";
        mstr_wdata_ext <= x"00C3";
        wait for 5 ns;
        mstr_data_ext <= "111";
        wait for 5 ns;
        mstr_data_ext <= "110";
        wait for 5 ns;
        mstr_addr_ext <= "1111101";
        -- TEST FOR SYSTEM ROBUSTNESS (normal functioning is not altered during tests)
        read_transaction(1,"1101010");
        sync_to_EOT;
        write_transaction(1, "1111111", x"0001");
        sync_to_EOT;
        write_transaction(1, "1110000", x"0033");
        sync_to_EOT;
        read_transaction(0, "0001000");
        sync_to_EOT;
        read_transaction(1, "1110000");
        sync_to_EOT;
        wait for 20 ns;
        testing <= false;

    end process;

end architecture;