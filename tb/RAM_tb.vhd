-- Testbench file for 128x8 ROM. Device source code available at "src/RAM.vhd"

library IEEE;
    use ieee.std_logic_1164.all;            -- Required for standard logic and vectors

entity RAM_tb is                            -- Empty entity for testbench
end entity;

architecture beh of RAM_tb is               -- TB behavioural architecture declaration
    -- Testbench constants
    constant CK_PERIOD  : time := 10 ns;    -- Clock frequency set to 100 MHz
    -- Testbench component (Device Under Test)
    component RAM_128x8 is
        port(
            en_in       : in std_logic;
            write_in    : in std_logic;
            addr_in     : in std_logic_vector(6 downto 0);
            data_in     : in std_logic_vector(7 downto 0);
            data_out    : out std_logic_vector(7 downto 0)
        );
    end component;
    -- Testbench internal signals
    signal testing  : boolean := true;                              -- Simulation flag, becomes false at end of testing
    signal clk_tb   : std_logic := '0';                             -- Testbench clock, to time signal variations during tests
    -- Testbench simulated signals as input for DUT 
    signal en_ext   : std_logic := '0';
    signal wrt_ext  : std_logic := '0';                             -- External input access mode, read or write (default "read")
    signal addr_ext : std_logic_vector(6 downto 0) := "0000000";    -- External input address bus, controlled by testbench
    signal din_ext  : std_logic_vector(7 downto 0) := "00000000";   -- External bus for data to write
    -- Testbench measured signals as output from DUT
    signal dout_ext : std_logic_vector(7 downto 0);                 -- Output bus with data read
    -- Testbench other signals used as auxiliary signals for testing
    type mode_t is (R, W);                                          -- Read or Write mode
    signal mode_s   : mode_t := R;                                  -- Default mode is "read"

begin
    -- Clock activated while testing, period CK_PERIOD
    clk_tb <= not clk_tb after CK_PERIOD / 2 when testing else '0';
    -- Access mode signal (notifies "read" or "write valid transactions")
    mode_s <= R when wrt_ext = '0' else W;                          -- This signal allows to simplify the waveforms shown in simulation and make faster visual checks

    -- Component instantiation
    DUT: RAM_128x8
    port map(
        en_in => en_ext,
        write_in => wrt_ext,
        addr_in => addr_ext,
        data_in => din_ext,
        data_out => dout_ext
    );
    
    --------------------------------------------------------------------------------------------------------------
    -- STIMULI PROCESS: enables memory after 2 clock periods and performs read and write transaction, also trying
    -- to stress component. Verifications to be made:
    -- 1)  Different input address corresponds to access to different cells
    -- 2)  Multiple accesses to the same address correspond to access to the same cell
    -- 3)  Cells can be accessed both in reading and writing mode
    -- 4)  Writing to a cell changes its content (new value can be read thereafter)
    -- 5)  Rising edge of enable signal starts a new transaction
    -- 6)  Updating inputs with thier own previous values does not perturbate the system (pointless switching,
    --     increased dynamic power consumption)
    -- 7)  Input signals variations are not considered if they are not sampled by rising edge of enable
    --------------------------------------------------------------------------------------------------------------
    TB_PROC: process
        -- This procedure synchronises inputs to perform a write access to RAM (correct timing is met)
        procedure write(
            -- Procedure parameters: address of target cell and data to be written
            constant add_p  : std_logic_vector(6 downto 0);
            constant din_p  : std_logic_vector(7 downto 0)
        ) is
        begin
            -- Setup phase
            addr_ext <= add_p;
            din_ext <= din_p;
            wrt_ext <= '1';
            wait for 1 ns;                      -- May be used to simulate respect of setup time
            -- Access phase
            wait until rising_edge(clk_tb);     -- Enable signal is synchronized to testbench clock
            en_ext <= '1';                      -- Generate rising edge event
            wait for 5 ns;                      -- May be used to guarantee respect of hold time (busy waiting to make sure inputs do not change)
            wait until rising_edge(clk_tb);     -- Synchronises procedure to clock once more
            -- End of transaction
            en_ext <= '0';                      -- Go back to initial conditions
        end procedure;

        -- This procedure synchronises inputs to perform a read access to RAM (correct timing is met)
        procedure read(
        -- Procedure parameters: address of target cell and data to be written
            constant add_p  : std_logic_vector(6 downto 0)
        ) is
        begin
            -- Setup phase
            addr_ext <= add_p;
            wrt_ext <= '0';
            wait for 1 ns;                      -- May be used to simulate respect of setup time
            -- Access phase
            wait until rising_edge(clk_tb);     -- Enable signal is synchronized to testbench clock
            en_ext <= '1';                      -- Generate rising edge event
            wait for 5 ns;                      -- May be used to guarantee respect of hold time (busy waiting to make sure inputs do not change)
            wait until rising_edge(clk_tb);     -- Synchronises procedure to clock once more
            -- End of transaction
            en_ext <= '0';                      -- Go back to initial conditions
        end procedure;
    begin
        wait for 15 ns;
        ------------------------------------------------------------------------------------------------------------
        -- Series of read and write transaction, to evaluate multiple situations: reading a previously writeen
        -- value, overwriting cells, trying different read-write combinations, etc...
        ------------------------------------------------------------------------------------------------------------
        read("0001010");
        write("1101010", x"AC");
        write("1111111", x"FF");
        read("1101010");
        read("1010101");
        write("1111000", x"AA");
        read("0011001");
        write("0000011", x"13");
        read("1111000");
        write("0101011", x"11");
        read("0101011");
        read("0011001");
        write("0011100", x"56");
        read("0011100");
        read("1101010");
        write("1111111", x"01");
        write("1110000", x"33");
        read("0001000");
        read("1101010");
        read("1110000");
        ------------------------------------------------------------------------------------------------------------
        -- Series of tests out of normal operation mode, to stress possible wrong operations: input continuos changes 
        -- without enable, enable kept high, input variations close to enable fronts, etc...
        ------------------------------------------------------------------------------------------------------------
        addr_ext <= "1011001";
        addr_ext <= "0100110";
        addr_ext <= "1011001";
        wait for 1 ns;
        addr_ext <= "1100111";
        wrt_ext <= '1';
        wrt_ext <= '1';
        wait for 1 ns;
        wrt_ext <= '0';
        addr_ext <= "1110000";
        wait for 1 ns;
        wait until rising_edge(clk_tb);
        en_ext <= '1';
        wait for 5 ns;
        wrt_ext <= '1';
        din_ext <= x"21";
        addr_ext <= "1111111";
        wait for 1 ns;
        addr_ext <= "1100111";
        wrt_ext <= '1';
        wrt_ext <= '0';
        addr_ext <= "0000000";
        wait for 1 ns;
        en_ext <= '0';
        wait for 5 ns;
        addr_ext <= "0001000";
        wrt_ext <= '1';
        en_ext <= '1';
        wait for 5 ns;
        en_ext <= '0';
        wrt_ext <= '0';
        addr_ext <= "0000000";
        wait for 1 ns;
        wait until rising_edge(clk_tb);
        en_ext <= '1';
        wait for 20 ns;
        -- End simulation
        testing <= false;

    end process;

end architecture;