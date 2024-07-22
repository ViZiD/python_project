{
  description = "NixOS flake for poetry project";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable-small";

    poetry2nix.url = "github:nix-community/poetry2nix";
    poetry2nix.inputs.nixpkgs.follows = "nixpkgs";

    utils.url = "github:numtide/flake-utils";
  };

  outputs =
    {
      self,
      nixpkgs,
      poetry2nix,
      utils,
    }:
    utils.lib.eachDefaultSystem (
      system:
      let
        pkgs = import nixpkgs {
          inherit system;
          overlays = [ poetry2nix.overlays.default ];
        };
        p2n = import poetry2nix { inherit pkgs; };

        overrides = p2n.defaultPoetryOverrides.extend (
          self: super: {
            #aiogram = super.aiogram.overridePythonAttrs (old: {
            #  buildInputs = old.buildInputs or [ ] ++ [ super.hatchling ];
            #});
          }
        );

        python = pkgs.python311;

        pythonEnv = p2n.mkPoetryEnv {
          projectDir = self;
          editablePackageSources = {
            python_project = "python_project";
          };
          python = python;
          overrides = overrides;
        };
        pythonApp = p2n.mkPoetryApplication {
          projectDir = self;
          python = python;
          overrides = overrides;
        };
      in
      rec {
        packages.default = pythonApp;

        defaultPackage = packages.default;

        apps.default = {
          type = "app";
          program = "${self.defaultPackage."${system}"}/bin/python_project";
        };

        defaultApp = apps.default;

        devShells.default = pkgs.mkShell {
          buildInputs = [
            pythonEnv
            pkgs.poetry
          ];
        };
      }
    );
}
