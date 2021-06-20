library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use std.textio.all;
use std.env.finish;

entity VGA_demo_tb is
end VGA_demo_tb;

architecture sim of VGA_demo_tb is

  constant clk_hz : integer := 50e6;
  constant clk_period : time := 1 sec / clk_hz;

  signal clk : std_logic := '1';
  signal rst : std_logic := '1';

  signal ADC_CLK_10    : std_logic := '0';
  signal VGA_R         : std_logic_vector(3 downto 0);
  signal VGA_G         : std_logic_vector(3 downto 0);
  signal VGA_B         : std_logic_vector(3 downto 0);
  signal VGA_HS        : std_logic;
  signal VGA_VS        : std_logic;
  signal KEY           : std_logic_vector(1 downto 0) := (others => '0');

begin

  clk <= not clk after clk_period / 2;

  DUT : entity work.VGA_demo(rtl)
  port map (
    ADC_CLK_10    => ADC_CLK_10,
    MAX10_CLK1_50 => clk,
    MAX10_CLK2_50 => clk,
    VGA_R         => VGA_R,
    VGA_G         => VGA_G,
    VGA_B         => VGA_B,
    VGA_HS        => VGA_HS,
    VGA_VS        => VGA_VS,
        
    KEY           => KEY
  );

  SEQUENCER_PROC : process
  begin
    wait for clk_period * 2;

    -- release reset
    KEY(0) <= '1';

    wait for clk_period * 1000000;
    --assert false
    --  report "Replace this with your test cases"
    --  severity failure;

    --finish;
  end process;

end architecture;