{
  description = "CiderPress II — Apple II / vintage Mac disk image and file archive utility (CLI + Avalonia GUI)";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  };

  outputs =
    { self, nixpkgs }:
    let
      systems = [
        "x86_64-linux"
        "aarch64-linux"
      ];
      forAllSystems = nixpkgs.lib.genAttrs systems;
      pkgsFor = system: nixpkgs.legacyPackages.${system};
    in
    {
      packages = forAllSystems (
        system:
        let
          pkgs = pkgsFor system;
          ciderpress2 = pkgs.callPackage ./package.nix { };
        in
        {
          inherit ciderpress2;
          default = ciderpress2;
        }
      );

      # Convenience apps: `nix run .#cp2` and `nix run .#gui`.
      apps = forAllSystems (
        system:
        let
          ciderpress2 = self.packages.${system}.ciderpress2;
        in
        {
          default = {
            type = "app";
            program = "${ciderpress2}/bin/cp2";
          };
          cp2 = {
            type = "app";
            program = "${ciderpress2}/bin/cp2";
          };
          gui = {
            type = "app";
            program = "${ciderpress2}/bin/CiderPress2";
          };
        }
      );

      devShells = forAllSystems (
        system:
        let
          pkgs = pkgsFor system;
        in
        {
          default = pkgs.mkShell {
            packages = [ pkgs.dotnetCorePackages.sdk_10_0 ];
          };
        }
      );
    };
}
