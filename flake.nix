{
  description = "casm - A small build system for NASM projects.";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

  outputs = { self, nixpkgs }:
    let
      systems = [ "x86_64-linux" ];
      forAllSystems = nixpkgs.lib.genAttrs systems;

      mkCasm = pkgs:
        pkgs.writeShellApplication {
          name = "casm";

          runtimeInputs = with pkgs; [
            coreutils
            nasm
            binutils
            gcc
          ];

          text = ''
            exec ${pkgs.bash}/bin/bash ${./casm} "$@"
          '';

          meta = {
            description = "A small build system for NASM projects";
            mainProgram = "casm";
            platforms = [ "x86_64-linux" ];
          };
        };
    in
    {
      packages = forAllSystems (system:
        let
          pkgs = import nixpkgs { inherit system; };
          casm = mkCasm pkgs;
        in
        {
          inherit casm;
          default = casm;
        }
      );

      apps = forAllSystems (system:
        let
          package = self.packages.${system}.casm;
        in
        {
          default = {
            type = "app";
            program = "${package}/bin/casm";
          };
          casm = {
            type = "app";
            program = "${package}/bin/casm";
          };
        }
      );

      devShells = forAllSystems (system:
        let
          pkgs = import nixpkgs { inherit system; };
          casm = mkCasm pkgs;
        in
        {
          default = pkgs.mkShellNoCC {
            packages = with pkgs; [
              casm
              bash
              nasm
              binutils
              gcc
              valgrind
              strace
              shellcheck
              shfmt
            ];
          };
        }
      );

      overlays.default = final: prev: {
        casm = mkCasm final;
      };

      nixosModules.default = { config, lib, pkgs, ... }:
        {
          options.programs.casm.enable = lib.mkEnableOption "the casm NASM build tool";

          config = lib.mkIf config.programs.casm.enable {
            environment.systemPackages = [ self.packages.${pkgs.system}.default ];
          };
        };
    };
}
