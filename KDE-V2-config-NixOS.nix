# ==============================================================================
# NixOS Configuration: KDE-V2-config-NixOS.nix
# Description: Complete beginner-friendly NixOS configuration featuring:
#              - KDE Plasma 6 desktop environment & essential KDE apps
#              - Essential CLI tools & utilities (Git, curl, wget, ripgrep, etc.)
#              - Neovim (default editor) & VSCodium (Vim removed)
#              - Zen Browser (modern Firefox fork)
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
  networking.networkmanager.enable = true; # Manages Wi-Fi & Ethernet easily

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
  # 5. Desktop Environment: KDE Plasma 6 & Integration
  # ----------------------------------------------------------------------------
  services.xserver.enable = true;
  services.displayManager.sddm.enable = true;           # SDDM display / login manager
  services.displayManager.sddm.wayland.enable = true;   # SDDM Wayland support
  services.desktopManager.plasma6.enable = true;         # KDE Plasma 6 Desktop

  # KDE Connect (sync notifications, SMS, clipboard, and file transfer with your phone)
  programs.kdeconnect.enable = true;

  # Flatpak support (useful for installing extra apps directly from KDE Discover)
  services.flatpak.enable = true;

  # ----------------------------------------------------------------------------
  # 6. Audio & Printing (PipeWire)
  # ----------------------------------------------------------------------------
  services.printing.enable = true;                 # CUPS printing support
  services.pulseaudio.enable = false;              # Disabled in favor of PipeWire
  security.rtkit.enable = true;                    # Real-time kit for audio priority
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
    extraGroups = [ "networkmanager" "wheel" ];    # "wheel" grants sudo permissions
  };

  # ----------------------------------------------------------------------------
  # 8. Nix & Package Management Settings
  # ----------------------------------------------------------------------------
  # Allow proprietary/unfree software (required for VSCodium extensions, certain drivers, etc.)
  nixpkgs.config.allowUnfree = true;

  # Run unpatched dynamic binaries on NixOS (useful for VS Code / VSCodium remote extensions, CLI tools)
  programs.nix-ld.enable = true;

  # Include ~/.local/bin in PATH
  environment.localBinInPath = true;

  # ----------------------------------------------------------------------------
  # 9. Editor Preferences (Neovim & VSCodium enabled, Vim removed)
  # ----------------------------------------------------------------------------
  # Set Neovim as the default system editor
  programs.neovim = {
    enable = true;
    defaultEditor = true;
    viAlias = true;   # 'vi' points to neovim
    vimAlias = true;  # 'vim' points to neovim
  };

  # ----------------------------------------------------------------------------
  # 10. System Packages (KDE apps, basic tools, editors, browsers)
  # ----------------------------------------------------------------------------
  environment.systemPackages = with pkgs; [
    # --- Web Browsers ---
    zen-browser.default      # Zen Browser (Firefox-based modern vertical-tab browser)
    librewolf                # Privacy-oriented Firefox fork
    firefox                  # Standard Firefox browser

    # --- Code & Text Editors ---
    # NOTE: Vim has been removed. Neovim and VSCodium are installed below.
    neovim                   # Modern extensible terminal editor (default editor)
    vscodium                 # Community-driven, telemetry-free VS Code binary

    # --- Version Control ---
    git                      # Distributed version control system

    # --- KDE Applications & Utilities ---
    kdePackages.kate         # Advanced KDE text editor
    kdePackages.dolphin      # KDE file manager
    kdePackages.ark          # KDE archive manager (integrates with Dolphin)
    kdePackages.spectacle    # Screenshot & screen capture tool
    kdePackages.gwenview     # Fast image viewer
    kdePackages.okular       # Universal document and PDF viewer
    kdePackages.kcalc        # Scientific calculator
    kdePackages.plasma-systemmonitor # Modern KDE system monitor GUI

    # --- Essential Command-Line Utilities ---
    curl                     # Transfer data with URLs
    wget                     # Retrieve files using HTTP, HTTPS, and FTP
    tree                     # Recursive directory listing program
    ripgrep                  # Fast line-oriented search tool (grep alternative)
    fd                       # Simple, fast, and user-friendly find alternative
    jq                       # Lightweight command-line JSON processor
    which                    # Locate a command in PATH
    file                     # Determine file type

    # --- Archive Utilities ---
    unzip                    # Extraction utility for .zip archives
    zip                      # Packaging utility for .zip archives

    # --- System Monitoring & Information ---
    htop                     # Interactive process viewer
    btop                     # Modern, resource-friendly terminal resource monitor
    fastfetch                # Fast system information display tool
  ];

  # ----------------------------------------------------------------------------
  # 11. NixOS System Release Version
  # ----------------------------------------------------------------------------
  # Do not change this value after installation. Refer to manual for details.
  system.stateVersion = "26.05";
}
