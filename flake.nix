{
  description = "A very basic flake";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils, ... }: 
    flake-utils.lib.eachDefaultSystem (system:
    let
      pkgs = nixpkgs.legacyPackages.${system};

      pname = "sshpk";
      version = (builtins.fromJSON (builtins.readFile ./package.json)).version;
      deps = pkgs.mkYarnModules {
        inherit pname version;
        packageJSON = ./package.json;
        yarnLock = ./yarn.lock;
        yarnNix = ./yarn.nix;
      };
    in {
      packages = {
        sshpk = with import nixpkgs { inherit system; };
        stdenv.mkDerivation rec {
          inherit pname version;

          installPhase = ''
            (cd ${deps} && find node_modules -type f -exec install -Dm 755 "{}" "$out/{}" \;)
            mkdir -p $out/bin
            find $out/node_modules/sshpk/bin -type f -exec ln -s "{}" "$out/bin" \;
          '';

          dontUnpack = true;
        };
        default = self.packages.${system}.sshpk;
      };

      devShell = pkgs.mkShell {
        packages = [
          pkgs.yarn
          pkgs.yarn2nix
          self.packages.${system}.default
        ];
      };
    });
}
