{ pkgs, ... }:
{
  programs.alacritty = {
    enable = true;
    settings = {
      live_config_reload = true;
      font = {
        normal.family = "Source Code Pro for Powerline";
        size = 14.0;
        use_this_strokes = true;
      };
      cursor = {
        blinking = "On";
      };
      key_bindings = [
        {
          key = "I";
          mode = "Vi|~Search";
          action = "ReceiveChar";
        }
        {
          key = "Backslash";
          mods = "Control";
          chars = "\\x02\\x25";
        }
        {
          key = "Minus";
          mods = "Control";
          chars = "\\x02\\x5c";
        }
        {
          key = "T";
          mods = "Command";
          chars = "\\x02\\x63";
        }
        {
          key = "W";
          mods = "Command";
          chars = "\\x02\\x78";
        }
        {
          key = "H";
          mods = "Command";
          chars = "\\x02\\x70";
        }
        {
          key = "J";
          mods = "Command";
          chars = "\\x02\\x6a";
        }
        {
          key = "K";
          mods = "Command";
          chars = "\\x02\\x6b";
        }
        {
          key = "L";
          mods = "Command";
          chars = "\\x02\\x6c";
        }
        {
          key = "O";
          mods = "Control";
          chars = "\\x02\\x6f";
        }
      ];
    };
  };

}
