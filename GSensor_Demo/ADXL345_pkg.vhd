library ieee;
use ieee.std_logic_1164.ALL;
use ieee.numeric_std.ALL;

package ADXL345_pkg is
    constant INIT_CMD_NBR  : natural := 17;

    constant WR_MODE       : std_logic := '0';
    constant RD_MODE       : std_logic := '1';
    
    constant MB_MODE       : std_logic := '1';
    constant NOT_MB_MODE   : std_logic := '0';
    
    subtype addresse_format_type is std_logic_vector(5 downto 0);
    constant DEVID         : addresse_format_type := 6x"00"; -- Device Id, should return 11100101
    constant THRESH_TAP    : addresse_format_type := 6x"1D";
    constant DUR           : addresse_format_type := 6x"21";
    constant LATENT        : addresse_format_type := 6x"22";
    constant WINDOW        : addresse_format_type := 6x"23";
    constant THRESH_ACT    : addresse_format_type := 6x"24";
    constant THRESH_INACT  : addresse_format_type := 6x"25";
    constant TIME_INACT    : addresse_format_type := 6x"26";
    constant ACT_INACT_CTL : addresse_format_type := 6x"27";
    constant THRESH_FF     : addresse_format_type := 6x"28";
    constant TIME_FF       : addresse_format_type := 6x"29";
    constant TAP_AXES      : addresse_format_type := 6x"2A";
    constant PWR_CTL       : addresse_format_type := 6x"2D"; -- PWR Control
    constant INT_ENA       : addresse_format_type := 6x"2E"; -- INT ENA
    constant INT_MAP       : addresse_format_type := 6x"2F"; -- INT MAP
    constant INT_SOURCE    : addresse_format_type := 6x"30"; -- INT Status - R only
    constant DATA_FORMAT   : addresse_format_type := 6x"31"; -- DATA FORMAT
    constant X_LB          : addresse_format_type := 6x"32"; -- Low Byte
    constant X_HB          : addresse_format_type := 6x"33"; -- High Byte
    constant Y_LB          : addresse_format_type := 6x"34"; -- Low Byte 
    constant Y_HB          : addresse_format_type := 6x"35"; -- High Byte
    constant Z_LB          : addresse_format_type := 6x"36"; -- Low Byte 
    constant Z_HB          : addresse_format_type := 6x"37"; -- High Byte

    subtype config_format_type is std_logic_vector(7 downto 0);
    constant THRESH_TAP_conf     : config_format_type := x"20";  -- 32 * 62.5mg 
    constant DUR_conf            : config_format_type := x"20";  -- 32 * 625 us    
    constant LATENT_conf         : config_format_type := x"40";  -- 64 * 1.25ms    
    constant WINDOW_conf         : config_format_type := x"F0";  -- 240 * 1.25ms   
    constant THRESH_ACT_conf     : config_format_type := x"20";  -- 32 * 62.5mg   
    constant THRESH_INACT_conf   : config_format_type := x"03";  -- < 3*62.5mg results in inactivity
    constant TIME_INACT_conf     : config_format_type := x"01";  -- 1s before declaring inactivity
    constant ACT_INACT_CTL_conf  : config_format_type := x"7F";  
    constant THRESH_FF_conf      : config_format_type := x"05";  -- free fall threshold, 450mg  
    constant TIME_FF_conf        : config_format_type := x"14";  -- 350ms before generating an interrupt   
    constant TAP_AXES_conf       : config_format_type := x"01";  -- detection on Z axis
    constant PWR_CTL_conf        : config_format_type := x"08";  -- measure mode
    constant INT_ENA_conf        : config_format_type := x"7F";  -- single tap, double tap, free_fall enabled
    constant INT_ENA_reset_conf  : config_format_type := x"00";  -- disable all interrupt source during initilization
    constant INT_MAP_conf        : config_format_type := x"64";  -- single tap, double tap, free_fall on INT2
    constant DATA_FORMAT_conf    : config_format_type := x"40";  -- 3-Wire SPI mode 
end package;