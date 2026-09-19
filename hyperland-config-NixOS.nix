# ==============================================================================
# NixOS Configuration: hyperland-config-NixOS.nix
# Description: Complete standalone NixOS configuration featuring:
#              - Hyprland Wayland Compositor & ecosystem (Waybar, Rofi, Kitty, Dunst)
#              - Essential CLI tools & utilities (Git, curl, wget, ripgrep, etc.)
#              - Neovim (default editor) & VSCodium (Vim removed)
#              - Zen Browser, LibreWolf & Firefox
# ==============================================================================

{ config, lib, pkgs, modulesPath, ... }:

let
  # Zen Browser community package fetched directly (works without enabling Flakes CLI)
  zen-browser = import (builtins.fetchTarball "https://github.com/0xc000022070/zen-browser-flake/archive/main.tar.gz") {
    inherit pkgs;
  };
in
{
  imports = [
    # Automatically detected hardware modules (do not remove)
    (modulesPath + "/installer/scan/not-detected.nix")
  ];

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

  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
  hardware.cpu.intel.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;

  # Bluetooth support
  hardware.bluetooth.enable = true;
  hardware.bluetooth.powerOnBoot = true;

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
    zen-browser.default
    librewolf
    firefox

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
    swaybg                   # Wayland wallpaper manager
    hyprpaper                # Hyprland native wallpaper utility
    hyprlock                 # Fast, modern screen locker for Hyprland
    hypridle                 # Idle daemon for auto-sleep / auto-lock
    wl-clipboard             # Wayland CLI clipboard utilities (wl-copy, wl-paste)
    grim                     # Screenshot tool for Wayland
    slurp                    # Interactive region selection tool (works with grim)
    pavucontrol              # Volume control GUI
    brightnessctl            # Display brightness control tool

    # --- GUI Utilities & File Management ---
    kdePackages.dolphin      # Rich graphical file manager
    kdePackages.ark          # Archive manager
    kdePackages.kate         # Graphical text editor

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

  # ----------------------------------------------------------------------------
  # 11. NixOS System Release Version
  # ----------------------------------------------------------------------------
  system.stateVersion = "26.05";
}
