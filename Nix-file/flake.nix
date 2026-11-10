{
  description = "NixOS configuration flake for Cosmicguy42";

  inputs = {
    # Dépôt principal de paquets NixOS (branche unstable)
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

    # Navigateur Zen Browser
    zen-browser = {
      url = "github:0xc000022070/zen-browser-flake";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Navigateur Helium
    helium = {
      url = "github:schembriaiden/helium-browser-nix-flake";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, ... }@inputs: {
    nixosConfigurations = {
      # Le nom d'hôte de la machine (networking.hostName dans config.nix)
      nixos = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        specialArgs = { inherit inputs; };
        modules = [
          ./config.nix
        ];
      };
    };
  };
}
