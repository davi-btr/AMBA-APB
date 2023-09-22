-- Design of APB bridge to simulate communications based on AMBA-APB protocol

library IEEE;
    use IEEE.std_logic_1164.all;    -- Required for standard logic and vectors

entity APB_bridge is
    generic (
        -- This parameters could be set by design, even though in this case they are actually fixed by the peripherals of the system
        DATA_WIDTH  : positive;
        ADDR_WIDTH  : positive
    );
    port (
        -- General signals:
        pclk_in         : in std_logic;
        prstn_in        : in std_logic;                                 -- APB bridge reset signal, active LOW
        -- Signals from master, they specify the peripheral, the required transaction, its addres and the data involved
        mstr_data_in    : in std_logic_vector(2 downto 0);              -- 1st bit: require transaction, 2nd bit: slave select, 3rd bit: read/write
        mstr_addr_in    : in std_logic_vector(ADDR_WIDTH - 1 downto 0); -- Address of transaction
        mstr_wbus_in    : in std_logic_vector(DATA_WIDTH - 1 downto 0); -- Data to be written to slave during write transaction
        mstr_rbus_out   : out std_logic_vector(DATA_WIDTH - 1 downto 0);-- Data read from slave in response to a read transaction
        -- Signals required by APB protocol, connecting APB bridge to its peripherals (slaves)
        prdata_in       : in std_logic_vector(DATA_WIDTH - 1 downto 0);
        pwdata_out      : out std_logic_vector(DATA_WIDTH - 1 downto 0);
        paddr_out       : out std_logic_vector(ADDR_WIDTH - 1 downto 0);
        pwrite_out      : out std_logic;
        penable_out     : out std_logic;
        psel1_out       : out std_logic;                                -- slave N° 1: ROM
        psel2_out       : out std_logic;                                -- slave N° 2: RAM
        -- Signals related to "design for testability"
        state_curr_out  : out integer range 0 to 2;
        state_next_out  : out integer range 0 to 2
    );
end entity;

architecture rtl of APB_bridge is
    -------------------------------------------------------------------------------------------------------------
    -- APB bridge is a finite state machine (FSM) with 3 states:
    --      IDLE (idle state: default condition, wait for transaction request)
    --      START (setup state: first state of read/write, select peripheral and set address)
    --      END (access state: enable peripheral, perform transaction)
    -------------------------------------------------------------------------------------------------------------
    type state_t is (IDLE_ST, START_ST, END_ST);    -- Possible states
    -- General signals
    signal clk_s            : std_logic;            -- Actual clock signal
    -- Results of combinational logic
    signal state_next_s     : state_t;
    signal psel1_next_s     : std_logic;
    signal psel2_next_s     : std_logic;
    signal penable_next_s   : std_logic;
    signal pwrt_next_s      : std_logic;
    signal pwdata_next_s    : std_logic_vector(DATA_WIDTH - 1 downto 0);
    signal paddr_next_s     : std_logic_vector(ADDR_WIDTH - 1 downto 0);
    -- Output registers
    signal state_curr_s : state_t;
    signal psel1_s      : std_logic;
    signal psel2_s      : std_logic;
    signal penable_s    : std_logic;
    signal pwrite_s     : std_logic;
    signal pwdata_s     : std_logic_vector(DATA_WIDTH - 1 downto 0);
    signal paddr_s      : std_logic_vector(ADDR_WIDTH - 1 downto 0);
	-- Signal corresponding to output ports outside FSM, for better readability of code and simulation waveform, and also pre-2008 VHDL compatible
    signal mstr_rbus_s  : std_logic_vector(DATA_WIDTH - 1 downto 0);

