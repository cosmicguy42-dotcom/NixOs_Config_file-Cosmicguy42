# ==============================================================================
# NixOS Main Configuration: config.nix
# Modular setup importing ./package.nix
# ==============================================================================

{
  config,
  lib,
  pkgs,
  modulesPath,
  inputs ? null,
  ...
}:

{
  imports = [
    # Automatically detected hardware modules (do not remove)
    (modulesPath + "/installer/scan/not-detected.nix")

    # Modular package list
    ./package.nix
  ];

  # Provide default for inputs so this file can be built both with and without Flakes
  _module.args.inputs = lib.mkDefault null;

  # ----------------------------------------------------------------------------
  # 1. Hardware & Kernel Configuration
  # ----------------------------------------------------------------------------
  boot.initrd.availableKernelModules = [
    "xhci_pci"
    "ahci"
    "nvme"
    "usbhid"
    "usb_storage"
    "sd_mod"
  ];
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
    options = [
      "fmask=0077"
      "dmask=0077"
    ];
  };

  # NAS SMB/CIFS Share
  fileSystems."/mnt/nas" = {
    device = "//192.168.1.177/LE_NOM_DU_PARTAGE";
    fsType = "cifs";
    options = [
      "x-systemd.automount"
      "noauto"
      "x-systemd.idle-timeout=60"
      "credentials=/etc/.smbcredentials"
      "uid=1000"
      "gid=1000"
      "iocharset=utf8"
      "_netdev"
      "nofail"
    ];
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
      intel-media-driver # Décodage matériel VA-API pour i5-12450H (Alder Lake)
      libva-vdpau-driver
      libvdpau-va-gl
    ];
  };

  # Pilote propriétaire NVIDIA
  services.xserver.videoDrivers = [ "nvidia" ];

  hardware.nvidia = {
    modesetting.enable = true;
    powerManagement.enable = false;
    powerManagement.finegrained = false;
    open = false; # Pilote propriétaire officiel (recommandé et stable sur RTX 3050)
    nvidiaSettings = true;
    package = config.boot.kernelPackages.nvidiaPackages.stable;

    # Mode Hybride (PRIME Offload) :
    prime = {
      offload = {
        enable = true;
        enableOffloadCmd = true;
      };
      # Adresses PCI de la machine
      intelBusId = "PCI:0:2:0";
      nvidiaBusId = "PCI:1:0:0";
    };
  };

  # ----------------------------------------------------------------------------
  # 2. Bootloader (UEFI / systemd-boot)
  # ----------------------------------------------------------------------------
  boot.loader.systemd-boot.enable = true;
  boot.loader.systemd-boot.graceful = true;
  boot.loader.efi.canTouchEfiVariables = false;
  boot.loader.systemd-boot.configurationLimit = 5;

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
  # 5. Desktop Environment: Niri & Display Manager
  # ----------------------------------------------------------------------------
  programs.niri = {
    enable = true;
  };

  # Wayland variables for Electron/Chromium and default browser
  environment.sessionVariables = {
    NIXOS_OZONE_WL = "1";
    DEFAULT_BROWSER = "${pkgs.librewolf}/bin/librewolf";
  };

  # Default browser associations
  xdg.mime = {
    enable = true;
    defaultApplications = {
      "text/html" = "librewolf.desktop";
      "text/xml" = "librewolf.desktop";
      "application/xhtml+xml" = "librewolf.desktop";
      "x-scheme-handler/http" = "librewolf.desktop";
      "x-scheme-handler/https" = "librewolf.desktop";
      "x-scheme-handler/about" = "librewolf.desktop";
      "x-scheme-handler/unknown" = "librewolf.desktop";
    };
  };

  # SDDM Display / Login Manager
  services.displayManager.sddm = {
    enable = true;
    wayland.enable = true;
    theme = "sddm-astronaut-theme";
    extraPackages = [ pkgs.sddm-astronaut ];
  };
  services.displayManager.defaultSession = "niri";

  # Bluetooth management GUI service (blueman-applet)
  services.blueman.enable = true;

  # Security / Polkit authentication
  security.polkit.enable = true;

  # XDG Portals
  xdg.portal = {
    enable = true;
    extraPortals = [
      pkgs.xdg-desktop-portal-gtk
      pkgs.xdg-desktop-portal-gnome
    ];
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
    extraGroups = [
      "networkmanager"
      "wheel"
      "docker"
    ];
    shell = pkgs.fish;
  };

  # ----------------------------------------------------------------------------
  # 8. Nix & Package Management Settings
  # ----------------------------------------------------------------------------
  nixpkgs.config.allowUnfree = true;
  nix.settings.experimental-features = [
    "nix-command"
    "flakes"
  ];
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
  # 10. Additional System Services
  # ----------------------------------------------------------------------------
  virtualisation.docker.enable = true;
  services.udisks2.enable = true;
  services.upower.enable = true;
  programs.fish.enable = true;

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
