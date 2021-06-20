library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity SPI_3W is
    generic (
        CLK_DIVIDER : integer := 20
    );
    port (
        CLK           : in std_logic;
        RESETn        : in std_logic;

        SPI_START     :  in std_logic;
        SPI_ADDR      :  in std_logic_vector(7 downto 0);   -- address of the SPI device register
        SPI_DATA_IN   :  in std_logic_vector(7 downto 0);   -- data to send to the SPI device
        SPI_DATA_OUT  : out std_logic_vector(7 downto 0);   -- data from the SPI device
        SPI_BUSY      : out std_logic := '0';

        SDIO  : inout std_logic;
        CSn   : out std_logic := '1';
        SCLK  : out std_logic := '0'
    );
end SPI_3W;

architecture rtl of SPI_3W is
    type spi_state_type is (idle, w_cmd, rw_data);
    signal spi_state : spi_state_type := idle;

    signal cmd       : std_logic_vector(    SPI_ADDR'high downto 0);
    signal send_data : std_logic_vector( SPI_DATA_IN'high downto 0);
    signal rx_data   : std_logic_vector(SPI_DATA_OUT'high downto 0);

    signal spi_clk   : std_logic := '0';
    
    signal bit_cnt     : natural range 0 to SPI_DATA_IN'high;
    signal clk_cnt     : natural range 0 to CLK_DIVIDER;
    signal load_data   : std_logic := '0';
    signal sample_data : std_logic := '0';
begin

    spi_proc: process(CLK) is
    begin
        if rising_edge(CLK) then
            if (RESETn = '0') then
                spi_state    <= idle;
                SDIO         <= '0';
                CSn          <= '1';
            else
                case spi_state is
                    when idle =>
                        SDIO         <= 'Z';
                        CSn          <= '1';
                        bit_cnt      <= cmd'high;

                        if SPI_START = '1' then
                            cmd       <= SPI_ADDR;
                            send_data <= SPI_DATA_IN;
                            CSn       <= '0';
                            spi_state <= w_cmd;
                        end if;

                    when w_cmd =>
                        if load_data = '1' then
                            SDIO <= cmd(bit_cnt);
                        end if;

                        if sample_data = '1' then
                            if bit_cnt = 0 then
                                bit_cnt   <= send_data'high;
                                spi_state <= rw_data;
                            else
                                bit_cnt <= bit_cnt - 1;
                            end if;
                        end if;

                    when rw_data =>
                        if load_data = '1' then 
                            SDIO <= 'Z';
                            if cmd(cmd'high) = '0' then  -- prepare data the data (to SPI device)
                                SDIO <= send_data(bit_cnt);
                            end if;
                        end if;
                        if sample_data = '1' then
                            rx_data(bit_cnt) <= SDIO;    -- sample data on the bus
                            if bit_cnt = 0 then
                                spi_state <= idle;
                            else
                                bit_cnt <= bit_cnt - 1;
                            end if;
                        end if;                   

                    when others => 
                        spi_state <= idle;
                end case;
            end if;
        end if;
    end process;

    spi_clk_proc : process(CLK)
        variable prev_state_idle : std_logic := '1';
    begin
        if rising_edge(CLK) then
            load_data   <= '0';
            sample_data <= '0';
            if (spi_state /= idle) then
                if prev_state_idle = '1' then  -- defined to optimize the time transfer
                    spi_clk   <= '0';          -- can also lead to CSn to SCLK falling edge timing violation (CLK > 200MHz)!
                    load_data <= '1';          -- force data loading on first falling edge
                    prev_state_idle := '0';
                elsif clk_cnt = 1 then
                    spi_clk <= not spi_clk;
                    clk_cnt <= CLK_DIVIDER / 2;
                    if spi_clk = '1' then      -- update/load values on falling edge
                        load_data <= '1';
                    else
                        sample_data <= '1';    -- sample data on rising edge
                    end if;
                else
                    clk_cnt <= clk_cnt - 1;
                end if; 
            else
                spi_clk <= '1';
                clk_cnt <= CLK_DIVIDER / 2;
                prev_state_idle := '1';
            end if;
        end if;
    end process;

    SPI_BUSY <= '1' when spi_state /= idle else '0';
    SCLK <= spi_clk;
    SPI_DATA_OUT <= rx_data when spi_state = idle else (others => '0');
end architecture;