-- Testbench file for 64x16 ROM. Device source code available at "src/ROM.vhd"

library IEEE;
    use ieee.std_logic_1164.all;            -- Required for standard logic and vectors

entity ROM_tb is                            -- Empty entity for testbench
end entity;

architecture beh of ROM_tb is               -- TB behavioral architecture declaration
    -- Testbench constants
    constant CK_PERIOD  : time := 10 ns;    -- Clock frequency set to 100 MHz
    -- Testbench component (Device Under Test)
    component ROM_64x16 is
        port(
            en_in       : in std_logic;
            addr_in     : in std_logic_vector(5 downto 0);
            data_out    : out std_logic_vector(15 downto 0)
        );
    end component;
    -- Testbench internal signals 
    signal testing  : boolean := true;                          -- Simulation flag, becomes false at end of testing
    signal clk_tb   : std_logic := '0';                         -- Testbench clock, to time signal variations during tests
    -- Testbench simulated signals as input for DUT 
    signal en_ext   : std_logic := '0';                         -- External input chip selection, initially deactivated
    signal addr_ext : std_logic_vector(5 downto 0) := "000000"; -- External input address bus, controlled by testbench
    -- Testbench measured signals as output from DUT
    signal dout_ext : std_logic_vector(15 downto 0);            -- Full output measured by testbench
    -- Testbench other signals used as auxiliary signals for testing
    signal res_aux  : std_logic_vector(5 downto 0);             -- Auxiliary output signal to contain last 6 bits of output bus

begin
    -- Clock activated while testing with period CK_PERIOD
    clk_tb <= not clk_tb after CK_PERIOD / 2 when testing;
    -- Component instantiation
    DUT: ROM_64x16
    port map(
        en_in => en_ext,
        addr_in => addr_ext,
        data_out => dout_ext
    );

    --------------------------------------------------------------------------------------------------------------
    -- AUTOMATED SELF-CHECK PROCESS: verifies consistency of output values and input address.
    -- Whenever output is considered valid but its value does not match the content of the cell addressed by
    -- input, the simulation is instantly halted and an error log is displayed on console. This system relies
    -- on the way the ROM was initialised ("design for testability" strategy)
    --------------------------------------------------------------------------------------------------------------
    SELF_CHECK_P: process(dout_ext)
    begin
        if en_ext = '1' and addr_ext /= dout_ext(5 downto 0) then
            assert false report "---    ERROR: ROM output value inconsistent with address input     ---"
            severity failure;       -- Stop simulation with error message
        end if;
    end process;

    --------------------------------------------------------------------------------------------------------------
    -- STIMULI PROCESS: enables memory after 2 clock periods. Verifications to be made:
    -- 1) Output values are consistent with input address (6 LSBs of value correspond to binary representation
    --    of address by design during ROM initialisation). This is automatically accomplished using self-check
    --    auxiliary process to stop simulation in case of mismatch
    -- 2) Input address changes cause output values to change accordingly while chip is selected
    -- 3) Updating input address with its own previous value does not perturbate system (pointless switching,
    --    increased dynamic power consumption)
    -- 4) Chip deselection causes ROM to stop following input address variations
    -- 5) Chip reselection causes ROM to update its output value according to its current input address
    -- 6) Simultaneous switching of both input chip selection signals and input address bus does not upset
    --    normal functioning of ROM
    --------------------------------------------------------------------------------------------------------------
    TB_PROC: process(clk_tb)                -- Input signals change sinchronously with testbench clock
        variable count  : integer := 0;     -- Clock cycles counter
    begin
        if rising_edge(clk_tb) then
            case count is
                when 2  =>                  -- Activate ROM, expected output of address "000000"
                    en_ext <= '1';
                -- Some random tests for different addresses
                when 5  =>
                    addr_ext <= "001010";
                when 6 =>
                    addr_ext <= (others => '1');
                when 7  =>
                    addr_ext <= "101010";
                when 8  =>
                    addr_ext <= "101010";   -- Address update with its previous value
                when 9  =>
                    addr_ext <= "001110";
                when 10 =>
                    en_ext <= '0';          -- Chip deselect
                when 11  =>
                    addr_ext <= "111000";
                when 12  =>
                    addr_ext <= "000111";
                when 13 =>
                    en_ext <= '1';          -- Chip reselect
                when 14 =>
                    addr_ext <= "001010";
                when 15 =>                  -- Simultaneous (de)selections and address updates
                    addr_ext <= (others => '1');
                    en_ext <= '0';
                when 16 =>
                    en_ext <= '1';
                    addr_ext <= "011011";
                when 18 =>
                    addr_ext <= (others => '0');
                when 20 =>                  -- Constantly commuting enable signal (more similar to the behaviour required for APB)
                    en_ext <= '0';
                when 21 =>
                    en_ext <= '1';
                when 23 =>
                    en_ext <= '0';
                when 24 =>
                    addr_ext <= "001100";
                when 25 =>
                    en_ext <= '1';
                when 30 =>
                    testing <= false;       -- End simulation after 20 CK_PERIOD
                  
                when others =>              -- Default case: wait
                
            end case;
        
            count := count + 1;             -- Iterator update
        end if;
    end process;

    res_aux <= dout_ext(5 downto 0);        -- Auxiliary signal always contains 6 LSBs of full output, making easier to check if they match address

end architecture;