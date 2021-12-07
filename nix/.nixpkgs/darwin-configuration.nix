{ config, pkgs, ... }:
let
  home = builtins.getEnv "HOME";
in
{
  system.defaults = {
    loginwindow = {
      GuestEnabled = false;
    };

    finder = {
      AppleShowAllExtensions = true;
      FXEnableExtensionChangeWarning = false;
      QuitMenuItem = true;
      _FXShowPosixPathInTitle = true;
    };

    trackpad = {
      ActuationStrength = 0;
      Clicking = true;
    };

    dock = {
      autohide = false;
      tilesize = 30;
      mru-spaces = false;
      show-recents = false;
    };

    NSGlobalDomain = {
      "com.apple.sound.beep.feedback" = 0;
      "com.apple.sound.beep.volume" = "0.000";
      "com.apple.swipescrolldirection" = false;

      ApplePressAndHoldEnabled = false;
      AppleShowAllExtensions = true;
      AppleShowScrollBars = "Always";
      NSAutomaticCapitalizationEnabled = false;
      NSAutomaticDashSubstitutionEnabled = false;
      NSAutomaticPeriodSubstitutionEnabled = false;
      NSAutomaticQuoteSubstitutionEnabled = false;
      NSAutomaticSpellingCorrectionEnabled = false;
      NSDisableAutomaticTermination = true;
      NSDocumentSaveNewDocumentsToCloud = false;
      NSNavPanelExpandedStateForSaveMode = true;
      NSNavPanelExpandedStateForSaveMode2 = true;
      PMPrintingExpandedStateForPrint = true;
      PMPrintingExpandedStateForPrint2 = true;
    };

    LaunchServices.LSQuarantine = false;
  };



  # Auto upgrade nix package and the daemon service.
  # services.nix-daemon.enable = true;
  # nix.package = pkgs.nix;

  nix.extraOptions = ''
    extra-platforms = aarch64-darwin x86_64-darwin
    system = aarch64-darwin
  '';

  # Create /etc/bashrc that loads the nix-darwin environment.
  programs.zsh.enable = true; # default shell on catalina
  # programs.fish.enable = true;

  # Used for backwards compatibility, please read the changelog before changing.
  # $ darwin-rebuild changelog
  system.stateVersion = 4;



  environment.systemPackages = [
    pkgs.xcode-install
    pkgs.skhd
    pkgs.alacritty
  ];

  homebrew = {
    enable = true;
    autoUpdate = true;
    brewPrefix = "/opt/homebrew/bin";
    extraConfig = ''
      tap "yassinebridi/formulae", "https://github.com/yassinebridi/homebrew-formulae.git"
      brew "yassinebridi/formulae/yabai", args: ["HEAD"]
      tap "dbt-labs/dbt"
      brew "dbt"
      brew "borgbackup"
      brew "neomutt"
      brew "azure-cli"
      cask "ubersicht"
      cask "raycast"
      cask "vorta"
      cask "iterm2"
      brew "koekeishiya/formulae/skhd"

    '';

  };

  services.yabai = {
    enable = true;
    package = builtins.path {
      path = /opt/homebrew;
      filter = (path: type: type == "directory" || builtins.baseNameOf path == "yabai");
    };
    enableScriptingAddition = true;
    config = {
      active_window_border_color = "0xff5c7e81";
      active_window_border_topmost = "off";
      active_window_opacity = "1.0";
      auto_balance = "on";
      bottom_padding = 5;
      focus_follows_mouse = "off";
      insert_window_border_color = "0xffd75f5f";
      layout = "bsp";
      left_padding = 0;
      mouse_action1 = "move";
      mouse_action2 = "resize";
      mouse_follows_focus = "off";
      mouse_modifier = "fn";
      normal_window_border_color = "0xff505050";
      normal_window_opacity = "1.0";
      right_padding = 0;
      split_ratio = "0.50";
      top_padding = 26;
      window_border = "on";
      window_border_placement = "inset";
      window_border_radius = 3;
      window_border_width = 2;
      window_gap = 0;
      window_opacity = "off";
      window_opacity_duration = "0.0";
      window_placement = "second_child";
      window_shadow = "float";
      window_topmost = "on";
    };


    extraConfig = ''
        # rules
        yabai -m signal --add event=dock_did_restart action="sudo yabai --load-sa"
        yabai -m rule --add app='System Preferences' manage=off
        yabai -m config external_bar all:0:$SPACEBAR_HEIGHT
        yabai -m config window_topmost on


      # Any other arbitrary config here
    '';
  };

  services.skhd = {
    enable = true;
    package = pkgs.skhd;
    skhdConfig = ''

      alt - f : yabai -m window --toggle zoom-fullscreen
      cmd - return : yabai -m space --rotate 90

      cmd - left : yabai -m window --focus west || yabai -m display --focus west
      cmd - right : yabai -m window --focus east || yabai -m display --focus east
      cmd - up : yabai -m window --focus north || yabai -m display --focus north
      cmd - down : yabai -m window --focus south || yabai -m display --focus south


      shift + cmd - left : \
        yabai -m window --warp west || \
        (yabai -m window --display west && \
          yabai -m display --focus west && \
          yabai -m window focus recent)

      shift + cmd - right : \
        yabai -m window --warp east || \
        (yabai -m window --display east && \
          yabai -m display --focus east && \
          yabai -m window focus recent)


      ctrl + cmd - up : yabai -m space --focus next || yabai -m space --focus first
      shift + ctrl + cmd - up : \
        index=$(yabai -m query --windows --window | jq ".id") && \
        (yabai -m window --space next || yabai -m window --space first) && \
        yabai -m window --focus $index

      ctrl + cmd - down : yabai -m space --focus prev || yabai -m space --focus last
      shift + ctrl + cmd - down : \
        index=$(yabai -m query --windows --window | jq ".id") && \
        (yabai -m window --space prev || yabai -m window --space last) && \
        yabai -m window --focus $index

    '';
  };

  security.accessibilityPrograms = [ "${config.services.yabai.package}/bin/yabai" ];

  users = {
    users.mattniedelman = {
      name = "mattniedelman";
      home = "/Users/mattniedelman";
    };
  };

  nix.nixPath = {
    hm-config = "${home}/.config/nixpkgs/home.nix";
  };

  imports = [
    <home-manager/nix-darwin>
  ];

  home-manager = {
    useGlobalPkgs = true;
    users.mattniedelman = import "/Users/mattniedelman/.config/nixpkgs/home.nix";
  };

}
