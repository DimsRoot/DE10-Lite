library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
Ò
entity GSensor_interface is
    generic (
        clk_in_MHz      : integer := 50;
        MAX_SPI_CLK_MHz : integer := 5
    )
    port (
        CLK    : in std_logic;
        RESETn : in std_logic;

        GSENSOR_INT  :  in std_logic_vector(1 downto 0);
        GSENSOR_SDI  :  in std_logic;
        GSENSOR_CS_N : out std_logic := '0';
        GSENSOR_SCLK : out std_logic := '0';
        GSENSOR_SDO  : out std_logic := '0';

        LEDR : out std_logic_vector(9 downto 0)
    );
end GSensor_interface;

architecture rtl of GSensor_interface is

begin



end architecture;