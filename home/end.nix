{ config, pkgs, lib, ... }:

let
  dotfilesRoot = "${config.home.homeDirectory}/Projects/dotfiles";

  repoFile = path:
    config.lib.file.mkOutOfStoreSymlink "${dotfilesRoot}/${path}";
in
{
  home.username = "end";
  home.homeDirectory = "/home/end";

  # This pins Home Manager's migration behavior. Do not bump casually.
  home.stateVersion = "25.11";

  home.packages = with pkgs; [
    brightnessctl
    curl
    hyprlock
    jq
    playerctl
    ripgrep
    stow
    swayidle
    upower
  ];

  home.file = {
    ".config/btop/btop.conf".source = repoFile "apps/.config/btop/btop.conf";
    ".config/hypr/hyprlock.conf".source = repoFile "apps/.config/hypr/hyprlock.conf";
    ".config/mimeapps.list".source = repoFile "apps/.config/mimeapps.list";
    ".config/niri/config.kdl".source = repoFile "apps/.config/niri/config.kdl";
    ".config/pavucontrol.ini".source = repoFile "apps/.config/pavucontrol.ini";
    ".config/quickshell".source = repoFile "apps/.config/quickshell";
    ".config/starship.toml".source = repoFile "apps/.config/starship.toml";
    ".config/topgrade.toml".source = repoFile "apps/.config/topgrade.toml";
    ".config/vicinae/settings.json".source = repoFile "apps/.config/vicinae/settings.json";
    ".config/wezterm/wezterm.lua".source = repoFile "apps/.config/wezterm/wezterm.lua";
    ".config/xdg-desktop-portal/portals.conf".source = repoFile "apps/.config/xdg-desktop-portal/portals.conf";
    ".config/xdg-desktop-portal-wlr/config".source = repoFile "apps/.config/xdg-desktop-portal-wlr/config";
    ".config/zed/keymap.json".source = repoFile "apps/.config/zed/keymap.json";
    ".config/zed/settings.json".source = repoFile "apps/.config/zed/settings.json";
    ".config/zed/themes/zed.json".source = repoFile "apps/.config/zed/themes/zed.json";

    ".local/share/applications/org.wezfurlong.wezterm.desktop".source = repoFile "apps/.local/share/applications/org.wezfurlong.wezterm.desktop";

    ".config/fish/config.fish".source = repoFile "fish/.config/fish/config.fish";
    ".config/fish/conf.d/colors.fish".source = repoFile "fish/.config/fish/conf.d/colors.fish";

    ".local/bin/display-brightness".source = repoFile "apps/.local/bin/display-brightness";
    ".local/bin/hyprlock-lock".source = repoFile "apps/.local/bin/hyprlock-lock";
    ".local/bin/idle-lock-suspend".source = repoFile "apps/.local/bin/idle-lock-suspend";
    ".local/bin/location-info".source = repoFile "apps/.local/bin/location-info";
    ".local/bin/mullvad-tailscale-fix".source = repoFile "apps/.local/bin/mullvad-tailscale-fix";
    ".local/bin/quickshell-session".source = repoFile "apps/.local/bin/quickshell-session";
    ".local/bin/rfkill-airplane".source = repoFile "apps/.local/bin/rfkill-airplane";
    ".local/bin/rfkill-guard".source = repoFile "apps/.local/bin/rfkill-guard";
    ".local/bin/wallpaper".source = repoFile "apps/.local/bin/wallpaper";
    ".local/bin/wallpaper-init".source = repoFile "apps/.local/bin/wallpaper-init";
    ".local/bin/waydroid-label-desktop-entries".source = repoFile "apps/.local/bin/waydroid-label-desktop-entries";
  };

  programs.starship.enable = true;

  systemd.user.services.rfkill-guard = {
    Unit = {
      Description = "Keep WLAN unblocked after accidental rfkill events";
      After = [ "graphical-session.target" ];
    };

    Service = {
      ExecStart = "${config.home.homeDirectory}/.local/bin/rfkill-guard daemon";
      Restart = "always";
      RestartSec = 2;
    };

    Install.WantedBy = [ "default.target" ];
  };

  systemd.user.services.swayidle = {
    Unit = {
      Description = "Idle lock and suspend for niri session";
      After = [ "graphical-session.target" ];
      PartOf = [ "graphical-session.target" ];
    };

    Service = {
      ExecStart = "${pkgs.swayidle}/bin/swayidle -w timeout 900 '${config.home.homeDirectory}/.local/bin/idle-lock-suspend' before-sleep '${config.home.homeDirectory}/.local/bin/hyprlock-lock'";
      Restart = "on-failure";
      RestartSec = 2;
    };

    Install.WantedBy = [ "graphical-session.target" ];
  };

  systemd.user.startServices = "sd-switch";

  programs.home-manager.enable = true;
}
