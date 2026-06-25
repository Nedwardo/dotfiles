# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).

{ pkgs, ... }:

{
  imports =
    [ # Include the results of the hardware scan.
      ./hardware-configuration.nix
    ];
  nixpkgs.config.allowUnfree = true;
  nix.settings.experimental-features = [ "flakes" "nix-command" ];

  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  boot.kernelPackages = pkgs.linuxPackages_latest;

  nix.settings.auto-optimise-store = true;
  nix.settings.download-buffer-size = 1073741824;
  nix.gc = {
    automatic = true;
    dates = "daily";
    options = "--delete-order-than 3d";
  };

  services.xserver.xkb = {
    layout = "gb";
    variant = "";
  };
  console.keyMap = "uk";

  networking.hostName = "nixos";
  networking.networkmanager.enable = true;
  networking.nameservers = [
    "8.8.8.8"
    "8.8.4.4"
  ];

  systemd.services."dummy-network-online" = {
    description = "Dummy service to activate network-online.target";
    after = [ "network-online.target" ];
    wants = [ "network-online.target" ];
    script = ":";
    wantedBy = [ "multi-user.target" ];
  };

  time.timeZone = "Europe/London";

  i18n.defaultLocale = "en_GB.UTF-8";
  i18n.extraLocaleSettings = {
    LC_ADDRESS = "en_GB.UTF-8";
    LC_IDENTIFICATION = "en_GB.UTF-8";
    LC_MEASUREMENT = "en_GB.UTF-8";
    LC_MONETARY = "en_GB.UTF-8";
    LC_NAME = "en_GB.UTF-8";
    LC_NUMERIC = "en_GB.UTF-8";
    LC_PAPER = "en_GB.UTF-8";
    LC_TELEPHONE = "en_GB.UTF-8";
    LC_TIME = "en_GB.UTF-8";
  };

  fonts = {
    fontDir.enable = true;
    enableDefaultPackages = true;
    packages = with pkgs; [
      dejavu_fonts
      freefont_ttf
      gyre-fonts
      liberation_ttf
      unifont
      noto-fonts-color-emoji
      corefonts
      ubuntu-classic
      powerline-fonts
      font-awesome
      source-code-pro
      noto-fonts
      noto-fonts-cjk-sans
      tree
    ]
    ++ builtins.filter lib.attrsets.isDerivation (builtins.attrValues pkgs.nerd-fonts);

    fontconfig = {
      enable = true;
      useEmbeddedBitmaps = true;
      defaultFonts = {
        monospace = [ "Noto Mono for Powerline"];
        sansSerif = [ "Noto Sans" ];
        serif = [ "Noto Serif" ];
        emoji = [ "Noto Color Emoji" ];
      };
    };
  };

  environment.systemPackages = with pkgs; [
    vim
    neovim
    bat-extras.batman
    wget
    firefox
    alacritty
    stow
    git
    zinit
    oh-my-posh
    fzf
    readline70
    gcc
    gnumake
    bat
    waybar
    rofi
    uwsm
    vesktop
    tldr
    nixd
    rustup
    mise
    rustup
    lua
    zoxide
    qbittorrent
    xdg-desktop-portal-gtk
    adw-gtk3
    adwaita-icon-theme
    adwaita-qt
    adwaita-qt6
    gnome-themes-extra
    qt5.qtwayland
    qt6.qtwayland
    qt6Packages.qt6ct
    libsForQt5.qt5ct
    rose-pine-hyprcursor
    hexchat
  ];

  services.avahi = {
    enable = true;
    nssmdns4 = true;
    openFirewall = true;
  };
  
  services.printing = {
    enable = true;
    drivers = with pkgs; [
      cups-filters
      cups-browsed
    ];
  };

  services.openssh.enable = true;

  programs.hyprland = {
    enable = true;
    withUWSM = true;
  };

  programs.zsh = {
  enable = true;
  interactiveShellInit = ''
    ZINIT_HOME="${pkgs.zinit}/share/zinit"
  '';
  };

  users.defaultUserShell = pkgs.zsh;
  users.users.nedwardo = {
    isNormalUser = true;
    description = "nedwardo";
    extraGroups = [ "networkmanager" "wheel" ];
    useDefaultShell = true;
  };

  services.getty.autologinUser = "nedwardo";

  systemd.user.services = {
    user-wait-network-online = {
      description = "Wait for system level network-online.target as user.";
      documentation = ["https://github.com/containers/podman/issues/22197"];
      serviceConfig = { 
        Type = "oneshot"; 
	TimeoutStartSec = "90s";
	ExecStart = "/bin/sh -c 'until systemctl is-active network-online.target; do sleep 0.5; done'";
	RemainAfterExit = "yes";
      };
    };
    firefox = {
      description = "Firefox";
      after = [
        "graphical-session.target"
	"user-wait-network-online.service"
      ];
      wants = ["user-wait-network-online.service"];
      wantedBy = ["graphical-session.target"];
      serviceConfig.ExecStart = "${pkgs.firefox}/bin/firefox";
    };
    hexchat = {
      description = "Hexchat";
      after = [
        "graphical-session.target"
	"user-wait-network-online.service"
      ];
      wants = ["user-wait-network-online.service"];
      wantedBy = ["graphical-session.target"];
      serviceConfig.ExecStart = "${pkgs.hexchat}/bin/hexchat";
    };
    qbittorrent = {
      description = "qBittorrent";
      after = [
        "graphical-session.target"
	"user-wait-network-online.service"
      ];
      wants = ["user-wait-network-online.service"];
      wantedBy = ["graphical-session.target"];
      serviceConfig.ExecStart = "${pkgs.qbittorrent}/bin/qbittorrent";
    };
    vesktop = {
      description = "Discord";
      after = [
        "graphical-session.target"
	"user-wait-network-online.service"
      ];
      wants = ["user-wait-network-online.service"];
      wantedBy = ["graphical-session.target"];
      serviceConfig.ExecStart = "${pkgs.vesktop}/bin/vesktop";
    };
    waybar = {
      description = "Waybar";
      after = [
        "graphical-session.target"
      ];
      wantedBy = ["graphical-session.target"];
      serviceConfig.ExecStart = "${pkgs.waybar}/bin/waybar";
    };
    
  };

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "25.11"; # Did you read the comment?
}
