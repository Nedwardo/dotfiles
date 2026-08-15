{ pkgs, ... }:
let
  omp =
    (builtins.getFlake "github:can1357/oh-my-pi/de99219db09091dea34f70c316733dd8edc2f618")
    .packages.${pkgs.stdenv.hostPlatform.system}.omp;
in
{
  imports = [
    /etc/nixos/hardware-configuration.nix
  ];
  nixpkgs.config.allowUnfree = true;
  nix.settings.experimental-features = [
    "flakes"
    "nix-command"
  ];

  hardware.bluetooth.enable = true;

  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  boot.kernelPackages = pkgs.linuxPackages_latest;

  nix.settings.auto-optimise-store = true;
  nix.settings.download-buffer-size = 1073741824;
  nix.gc = {
    automatic = true;
    dates = "daily";
    options = "--delete-older-than 3d";
  };

  services.xserver.xkb = {
    layout = "gb";
    variant = "";
  };
  console.keyMap = "uk";

  networking.hostName = "nixos";
  networking.wireless.iwd.enable = true;
  networking.nameservers = [
    "8.8.8.8"
    "8.8.4.4"
  ];

  networking.useNetworkd = true;
  systemd.network.enable = true;
  systemd.services."systemd-networkd".environment.SYSTEMD_LOG_LEVEL = "debug";
  systemd.network.networks."40-wired" = {
    matchConfig = {
      Type = "ether";
      Driver = "!veth";
      Kind = "!veth";
    };
    networkConfig.DHCP = "yes";
    dhcpV4Config = {
      RouteMetric = 100;
    };
  };
  systemd.network.networks."40-wifi" = {
    matchConfig.Type = "wlan";
    networkConfig.DHCP = "yes";
    dhcpV4Config = {
      RouteMetric = 500;
    };
  };

  systemd.services."dummy-network-online" = {
    description = "Dummy service to activate network-online.target";
    after = [ "network-online.target" ];
    wants = [ "network-online.target" ];
    script = ":";
  };

  systemd.timers."dummy-network-online" = {
    description = "Trigger dummy-network-online shortly after boot";
    wantedBy = [ "timers.target" ];
    timerConfig = {
      OnBootSec = "0s";
    };
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
    packages =
      with pkgs;
      [
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
      ]
      ++ builtins.filter lib.attrsets.isDerivation (builtins.attrValues pkgs.nerd-fonts);

    fontconfig = {
      enable = true;
      useEmbeddedBitmaps = true;
      defaultFonts = {
        monospace = [ "Noto Mono for Powerline" ];
        sansSerif = [ "Noto Sans" ];
        serif = [ "Noto Serif" ];
        emoji = [ "Noto Color Emoji" ];
      };
    };
  };

  environment.pathsToLink = [ "/share/hypr" ];

  environment.systemPackages = with pkgs; [
    vim
    neovim
    bat-extras.batman
    wget
    firefox
    ghostty
    kitty
    basedpyright
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
    quickshell
    uwsm
    vesktop
    tldr
    nixd
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
    tree
    nixfmt
    ghostty
    shfmt
    ruff
    prettier
    luarocks
    tree-sitter
    ripgrep
    lua5_1
    lldb
    fd
    lua-language-server
    typescript-language-server
    vscode-json-languageserver
    mercurial
    stylua
    bash-language-server
    pavucontrol
    yazi
    slurp
    grim
    wayfreeze
    wl-clipboard
    killall
    brightnessctl
    pulseaudio
    iwd
    iwgtk
    karere
    dhcpcd
    python315
    go
    cargo
    btop
    jq
    playerctl
    swaynotificationcenter
    walker
    mpv
    bluetui
    eza
    vscode-extensions.vadimcn.vscode-lldb
    elephant
    omp
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
    extraGroups = [
      "networkmanager"
      "wheel"
    ];
    useDefaultShell = true;
  };

  services.getty.autologinUser = "nedwardo";

  systemd.user.services = {
    user-wait-network-online = {
      description = "Wait for system level network-online.target as user.";
      documentation = [ "https://github.com/containers/podman/issues/22197" ];
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
      wants = [ "user-wait-network-online.service" ];
      wantedBy = [ "graphical-session.target" ];
      serviceConfig.ExecStart = "${pkgs.firefox}/bin/firefox";
    };
    hexchat = {
      description = "Hexchat";
      after = [
        "graphical-session.target"
        "user-wait-network-online.service"
      ];
      wants = [ "user-wait-network-online.service" ];
      wantedBy = [ "graphical-session.target" ];
      serviceConfig.ExecStart = "${pkgs.hexchat}/bin/hexchat";
    };
    qbittorrent = {
      description = "qBittorrent";
      after = [
        "graphical-session.target"
        "user-wait-network-online.service"
      ];
      wants = [ "user-wait-network-online.service" ];
      wantedBy = [ "graphical-session.target" ];
      serviceConfig.ExecStart = "${pkgs.qbittorrent}/bin/qbittorrent";
    };
    vesktop = {
      description = "Discord";
      after = [
        "graphical-session.target"
        "user-wait-network-online.service"
      ];
      wants = [ "user-wait-network-online.service" ];
      wantedBy = [ "graphical-session.target" ];
      serviceConfig.ExecStart = "${pkgs.vesktop}/bin/vesktop";
    };
    waybar = {
      description = "Waybar";
      after = [
        "graphical-session.target"
      ];
      wantedBy = [ "graphical-session.target" ];
      serviceConfig.ExecStart = "${pkgs.waybar}/bin/waybar";
    };
    quickshell = {
      description = "Quickshell (window overview)";
      after = [
        "graphical-session.target"
      ];
      wantedBy = [ "graphical-session.target" ];
      serviceConfig = {
        ExecStart = "${pkgs.quickshell}/bin/qs -c overview";
        Restart = "on-failure";
      };
    };
    tldr = {
      description = "tldr update cache";
      wantedBy = [ "deafult.target" ];
      serviceConfig = {
        ExecStart = "tldr -u";
      };
    };
    walker = {
      description = "walker autostart";
      after = [ "graphical-session.target" ];
      wantedBy = [ "graphical-session.target" ];
      serviceConfig = {
        Type = "simple";
        ExecStart = "${pkgs.walker}/bin/walker --gapplication-service";
        Restart = "on-failure";
      };
    };
    elephant = {
      description = "Elephant data provider backend for Walker";
      wantedBy = [ "graphical-session.target" ];
      partOf = [ "graphical-session.target" ];
      serviceConfig = {
        Environment = "PATH=/run/current-system/sw/bin:/etc/profiles/per-user/%u/bin";
        ExecStart = "${pkgs.elephant}/bin/elephant";
        Restart = "on-failure";
      };
    };

    iwgtk.enable = false;
    waybar.serviceConfig.Environment = "PATH=/run/current-system/sw/bin:/etc/profiles/per-user/%u/bin";
    "app-iwgtk\\x2dindicator@autostart".enable = false;

  };

  programs.neovim = {
    enable = true;
    defaultEditor = true;
    viAlias = true;
    vimAlias = true;
    configure = {
      packages.myVimPackage = with pkgs.vimPlugins; {
        start = [
          actions-preview-nvim
          auto-session
          cmp-buffer
          cmp-nvim-lsp
          cmp-path
          cmp_luasnip
          conform-nvim
          diffview-nvim
          fidget-nvim
          friendly-snippets
          gitsigns-nvim
          indent-blankline-nvim
          lazy-nvim
          lspkind-nvim
          lualine-nvim
          luasnip
          nvim-cmp
          nvim-dap
          nvim-dap-ui
          nvim-dap-virtual-text
          nvim-lint
          nvim-lspconfig
          nvim-nio
          nvim-notify
          nvim-surround
          nvim-treesitter
          nvim-treesitter-textobjects
          plenary-nvim
          rustaceanvim
          telescope-fzf-native-nvim
          telescope-ui-select-nvim
          telescope-nvim
          tokyonight-nvim
          treewalker-nvim
          vim-matchup
          which-key-nvim
          yazi-nvim
        ];
      };
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
