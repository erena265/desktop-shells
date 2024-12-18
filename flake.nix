{
  description = "Astal desktop shells";
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-unstable";

    astal = {
      url = "github:aylur/astal";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    ags = {
      url = "github:Aylur/ags";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    {
      nixpkgs,
      astal,
      ags,
      ...
    }:
    let
      supportedSystems = [
        "x86_64-linux"
        "aarch64-linux"
        "x86_64-darwin"
        "aarch64-darwin"
      ];

      forEachSupportedSystem =
        action:
        nixpkgs.lib.genAttrs supportedSystems (
          system:
          action {
            pkgs = import nixpkgs {
              inherit system;
              overlays = [ ];
            };
          }
        );
    in
    {
      devShells = forEachSupportedSystem (
        { pkgs }:
        {
          default = pkgs.mkShellNoCC {
            packages = [ ];
          };
        }
      );

      packages = forEachSupportedSystem (
        { pkgs }:
        let
        in
        {
          bar = astal.lib.mkLuaPackage {
            inherit pkgs;
            name = "astal-bar"; # how to name the executable
            src = ./.; # should contain init.lua

            # add extra glib packages or binaries
            extraPackages = [
              astal.packages.${pkgs.system}.mpris
              astal.packages.${pkgs.system}.battery
              astal.packages.${pkgs.system}.network
              astal.packages.${pkgs.system}.tray
              astal.packages.${pkgs.system}.hyprland
              astal.packages.${pkgs.system}.wireplumber
            ];
          };
        }
      );
    };
}
