{
  description = "Quiver: a modern commutative diagram editor";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs =
    {
      self,
      nixpkgs,
      flake-utils,
    }:
    flake-utils.lib.eachDefaultSystem (
      system:
      let
        pkgs = nixpkgs.legacyPackages.${system};

      in
      {
        devShells.default = pkgs.mkShell {
          buildInputs = with pkgs; [
            gnumake
            curl
            unzip
            imagemagick
            python3
            git
          ];
        };

        packages.default = pkgs.callPackage ./package.nix {};

        apps.default = {
          type = "app";
          program = "${self.packages.${system}.default}/bin/quiver";
        };
      }
    );
}
