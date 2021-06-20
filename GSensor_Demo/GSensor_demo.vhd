library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
library work;
use work.ADXL345_pkg.all;

entity GSensor_demo is
    generic (
        INPUT_CLK_MHz    : natural := 50
    );
    port (
        ADC_CLK_10    :    in std_logic;
        MAX10_CLK1_50 :    in std_logic;
        MAX10_CLK2_50 :    in std_logic;

        --GSENSOR_SDO   : inout std_logic;
        GSENSOR_INT   :    in std_logic_vector(1 downto 0);
        GSENSOR_CS_N  :   out std_logic := '0';
        GSENSOR_SDI   : inout std_logic := '0';
        GSENSOR_SCLK  :   out std_logic := '0';

        LEDR          :   out std_logic_vector(9 downto 0);
        KEY           :    in std_logic_vector(1 downto 0)
    );
end GSensor_demo;

architecture rtl of GSensor_demo is
    alias nrst  : std_logic is KEY(0);
    
    -- Signal to trigger the SPI acquisiton
    signal trigger_sampling  : std_logic := '0';
    
    -- SPI signals 
    signal spi_start   : std_logic := '0';
    signal spi_isbusy  : std_logic;
    signal spi_addr    : std_logic_vector(7 downto 0) := (others => '0');
    signal spi_dat_in  : std_logic_vector(7 downto 0) := (others => '0');
    signal spi_dat_out : std_logic_vector(7 downto 0);
    
    -- SPI signals used for the initialization steps
    signal spi_init_addr   : std_logic_vector(7 downto 0) := (others => '0');
    signal spi_init_dat_in : std_logic_vector(7 downto 0) := (others => '0');

    -- Used to go trough the defined initialization
    signal init_cnt   : natural range 0 to INIT_CMD_NBR;

    -- FSM for the ADXL communication
    type adxl_state_type is (idle, transfer, delayCSn);
    signal adxl_state : adxl_state_type := idle;

    signal isHighByte : std_logic := '0';
    signal X_value    : std_logic_vector(15 downto 0) := (others => '0');

    -- Counter to respect the tcs,dis timing, p.17 datasheet (min 150ns)
    signal delayCsn_cnt : natural range 0 to INPUT_CLK_MHz*1000000 / (1000000000/150) := 0;

    -- interrupt register
    signal getIntStatus : std_logic := '0';
    signal freefall     : std_logic := '0';
    signal singletap    : std_logic := '0';
    signal doubletap    : std_logic := '0';
