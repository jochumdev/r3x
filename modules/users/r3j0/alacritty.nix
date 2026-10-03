{
  ...
}:
{
  users.r3j0.alacritty = {
    homeManager = {
      programs.alacritty = {
        enable = true;
        settings = {
          font = {
            normal = {
              family = "UDEV Gothic 35NFLG";
              style = "Regular";
            };
            bold = {
              family = "UDEV Gothic 35NFLG";
              style = "Bold";
            };
            bold_italic = {
              family = "UDEV Gothic 35NFLG";
              style = "BoldItalic";
            };
            italic = {
              family = "UDEV Gothic 35NFLG";
              style = "Italic";
            };
            size = 12;
          };
          env = {
            TERM = "xterm-256color";
          };
          colors = {
            primary = {
              background = "#0A0E14";
              foreground = "#B3B1AD";
            };
            normal = {
              black = "#01060E";
              red = "#EA6C73";
              green = "#91B362";
              yellow = "#F9AF4F";
              blue = "#53BDFA";
              magenta = "#FAE994";
              cyan = "#90E1C6";
              white = "#C7C7C7";
            };
            bright = {
              black = "#686868";
              red = "#F07178";
              green = "#C2D94C";
              yellow = "#FFB454";
              blue = "#59C2FF";
              magenta = "#FFEE99";
              cyan = "#95E6CB";
              white = "#FFFFFF";
            };
          };
        };
      };
    };
  };
}
