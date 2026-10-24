{ pkgs, inputs, ... }:

let
  zen-browser-pkg = inputs.zen-browser.packages.${pkgs.stdenv.hostPlatform.system}.default;
  helium-pkg = inputs.helium.packages.${pkgs.stdenv.hostPlatform.system}.default;
  noctalia-shell-pkg = (pkgs.noctalia-shell.override {
    noctalia-qs = pkgs.noctalia-qs.overrideAttrs (old: {
      postPatch = (old.postPatch or "") + ''
        echo '#include "monitor.hpp"' >> src/wayland/hyprland/ipc/connection.hpp
        echo '#include "workspace.hpp"' >> src/wayland/hyprland/ipc/connection.hpp
        echo '#include "hyprland_toplevel.hpp"' >> src/wayland/hyprland/ipc/connection.hpp
        echo '#include "monitor.hpp"' >> src/x11/i3/ipc/controller.hpp
        echo '#include "workspace.hpp"' >> src/x11/i3/ipc/controller.hpp
        echo '#include "metadata.hpp"' >> src/services/pipewire/defaults.hpp
        echo '#include "node.hpp"' >> src/services/pipewire/defaults.hpp
        echo '#include "node.hpp"' >> src/services/pipewire/device.hpp
        echo '#include "qml.hpp"' >> src/services/pipewire/peak.hpp
        echo '#include "qml.hpp"' >> src/services/pipewire/spectrum.hpp
      '';
    });
  }).overrideAttrs (old: {
    # Fix Qt 6.12 collision between QtQuick.Color (QQuickColor) and qs.Commons.Color
    postPatch = (old.postPatch or "") + ''
      mv Commons/Color.qml Commons/NColor.qml
      find . -name '*.qml' -exec sed -i -E \
        -e 's/\bColor\.(m[A-Z]|resolve|smartAlpha|adaptiveOpacity|colorKeyModel|isTransitioning)/NColor.\1/g' \
        -e 's/\btarget: Color\b/target: NColor/g' \
        {} +
    '';
  });
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

    # --- Compilers, Rust Toolchain & Build Acceleration ---
    gcc
    clang
    llvm
    lld
    mold                     # Ultra-fast linker for Rust
    sccache                  # Shared compilation cache across Cargo workspaces
    pkg-config
    cmake
    gnumake
    protobuf
    python3
    rustc
    cargo
    clippy
    rustfmt
    rust-analyzer
    rustPlatform.rustLibSrc
    cargo-nextest            # Fast parallel test runner
    cargo-watch              # Auto-recompile on file save
    cargo-edit               # cargo add/rm/upgrade utilities
    cargo-audit              # Security vulnerability scanner for Cargo.lock
    cargo-expand             # Macro expansion inspector
    cargo-outdated           # Dependency version checker
    cargo-flamegraph         # Profiling & flamegraphs
    cargo-binutils           # LLVM objdump/nm/size wrappers for Rust
    just                     # Command runner
    gdb                      # GNU Debugger
    lldb                     # LLVM Debugger (for Rust debugging)

    # --- Cryptography Libraries & CLI Tools ---
    openssl
    nettle
    gmp
    libsodium
    sqlite
    xz
    zstd
    zlib
    bzip2
    pcsclite
    sequoia-sq               # Modern OpenPGP CLI (`sq`) written in Rust
    age                      # Simple, modern file encryption
    gnupg                    # GnuPG suite
    mkcert                   # Zero-config local trusted TLS certificates
    step-cli                 # Smallstep crypto & X.509/TLS Swiss-army knife
    wireguard-tools          # WireGuard key & tunnel management (`wg`, `wg-quick`)

    # --- Networking & Packet Analysis ---
    libpcap
    wireshark
    termshark                # Terminal UI for Wireshark/tshark
    tcpdump
    nmap
    rustscan                 # Fast port scanner in Rust
    socat                    # Multipurpose relay (TCP/UDP/UNIX/TLS sockets)
    netcat-gnu               # Classic netcat (`nc`)
    iperf3                   # Network bandwidth measurement
    mtr                      # Network diagnostic traceroute
    dnsutils                 # `dig`, `nslookup`, `nsupdate`
    whois
    iproute2                 # `ip`, `ss`, `tc`, `bridge` (network namespaces & traffic control)
    ethtool
    nftables
    conntrack-tools
    arti                     # Tor implementation in Rust (`arti`)
    tor                      # Standard Tor daemon/relay
    xh                       # Fast HTTP/HTTPS/TLS CLI client in Rust
    websocat                 # CLI WebSocket client/server debugger in Rust

    # --- Code & Text Editors ---
    neovim
    vscodium
    micro

    # --- Version Control ---
    lazygit
    git

    # --- Hypr Desktop Ecosystem ---
    hyprpicker
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
    obs-studio
    inotify-tools
    wlogout
    wl-screenrec
    sddm-astronaut            # SDDM Theme
    gnome-themes-extra # Fournit Adwaita-dark
    glib               # Fournit la commande gsettings
    gsettings-desktop-schemas

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