begin

    trigger_1ms : entity work.trigger_generator(rtl)
	 generic map (
        INPUT_CLK_MHz    => 50,
        TRIGGER_FREQ_Hz  => 50
    )
    port map (
        CLK   => MAX10_CLK1_50,
        nRST  => nrst,
        OUT_PULS => trigger_sampling
    );

	spi_ctl : entity work.SPI_3W(rtl)
    port map (
        CLK          => MAX10_CLK1_50,
        RESETn       => nrst,

        SPI_START    => spi_start,
        SPI_ADDR     => spi_addr,
        SPI_DATA_IN  => spi_dat_in,
        SPI_DATA_OUT => spi_dat_out,
        SPI_BUSY     => spi_isbusy,

        SDIO         => GSENSOR_SDI,
        CSn          => GSENSOR_CS_N,
        SCLK         => GSENSOR_SCLK
    );

    ADXL_PROC : process(MAX10_CLK1_50)
        variable spi_isbusy_prev : std_logic := '0';
        variable interrupt_prev  : std_logic := '0';
    begin
        if rising_edge(MAX10_CLK1_50) then
            if (nrst = '0') then
                adxl_state   <= idle;
                init_cnt     <= 0;
                delayCsn_cnt <= 0;
                getIntStatus <= '0';
                singletap    <= '0';
                doubletap    <= '0';
                freefall     <= '0';
            else
                spi_start <= '0';

                if init_cnt < INIT_CMD_NBR then
                    case adxl_state is          
                        when idle =>
                            spi_addr   <= spi_init_addr;
                            spi_dat_in <= spi_init_dat_in;
                            init_cnt   <= init_cnt + 1;
                            adxl_state <= transfer;
                            spi_start  <= '1';
                            
                        when transfer => 
                            if spi_isbusy_prev = '1' and spi_isbusy = '0' then  -- wait falling edge on the spi_isbusy
                                adxl_state <= delayCsn;
                            end if;

                        when delayCSn =>
                            if delayCsn_cnt = delayCsn_cnt'high - 1 then
                                adxl_state   <= idle;
                                delayCsn_cnt <= 0;
                            else
                                delayCsn_cnt <= delayCsn_cnt + 1;
                            end if;
                    
                        when others =>
                            adxl_state <= idle;
                    end case;
                else
                    case adxl_state is 
                        when idle =>
                            if (GSENSOR_INT(1) = '1' and interrupt_prev = '0') or
                               (GSENSOR_INT(1) = '1' and trigger_sampling = '1') then -- rising edge on the interrupt line
                                spi_addr     <= RD_mode & NOT_MB_MODE & INT_SOURCE;
                                spi_start    <= '1';
                                adxl_state   <= transfer;
                                getIntStatus <= '1';
                            elsif trigger_sampling = '1' then
                                isHighByte <= '0';
                                spi_addr   <= RD_mode & NOT_MB_MODE & X_LB;
                                spi_start  <= '1';
                                adxl_state <= transfer;
                            end if;

                        when transfer =>
                            if spi_isbusy_prev = '1' and spi_isbusy = '0' then -- falling edge on the spi_isbusy
                                if getIntStatus = '1' then
                                    getIntStatus <= '0';
                                    if spi_dat_out(6) = '1' then
                                        singletap <= not singletap;
                                    end if;
                                    if spi_dat_out(5) = '1' then
                                        doubletap <= not doubletap;
                                    end if;
                                    if spi_dat_out(2) = '1' then
                                        freefall <= not freefall;
                                    end if;
                                    adxl_state <= idle;
                                elsif isHighByte = '0' then
                                    X_value(7 downto 0) <= spi_dat_out;
                                    isHighByte <= '1';
                                    spi_addr   <= RD_mode & NOT_MB_MODE & X_HB;
                                    adxl_state <= delayCSn;
                                else 
                                    X_value(15 downto 8) <= spi_dat_out;
                                    adxl_state <= idle;
                                end if;
                            end if;
                        
                        when delayCSn =>
                            if delayCsn_cnt = delayCsn_cnt'high - 1 then
                                spi_start    <= '1';
                                adxl_state   <= transfer;
                                delayCsn_cnt <= 0;
                            else
                                delayCsn_cnt <= delayCsn_cnt + 1;
                            end if;

                        when others =>
                            adxl_state <= idle;
                    end case;
                end if;
            end if;

            spi_isbusy_prev := spi_isbusy;
            interrupt_prev  := GSENSOR_INT(1);
        end if;
    end process;

    init_adxl : process(MAX10_CLK1_50)
    begin
        if rising_edge(MAX10_CLK1_50) then
            case init_cnt is
                when 0 =>
                    spi_init_addr   <= WR_MODE & NOT_MB_MODE & INT_ENA;
                    spi_init_dat_in <= INT_ENA_reset_conf;
                when 1 =>
                    spi_init_addr   <= WR_MODE & NOT_MB_MODE & THRESH_TAP;
                    spi_init_dat_in <= THRESH_TAP_conf;
                when 2 =>
                    spi_init_addr   <= WR_MODE & NOT_MB_MODE & DUR;
                    spi_init_dat_in <= DUR_conf;
                when 3 =>
                    spi_init_addr   <= WR_MODE & NOT_MB_MODE & LATENT;
                    spi_init_dat_in <= LATENT_conf;
                when 4 =>
                    spi_init_addr   <= WR_MODE & NOT_MB_MODE & WINDOW;
                    spi_init_dat_in <= WINDOW_conf;
                when 5 =>
                    spi_init_addr   <= WR_MODE & NOT_MB_MODE & THRESH_ACT;
                    spi_init_dat_in <= THRESH_ACT_conf;
                when 6 =>
                    spi_init_addr   <= WR_MODE & NOT_MB_MODE & THRESH_INACT;
                    spi_init_dat_in <= THRESH_INACT_conf;
                when 7 =>
                    spi_init_addr   <= WR_MODE & NOT_MB_MODE & TIME_INACT;
                    spi_init_dat_in <= TIME_INACT_conf;
                when 8 =>
                    spi_init_addr   <= WR_MODE & NOT_MB_MODE & ACT_INACT_CTL;
                    spi_init_dat_in <= ACT_INACT_CTL_conf;
                when 9 =>
                    spi_init_addr   <= WR_MODE & NOT_MB_MODE & THRESH_FF;
                    spi_init_dat_in <= THRESH_FF_conf;
                when 10 =>
                    spi_init_addr   <= WR_MODE & NOT_MB_MODE & TIME_FF;
                    spi_init_dat_in <= TIME_FF_conf;
                when 11 =>
                    spi_init_addr   <= WR_MODE & NOT_MB_MODE & TAP_AXES;
                    spi_init_dat_in <= TAP_AXES_conf;
                when 12 =>
                    spi_init_addr   <= WR_MODE & NOT_MB_MODE & INT_MAP;
                    spi_init_dat_in <= INT_MAP_conf;
                when 13 =>
                    spi_init_addr   <= WR_MODE & NOT_MB_MODE & DATA_FORMAT;
                    spi_init_dat_in <= DATA_FORMAT_conf;
                when 14 =>
                    spi_init_addr   <= RD_MODE & NOT_MB_MODE & INT_SOURCE;  -- reset the interrupt status before INT_ENA
                    spi_init_dat_in <= (others => '0');
                when 15 =>
                    spi_init_addr   <= WR_MODE & NOT_MB_MODE & INT_ENA;
                    spi_init_dat_in <= INT_ENA_conf;
                when 16 => 
                    spi_init_addr   <= WR_MODE & NOT_MB_MODE & PWR_CTL;
                    spi_init_dat_in <= PWR_CTL_conf;
                when others =>
                    null; 
            end case;
        end if;
    end process;

    LEDR <= singletap & doubletap & freefall & X_value(7 downto 1);

end architecture;