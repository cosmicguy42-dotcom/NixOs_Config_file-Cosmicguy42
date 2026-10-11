# ==============================================================================
# NixOS Configuration: configuration.nix (Hyprland Clean)
# Description: Configuration NixOS propre avec Hyprland & QuickShell Nothing
# ==============================================================================

{ config, lib, pkgs, modulesPath, inputs ? null, ... }:

let
  # Zen Browser package
  zen-browser-pkg =
    if inputs != null && inputs ? zen-browser
    then inputs.zen-browser.packages.${pkgs.stdenv.hostPlatform.system}.default
    else (import (builtins.fetchTarball "https://github.com/0xc000022070/zen-browser-flake/archive/main.tar.gz") {
      inherit pkgs;
    }).default;
in
{
  imports = [
    # Hardware detection automatique
    (modulesPath + "/installer/scan/not-detected.nix")
  ];

  _module.args.inputs = lib.mkDefault null;

  # ----------------------------------------------------------------------------
  # 1. Hardware & Kernel
  # ----------------------------------------------------------------------------
  boot.initrd.availableKernelModules = [ "xhci_pci" "ahci" "nvme" "usbhid" "usb_storage" "sd_mod" ];
  boot.initrd.kernelModules = [ ];
  boot.kernelModules = [ "kvm-intel" ];
  boot.extraModulePackages = [ ];

  # Partitions
  fileSystems."/" = {
    device = "/dev/disk/by-uuid/9bb46d78-8ce8-4287-b2c6-6fe709203908";
    fsType = "ext4";
  };

  fileSystems."/boot" = {
    device = "/dev/disk/by-uuid/C525-B702";
    fsType = "vfat";
    options = [ "fmask=0077" "dmask=0077" ];
  };

  swapDevices = [ ];
  zramSwap.enable = true;

  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
  hardware.cpu.intel.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;

  # Bluetooth
  hardware.bluetooth.enable = true;
  hardware.bluetooth.powerOnBoot = true;

  # ----------------------------------------------------------------------------
  # Accélération graphique & GPU Hybride (Intel Alder Lake + NVIDIA RTX 3050)
  # ----------------------------------------------------------------------------
  hardware.graphics = {
    enable = true;
    enable32Bit = true;
    extraPackages = with pkgs; [
      intel-media-driver
      libva-vdpau-driver
      libvdpau-va-gl
    ];
  };

  services.xserver.videoDrivers = [ "nvidia" ];

  hardware.nvidia = {
    modesetting.enable = true;
    powerManagement.enable = false;
    powerManagement.finegrained = false;
    open = false; # Pilote propriétaire officiel pour RTX 3050
    nvidiaSettings = true;
    package = config.boot.kernelPackages.nvidiaPackages.stable;

    prime = {
      offload = {
        enable = true;
        enableOffloadCmd = true;
      };
      intelBusId = "PCI:0:2:0";
      nvidiaBusId = "PCI:1:0:0";
    };
  };

  # ----------------------------------------------------------------------------
  # 2. Bootloader (UEFI / systemd-boot)
  # ----------------------------------------------------------------------------
  boot.loader.systemd-boot = {
    enable = true;
    # Limite à 5 générations dans le menu de boot pour ne plus être encombré !
    configurationLimit = 5;
  };
  boot.loader.efi.canTouchEfiVariables = true;

  # ----------------------------------------------------------------------------
  # 3. Réseau & Localisation
  # ----------------------------------------------------------------------------
  networking.hostName = "nixos";
  networking.networkmanager.enable = true;

  time.timeZone = "Europe/Paris";

  i18n.defaultLocale = "en_US.UTF-8";
  i18n.extraLocaleSettings = {
    LC_ADDRESS = "fr_FR.UTF-8";
    LC_IDENTIFICATION = "fr_FR.UTF-8";
    LC_MEASUREMENT = "fr_FR.UTF-8";
    LC_MONETARY = "fr_FR.UTF-8";
    LC_NAME = "fr_FR.UTF-8";
    LC_NUMERIC = "fr_FR.UTF-8";
    LC_PAPER = "fr_FR.UTF-8";
    LC_TELEPHONE = "fr_FR.UTF-8";
    LC_TIME = "fr_FR.UTF-8";
  };

  services.xserver.xkb = {
    layout = "fr";
    variant = "";
  };
  console.keyMap = "fr";

  # ----------------------------------------------------------------------------
  # 4. Bureau : Hyprland & Display Manager
  # ----------------------------------------------------------------------------
  programs.hyprland = {
    enable = true;
    xwayland.enable = true;
  };

  environment.sessionVariables.NIXOS_OZONE_WL = "1";

  services.displayManager.sddm = {
    enable = true;
    wayland.enable = true;
  };
  services.displayManager.defaultSession = "hyprland";

  services.blueman.enable = true;
  security.polkit.enable = true;

  xdg.portal = {
    enable = true;
    extraPortals = [
      pkgs.xdg-desktop-portal-gtk
      pkgs.xdg-desktop-portal-hyprland
    ];
  };

  services.flatpak.enable = true;

  # ----------------------------------------------------------------------------
  # 5. Audio, Alimentation & Services Système
  # ----------------------------------------------------------------------------
  services.printing.enable = true;
  services.pulseaudio.enable = false;
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
  };

  # Gestion de batterie UPower (essentiel pour QuickShell Nothing & Waybar)
  services.upower.enable = true;
  services.udisks2.enable = true;

  # ----------------------------------------------------------------------------
  # 6. Utilisateur
  # ----------------------------------------------------------------------------
  users.users."kmv22" = {
    isNormalUser = true;
    description = "KMV22";
    extraGroups = [ "networkmanager" "wheel" ];
  };

  # ----------------------------------------------------------------------------
  # 7. Paramètres Nix & Éditeur
  # ----------------------------------------------------------------------------
  nixpkgs.config.allowUnfree = true;
  nix.settings.experimental-features = [ "nix-command" "flakes" ];
  programs.nix-ld.enable = true;
  environment.localBinInPath = true;

  programs.neovim = {
    enable = true;
    defaultEditor = true;
    viAlias = true;
    vimAlias = true;
  };

  # ----------------------------------------------------------------------------
  # 8. Paquets Système
  # ----------------------------------------------------------------------------
  environment.systemPackages = with pkgs; [
    # Navigateurs
    librewolf
    zen-browser-pkg    

    # Applis
    spotify    
    discord
    steam
    qbittorrent
    obsidian
    nnn

    # Cybersécurité & Dév
    nmap
    wireshark
    gcc
    python3
    cargo
    neovim
    vscodium
    git

    # Écosystème Hyprland
    kitty
    waybar
    rofi
    wofi
    dunst
    libnotify
    swaybg
    hyprpaper
    hyprlock
    hypridle
    wl-clipboard
    grim
    slurp
    pavucontrol
    brightnessctl
    pamixer
    playerctl
    networkmanagerapplet
    kdePackages.polkit-kde-agent-1
    swaylock-effects
    waypaper

    # Fichiers
    nautilus
    kdePackages.dolphin
    kdePackages.ark
    qimgv
    yazi

    # Utilitaires CLI
    curl
    wget
    tree
    ripgrep
    fd
    jq
    which
    file
    unzip
    zip
    htop
    btop
    fastfetch
  ];

  # ----------------------------------------------------------------------------
  # 9. Polices
  # ----------------------------------------------------------------------------
  fonts.packages = with pkgs; [
    nerd-fonts.jetbrains-mono
    font-awesome
    noto-fonts
    noto-fonts-color-emoji
  ];

  # ----------------------------------------------------------------------------
  # 10. Version NixOS
  # ----------------------------------------------------------------------------
  system.stateVersion = "26.05";
}
