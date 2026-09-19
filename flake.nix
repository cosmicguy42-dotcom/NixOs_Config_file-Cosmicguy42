{
  description = "NixOS Configuration with Hyprland and Ryoku Desktop";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

    ryoku = {
      url = "github:aethctl/Ryoku-on-NixOS";
    };

    zen-browser = {
      url = "github:0xc000022070/zen-browser-flake";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, ryoku, zen-browser, ... }@inputs: {
    nixosConfigurations.nixos = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      specialArgs = { inherit inputs; };
      modules = [
        ./hyperland-config-NixOS.nix
        ryoku.nixosModules.default
        {
          nixpkgs.config.allowUnfree = true;
          nixpkgs.config.permittedInsecurePackages = [
            "electron-41.10.6"
          ];

          programs.ryoku = {
            enable = true;
            shell = "fish";
            updateFlake = "/home/kmv22/Nix_Config";
          };
        }
      ];
    };
  };
}
