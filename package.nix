{ pkgs, inputs ? null, ... }:

let
  # Zen Browser package from flake input if provided, otherwise fetchTarball
  zen-browser-pkg =
    if inputs != null && inputs ? zen-browser then
      inputs.zen-browser.packages.${pkgs.stdenv.hostPlatform.system}.default
    else
      (import
        (builtins.fetchTarball "https://github.com/0xc000022070/zen-browser-flake/archive/main.tar.gz")
        {
          inherit pkgs;
        }
      ).default;

  # Helium Browser package from flake input if provided, otherwise getFlake
  helium-pkg =
    if inputs != null && inputs ? helium then
      inputs.helium.packages.${pkgs.stdenv.hostPlatform.system}.default
    else
      (builtins.getFlake "github:schembriaiden/helium-browser-nix-flake").packages.${pkgs.stdenv.hostPlatform.system}.default;

in
{
  # ----------------------------------------------------------------------------
  # System Packages Configuration
  # ----------------------------------------------------------------------------
  environment.systemPackages = with pkgs; [
    # --- Web Browsers ---
    librewolf
    zen-browser-pkg
    helium-pkg

    # --- Messages & Communication ---
    discord
    signal-desktop
    karere

    # --- Productivity & Office ---
    libreoffice

    # --- Media, Gaming & Notes ---
    spotify
    steam
    obsidian

    # --- Terminal UI (TUI) ---
    cava
    peaclock
    cowsay

    # --- Compilers & Dev Tools ---
    gcc
    python3
    cargo
    rustc

    # --- Networking ---
    nmap
    wireshark

    # --- Code & Text Editors ---
    neovim
    vscodium
    micro

    # --- Version Control ---
    lazygit
    git

    # --- Niri Desktop Ecosystem ---
    xwayland-satellite       # XWayland outside-of-process bridge for Niri
    fuzzel                   # Minimalist Wayland application launcher
    kitty                    # Default terminal emulator
    waybar                   # Wayland status bar
    rofi                     # Application launcher & window switcher
    wofi                     # Alternative Wayland app launcher
    dunst                    # Lightweight notification daemon
    libnotify                # Notification sender (notify-send)
    swaybg                   # Wayland wallpaper manager
    waypaper                 # GUI wallpaper selector
    hyprpaper                # Alternative Wayland wallpaper utility
    hyprlock                 # Screen locker
    hypridle                 # Idle daemon for auto-sleep / auto-lock
    swaylock-effects         # Screen locker with effects
    wl-clipboard             # Wayland CLI clipboard utilities
    grim                     # Screenshot tool for Wayland
    slurp                    # Region selector for grim
    pavucontrol              # Volume control GUI
    brightnessctl            # Screen & keyboard brightness tool
    pamixer                  # PipeWire / PulseAudio CLI volume
    playerctl                # Media player CLI controller
    networkmanagerapplet     # NetworkManager systray (nm-applet)
    kdePackages.polkit-kde-agent-1 # Polkit authentication GUI agent
    inotify-tools
    wlogout
    wl-screenrec

    # --- GUI Utilities & File Management ---
    kdePackages.dolphin      # KDE File Manager
    kdePackages.ark          # Archive manager
    nautilus                 # GNOME File Manager
    qimgv                    # Image Viewer
    mpv                      # Video Player
    yazi                     # Terminal File Manager

    # --- Essential CLI Utilities ---
    cifs-utils
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
}
