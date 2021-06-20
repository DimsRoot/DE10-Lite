library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use std.textio.all;
use std.env.finish;

entity trigger_generator_tb is
end trigger_generator_tb;

architecture sim of trigger_generator_tb is

    constant clk_hz : integer := 50e6;
    constant clk_period : time := 1 sec / clk_hz;

    signal clk : std_logic  := '1';
    signal nrst : std_logic := '0';

    signal trigger : std_logic := '0';

begin

    clk <= not clk after clk_period / 2;

    DUT : entity work.trigger_generator(rtl)
    generic map(
        TRIGGER_FREQ_Hz => 100000
    )
    port map (
        CLK => clk,
        nRST => nrst,
        OUT_PULS => trigger
    );

    SEQUENCER_PROC : process
    begin
        wait for clk_period * 2;

        nrst <= '1';

        wait for clk_period * 100000;
        assert false
            report "Replace this with your test cases"
            severity failure;

        finish;
    end process;

end architecture;