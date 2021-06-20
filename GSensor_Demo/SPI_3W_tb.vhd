library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use std.textio.all;
use std.env.finish;

entity SPI_3W_tb is
end SPI_3W_tb;

architecture sim of SPI_3W_tb is

    constant clk_hz : integer := 50e6;
    constant clk_period : time := 1 sec / clk_hz;

    signal clk  : std_logic := '1';
    signal nrst : std_logic := '0';

    signal spi_st     : std_logic := '0';
    signal spi_isbusy : std_logic;
    signal spi_add    : std_logic_vector(7 downto 0) := (others => '0');
    signal spi_dat_in : std_logic_vector(7 downto 0) := (others => '0');
    signal spi_dat_out: std_logic_vector(7 downto 0);

    signal GSENSOR_SDI: std_logic := '0';
    signal mosi       : std_logic;
    signal nCS        : std_logic;
    signal sclk       : std_logic;

    signal read_cmd   : std_logic := '1'; -- 1 is read, 0 is write
    signal mult_byte  : std_logic := '0'; -- 0 is single byte, 1 is multiple byte (not implemented yet)

    subtype addresse_format_type is std_logic_vector(5 downto 0);
    constant xData0_add  : addresse_format_type := "110010";  -- 0x32 -R
    constant xOffset_add : addresse_format_type := "011110";  -- 0x1E -RW
begin

    clk <= not clk after clk_period / 2;

    DUT : entity work.SPI_3W(rtl)
    generic map (
        CLK_DIVIDER  => 10
    )
    port map (
        CLK          => clk,
        RESETn       => nrst,

        SPI_START    => spi_st,
        SPI_ADDR     => spi_add,
        SPI_DATA_IN  => spi_dat_in,
        SPI_DATA_OUT => spi_dat_out,
        SPI_BUSY     => spi_isbusy,

        SDIO         => GSENSOR_SDI,
        CSn          => nCS,
        SCLK         => sclk
    );

    SEQUENCER_PROC : process
    begin
        wait for clk_period * 2;

        nrst <= '1';

        wait for clk_period * 10;

        spi_dat_in <= "10010110"; --  offset value

        -- simulation of the read X-Axis Data 0
        spi_add <= read_cmd & mult_byte & xData0_add;
        spi_st <= '1';
        wait for clk_period;
        spi_st <= '0';
        wait for clk_period * 200;

        -- simulation of the write xOffset 
        spi_add <= not read_cmd & mult_byte & xOffset_add;
        
        spi_st <= '1';
        wait for clk_period;
        spi_st <= '0';
        wait for clk_period * 200;   

        wait for clk_period * 600;   

        assert false
            report "Replace this with your test cases"
            severity failure;

        finish;
    end process;

end architecture;