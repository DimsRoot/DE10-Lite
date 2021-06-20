library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity trigger_generator is
    generic (
        INPUT_CLK_MHz    : natural := 50;
        TRIGGER_FREQ_Hz  : natural := 1
    );
    port (
        CLK      :  in std_logic;
        nRST     :  in std_logic;

        OUT_PULS : out std_logic := '0'
    );
end trigger_generator;

architecture rtl of trigger_generator is
    signal clk_cnt : natural range 0 to INPUT_CLK_MHz * 1000000 / TRIGGER_FREQ_Hz;
begin
    CLK_DIV_PROC : process(CLK)
    begin
        if rising_edge(CLK) then
            OUT_PULS <= '0';
            if nRST = '0' then
                clk_cnt <= 0;
            else 
                clk_cnt <= clk_cnt + 1;
                if  clk_cnt = clk_cnt'high - 1 then
                    clk_cnt  <= 0;
                    OUT_PULS <= '1';
                end if;
            end if;
        end if;
    end process;

end architecture;