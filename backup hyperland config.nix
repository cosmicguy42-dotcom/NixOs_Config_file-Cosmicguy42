# ==============================================================================
# NixOS Configuration: hyperland-configV3-NixOS.nix
# Description: Complete standalone NixOS configuration featuring:
#              - Hyprland Wayland Compositor & ecosystem (Waybar, Rofi, Kitty, Dunst)
#              - Essential CLI tools & utilities (Git, curl, wget, ripgrep, etc.)
#              - Neovim (default editor) & VSCodium (Vim removed)
#              - Zen Browser, LibreWolf & Firefox
#              - Hybrid Graphics Acceleration (Intel Alder Lake + NVIDIA RTX 3050)
# ==============================================================================

{ config, lib, pkgs, modulesPath, inputs ? null, ... }:

let
  # Zen Browser package from flake input if provided, otherwise fetchTarball
  zen-browser-pkg =
    if inputs != null && inputs ? zen-browser
    then inputs.zen-browser.packages.${pkgs.stdenv.hostPlatform.system}.default
    else (import (builtins.fetchTarball "https://github.com/0xc000022070/zen-browser-flake/archive/main.tar.gz") {
      inherit pkgs;
    }).default;
in
{
  imports = [
    # Automatically detected hardware modules (do not remove)
    (modulesPath + "/installer/scan/not-detected.nix")
  ];

  # Provide default for inputs so this file can be built both with and without Flakes
  _module.args.inputs = lib.mkDefault null;

  # ----------------------------------------------------------------------------
  # 1. Hardware & Kernel Configuration
  # ----------------------------------------------------------------------------
  boot.initrd.availableKernelModules = [ "xhci_pci" "ahci" "nvme" "usbhid" "usb_storage" "sd_mod" ];
  boot.initrd.kernelModules = [ ];
  boot.kernelModules = [ "kvm-intel" ];
  boot.extraModulePackages = [ ];

  # Root Filesystem (ext4)
  fileSystems."/" = {
    device = "/dev/disk/by-uuid/9bb46d78-8ce8-4287-b2c6-6fe709203908";
    fsType = "ext4";
  };

  # EFI Boot Partition (vfat)
  fileSystems."/boot" = {
    device = "/dev/disk/by-uuid/C525-B702";
    fsType = "vfat";
    options = [ "fmask=0077" "dmask=0077" ];
  };

  swapDevices = [ ];
  zramSwap.enable = true;

  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
  hardware.cpu.intel.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;

  # Bluetooth support
  hardware.bluetooth.enable = true;
  hardware.bluetooth.powerOnBoot = true;

  # ----------------------------------------------------------------------------
  # Accélération graphique & GPU Hybride (Intel Alder Lake + NVIDIA RTX 3050)
  # ----------------------------------------------------------------------------
  hardware.graphics = {
    enable = true;
    enable32Bit = true;
    extraPackages = with pkgs; [
      intel-media-driver   # Décodage matériel VA-API pour ton i5-12450H (Alder Lake)
      libva-vdpau-driver
      libvdpau-va-gl
    ];
  };

  # Charger le pilote propriétaire NVIDIA officiel (remplace nouveau)
  services.xserver.videoDrivers = [ "nvidia" ];

  hardware.nvidia = {
    modesetting.enable = true;
    powerManagement.enable = false;
    powerManagement.finegrained = false;
    open = false; # Pilote propriétaire officiel (recommandé et stable sur RTX 3050)
    nvidiaSettings = true;
    package = config.boot.kernelPackages.nvidiaPackages.stable;

    # Mode Hybride (PRIME Offload) :
    # - Hyprland, Zen Browser et LibreWolf tournent sur l'iGPU Intel (0 lag, 4K fluide, batterie préservée)
    # - La RTX 3050 reste en veille et ne s'allume que si tu lances une appli avec 'nvidia-offload'
    prime = {
      offload = {
        enable = true;
        enableOffloadCmd = true;
      };
      # Adresses PCI exactes de ta machine :
      intelBusId = "PCI:0:2:0";
      nvidiaBusId = "PCI:1:0:0";
    };
  };

  # ----------------------------------------------------------------------------
  # 2. Bootloader (UEFI / systemd-boot)
  # ----------------------------------------------------------------------------
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  # ----------------------------------------------------------------------------
  # 3. Networking
  # ----------------------------------------------------------------------------
  networking.hostName = "nixos";
  networking.networkmanager.enable = true;

  # ----------------------------------------------------------------------------
  # 4. Localization, Timezone & Keyboard
  # ----------------------------------------------------------------------------
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

  # Keyboard layout (French AZERTY)
  services.xserver.xkb = {
    layout = "fr";
    variant = "";
  };
  console.keyMap = "fr";

  # ----------------------------------------------------------------------------
  # 5. Desktop Environment: Hyprland & Display Manager
  # ----------------------------------------------------------------------------
  # Enable Hyprland dynamic tiling Wayland compositor
  programs.hyprland = {
    enable = true;
    xwayland.enable = true;
  };

  # Hint Electron and Chromium apps to use Wayland natively
  environment.sessionVariables.NIXOS_OZONE_WL = "1";

  # SDDM Display / Login Manager
  services.displayManager.sddm = {
    enable = true;
    wayland.enable = true;
  };
  services.displayManager.defaultSession = "hyprland";

  # Bluetooth management GUI service (blueman-applet)
  services.blueman.enable = true;

  # Security / Polkit authentication
  security.polkit.enable = true;

  # XDG Portals (ensures file picker & desktop integration work in Wayland apps)
  xdg.portal = {
    enable = true;
    extraPortals = [ pkgs.xdg-desktop-portal-gtk ];
  };

  # Flatpak support
  services.flatpak.enable = true;

  # ----------------------------------------------------------------------------
  # 6. Audio & Printing (PipeWire)
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

  # ----------------------------------------------------------------------------
  # 7. User Accounts
  # ----------------------------------------------------------------------------
  users.users."kmv22" = {
    isNormalUser = true;
    description = "KMV22";
    extraGroups = [ "networkmanager" "wheel" ];
  };

  # ----------------------------------------------------------------------------
  # 8. Nix & Package Management Settings
  # ----------------------------------------------------------------------------
  nixpkgs.config.allowUnfree = true;
  nix.settings.experimental-features = [ "nix-command" "flakes" ];
  programs.nix-ld.enable = true;
  environment.localBinInPath = true;

  # ----------------------------------------------------------------------------
  # 9. Editor Preferences (Neovim default, Vim removed)
  # ----------------------------------------------------------------------------
  programs.neovim = {
    enable = true;
    defaultEditor = true;
    viAlias = true;
    vimAlias = true;
  };

  # ----------------------------------------------------------------------------
  # 10. System Packages
  # ----------------------------------------------------------------------------
  environment.systemPackages = with pkgs; [
    # --- Web Browsers ---
    librewolf
    zen-browser-pkg    

    # --- Cool things ---
    spotify    
    discord
    steam
    qbittorrent
    obsidian
    nnn

    # --- Cybersecurity ---
    nmap
    wireshark
    
    # --- Compilator ---
    gcc
    python3
    cargo
    

    # --- Code & Text Editors ---
    neovim
    vscodium

    # --- Version Control ---
    git

    # --- Hyprland Desktop Ecosystem ---
    kitty                    # Default terminal for Hyprland
    waybar                   # Highly customizable Wayland top/bottom bar
    rofi                     # Modern application launcher & window switcher
    wofi                     # Alternative Wayland app launcher
    dunst                    # Lightweight notification daemon
    libnotify                # Notification sender tool (notify-send)
    swaybg                   # Wayland wallpaper manager
    hyprpaper                # Hyprland native wallpaper utility
    hyprlock                 # Fast, modern screen locker for Hyprland
    hypridle                 # Idle daemon for auto-sleep / auto-lock
    wl-clipboard             # Wayland CLI clipboard utilities (wl-copy, wl-paste)
    grim                     # Screenshot tool for Wayland
    slurp                    # Interactive region selection tool (works with grim)
    pavucontrol              # Volume control GUI
    brightnessctl            # Display brightness control tool
    pamixer                  # PipeWire / PulseAudio volume CLI for keybindings
    playerctl                # Media player controller for media keys
    networkmanagerapplet     # NetworkManager systray applet (nm-applet)
    kdePackages.polkit-kde-agent-1 # Polkit authentication GUI agent
    swaylock-effects
    waypaper

    # --- GUI Utilities & File Management ---
    nautilus                 # Rich graphical file manager
    kdePackages.dolphin      # Rich graphical file manager
    kdePackages.ark          # Archive manager
    qimgv                    # Image Viewer
    yazi                     # Terminal file manager

    # --- Essential Command-Line Utilities ---
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
  services.udisks2.enable = true;

  # ----------------------------------------------------------------------------
  # 11. Fonts (Nerd Fonts & Icons for Waybar, Kitty, Neovim)
  # ----------------------------------------------------------------------------
  fonts.packages = with pkgs; [
    nerd-fonts.jetbrains-mono
    font-awesome
    noto-fonts
    noto-fonts-color-emoji
  ];

  # ----------------------------------------------------------------------------
  # 12. NixOS System Release Version
  # ----------------------------------------------------------------------------
  system.stateVersion = "26.05";
}

