{
  description = "fast line counter in zig";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs =
    { self, nixpkgs, flake-utils }:
    flake-utils.lib.eachDefaultSystem (
      system:
      let
        pkgs = nixpkgs.legacyPackages.${system};
        version =
          let
            zon = builtins.readFile ./build.zig.zon;
            match = builtins.match ''.*\.version = "([^"]+)".*'' zon;
          in
          builtins.elemAt match 0;
      in
      {
        packages.default = pkgs.stdenv.mkDerivation {
          pname = "zline";
          inherit version;
          src = self;
          nativeBuildInputs = [ pkgs.zig_0_16 ];
          dontConfigure = true;
          buildPhase = ''
            export ZIG_GLOBAL_CACHE_DIR=$(mktemp -d)
            zig build -Doptimize=ReleaseSmall
          '';
          installPhase = ''
            mkdir -p $out/bin
            cp zig-out/bin/zline $out/bin/
          '';
          meta = with pkgs.lib; {
            description = "fast line counter in zig";
            homepage = "https://github.com/flyewic/zline";
            license = licenses.mit;
            mainProgram = "zline";
          };
        };

        devShells.default = pkgs.mkShell {
          nativeBuildInputs = [ pkgs.zig_0_16 ];
        };
      }
    );
}
