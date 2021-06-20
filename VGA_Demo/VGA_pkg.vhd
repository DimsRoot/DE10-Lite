package VGA_PKG is
  -- package for the VGA 640 x 480 @ 60Hz
  -- Data from:  http://tinyvga.com/vga-timing/640x480@60Hz

  -- Horizontal timing specification
  constant HS_VISIBLE_AREA_PX : natural := 640;
  constant HS_FRONT_PORCH_PX  : natural := 16;
  constant HS_SYNC_PULSE_PX   : natural := 96;  -- active low
  constant HS_BACK_PORCH_PX   : natural := 48;
  constant HS_WHOLE_LINE_PX   : natural := 800;
  
  -- Verical timing specification
  constant VS_VISIBLE_AREA_PX : natural := 480;
  constant VS_FRONT_PORCH_PX  : natural := 10;
  constant VS_SYNC_PULSE_PX   : natural := 2;   -- active low
  constant VS_BACK_PORCH_PX   : natural := 33;
  constant VS_WHOLE_LINE_PX   : natural := 525;

end package;

--package body VGA_PKG is

--end package body;