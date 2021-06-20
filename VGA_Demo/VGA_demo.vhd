library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
library work;
use work.VGA_pkg.all;

entity VGA_DEMO is
  port (
    ADC_CLK_10    :  in std_logic;
    MAX10_CLK1_50 :  in std_logic;
    MAX10_CLK2_50 :  in std_logic;

    VGA_R         : out std_logic_vector(3 downto 0) := (others => '0');
    VGA_G         : out std_logic_vector(3 downto 0) := (others => '0');
    VGA_B         : out std_logic_vector(3 downto 0) := (others => '0');
    VGA_HS        : out std_logic := '1';
    VGA_VS        : out std_logic := '1';
    
    KEY           :  in std_logic_vector(1 downto 0)
  );
end VGA_DEMO;

architecture rtl of VGA_DEMO is
  alias nrst        : std_logic is KEY(0);

  signal PX_VGA_clk : std_logic := '0';

  -- Pixel counter
  signal PX_HS_cnt       : natural range 0 to HS_WHOLE_LINE_PX := 0;
  signal PX_VS_cnt       : natural range 0 to VS_WHOLE_LINE_PX := 0;

  signal disp_data     : std_logic := '0';
  signal disp_h_px_cnt : natural range 0 to HS_VISIBLE_AREA_PX := 0;
  signal disp_v_px_cnt : natural range 0 to VS_VISIBLE_AREA_PX := 0;
  signal frame_cnt     : natural range 0 to 240;

  signal RGB_data   : std_logic_vector(11 downto 0);

begin

  VGA_PLL_inst : entity work.VGA_PLL(SYN)
  port map (
		inclk0	 => MAX10_CLK1_50,
		c0	 => PX_VGA_clk
	);

  -- Pixel counter (horizontal) and line counter (vertical)
  PX_CNT_PROC : process(PX_VGA_clk)
  begin
    if rising_edge(PX_VGA_clk) then
      if nrst = '0' then
        PX_HS_cnt <= 0;
        PX_VS_cnt <= 0;
        disp_h_px_cnt <= 0;
        disp_v_px_cnt <= 0;
        frame_cnt     <= 0;
      else
        -- counter for the whole image
        PX_HS_cnt <= PX_HS_cnt + 1;
        if PX_HS_cnt = HS_WHOLE_LINE_PX - 1 then
          PX_HS_cnt <= 0;
          PX_VS_cnt <= PX_VS_cnt + 1;
          if PX_VS_cnt = VS_WHOLE_LINE_PX - 1 then
            PX_VS_cnt <= 0;
          end if;
        end if;

        -- counter for the visible image (640*480)
        if disp_data = '1' then
          disp_h_px_cnt <= disp_h_px_cnt + 1;
          if disp_h_px_cnt = HS_VISIBLE_AREA_PX - 1 then
            disp_h_px_cnt <= 0;
            disp_v_px_cnt <= disp_v_px_cnt + 1;
            if disp_v_px_cnt = VS_VISIBLE_AREA_PX - 1 then
              disp_v_px_cnt <= 0;
              frame_cnt     <= frame_cnt + 1;
            end if;
          end if;
        else
        disp_h_px_cnt <= 0;
        end if;
      end if;
    end if;
  end process;

  HS_VS_PROC : process(PX_VGA_clk)
  begin
    if rising_edge(PX_VGA_clk) then
      VGA_HS <= '1';
      VGA_VS <= '1';
      if nrst = '0' then
        VGA_HS <= '1';
        VGA_VS <= '1';
      else
        if PX_HS_cnt < HS_SYNC_PULSE_PX then
          VGA_HS <= '0';
        end if;
        if PX_VS_cnt < VS_SYNC_PULSE_PX then
          VGA_VS <= '0';
        end if;
      end if;
    end if;
  end process;

  BLANK_PROC : process(PX_VGA_clk)
  begin
    if rising_edge(PX_VGA_clk) then
      if nrst = '0' then
        disp_data <= '0';
      else
        disp_data   <= '1';
        if PX_HS_cnt < HS_SYNC_PULSE_PX + HS_BACK_PORCH_PX or 
           PX_HS_cnt > HS_WHOLE_LINE_PX - HS_FRONT_PORCH_PX then
          disp_data   <= '0';
        elsif PX_VS_cnt < VS_SYNC_PULSE_PX + VS_BACK_PORCH_PX or 
           PX_VS_cnt >= VS_WHOLE_LINE_PX - VS_FRONT_PORCH_PX then
          disp_data   <= '0';
        end if;
      end if;
    end if;
  end process;

  DISP_PROC : process(PX_VGA_clk)
  begin
    if rising_edge(PX_VGA_clk) then
      if nrst = '0' then
        RGB_data <= (others => '0');
      else
        if disp_data = '1' then
          if frame_cnt > 120 then  -- display french flag
            if disp_h_px_cnt < 214 then
              RGB_data <= x"00F";
            elsif disp_h_px_cnt < 428 then
              RGB_data <= x"FFF";
            else
              RGB_data <= x"F00";
            end if;
          else                     -- display german flag
            if disp_v_px_cnt < 160 then
              RGB_data <= x"000";
            elsif disp_v_px_cnt < 320 then
              RGB_data <= x"F00";
            else
              RGB_data <= x"FF0";
            end if;
          end if;
        else 
          RGB_data <= (others => '0');
        end if;
      end if;
    end if;
  end process;

  VGA_R <= RGB_data(11 downto 8);
  VGA_G <= RGB_data(7 downto 4);
  VGA_B <= RGB_data(3 downto 0);

end architecture;