begin
    clk_s <= pclk_in;

    -----------------------------------------------------------------------------------------------------------
    -- Synchronous process for modified Mealy machines: output values are updated on rising edge of system
    -- clock, loading the values calculated by combinational block.
    -- Reset signal is handled synchronously, setting all outputs to zero or default conditions.
    -----------------------------------------------------------------------------------------------------------
    OUT_REG_P: process(clk_s)
    begin
        if rising_edge(clk_s) then
            if prstn_in = '0' then                  -- Synchronous reset command
                state_curr_s <= IDLE_ST;            -- If reset is active keep waiting in IDLE state
                pwdata_s <= (others => '0');        -- Reset data bus wires (optional): helps overwriting undefined conditions and makes testing easier, and is also a hardware security measure (no data leakage)
                paddr_s <= (others => '0');         -- Reset address bus wires (optional): helps overwriting undefined conditions and makes testing easier, and is also a hardware security measure (no address leakage)
                --mstr_rbus_s <= (others => '0');     -- Reset last data sent to master: hardware security measure (prevents data leakage)
                pwrite_s <= '0';                    -- Reset condition for pwrite is "read", for better integrity (no spurious writings)
                penable_s <= '0';                   -- Transactions are halted
                psel1_s <= '0';
                psel2_s <= '0';
            else                                    -- Ordinary execution flow
                psel1_s <= psel1_next_s;
                psel2_s <= psel2_next_s;
                penable_s <= penable_next_s;
                pwrite_s <= pwrt_next_s;
                pwdata_s <= pwdata_next_s;
                paddr_s <= paddr_next_s;
                state_curr_s <= state_next_s;
            end if;
        end if;
    end process;
    -----------------------------------------------------------------------------------------------------------
    -- Combinational process for modified Mealy machines: next state and correlated outputs are calculated
    -- based on inputs and current state.
    -----------------------------------------------------------------------------------------------------------
    FSM_P: process(state_curr_s, mstr_data_in, mstr_wbus_in, mstr_addr_in, psel1_s, psel2_s, pwrite_s, paddr_s, pwdata_s)    -- reset has been put in sensitivity list just to 
    begin
        -- All signals are always assigned to avoid undefined architecture-dependent behaviour and facilitate testing
        -- Default values (some of them are simply transparent to avoid extra logic with increased area occupation and power leakage)
        penable_next_s <= '0';
        psel1_next_s <= '0';
        psel2_next_s <= '0';
        pwrt_next_s <= '0';
        state_next_s <= IDLE_ST;
        paddr_next_s <= mstr_addr_in;
        pwdata_next_s <= mstr_wbus_in;
        case state_curr_s is
        when IDLE_ST =>
            if mstr_data_in(2) = '1' then   -- Transaction detected
                state_next_s <= START_ST;   -- Get ready for beginnining of transaction
                pwrt_next_s <= mstr_data_in(0);
                if mstr_data_in(1) = '0' then
                    psel1_next_s <= '1';    -- Target slave N° 1
                else psel2_next_s <= '1';   -- Target slave N° 2
                end if;
            end if;
        when START_ST =>
            -- Outputs set for END state
            state_next_s <= END_ST;
            penable_next_s <= '1';
            psel1_next_s <= psel1_s;
            psel2_next_s <= psel2_s;
            pwrt_next_s <= pwrite_s;
            paddr_next_s <= paddr_s;
            pwdata_next_s <= pwdata_s;
        when END_ST =>
            -- AMBA APB protocol allows consequent access to same peripheral, w.o. returning to IDLE state
            if mstr_data_in(2) = '1' then
                if (mstr_data_in(1) = '0' and psel1_s = '1') or (mstr_data_in(1) = '1' and psel2_s = '1') then
                -- Transaction is concluded but the same slave is requested again: the FSM goes directly to START state
                state_next_s <= START_ST;
                pwrt_next_s <= mstr_data_in(0);
                psel1_next_s <= psel1_s;
                psel2_next_s <= psel2_s;
                end if;
            end if;
        when others =>
        end case;
    end process;

    mstr_rbus_s <= prdata_in;

    -- Output signals assigned to corresponding ports
    mstr_rbus_out <= mstr_rbus_s;
    pwdata_out <= pwdata_s;
    paddr_out <= paddr_s;
    pwrite_out <= pwrite_s;
    penable_out <= penable_s;
    psel1_out <= psel1_s;
    psel2_out <= psel2_s;
    -- Auxiliary output signals
    state_curr_out <= 0 when state_curr_s = IDLE_ST else 1 when state_curr_s = START_ST else 2;
    state_next_out <= 0 when state_next_s = IDLE_ST else 1 when state_next_s = START_ST else 2;

end architecture;