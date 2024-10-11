{
  description = "Basic haskell cabal template";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";

  outputs = { self, nixpkgs }:
    let
      forAllSystems = nixpkgs.lib.genAttrs nixpkgs.lib.systems.flakeExposed;
      nixpkgsFor = forAllSystems (system: import nixpkgs {
        inherit system;
        overlays = [ self.overlay ];
      });
    in
    {
      overlay = final: prev: {
        hsPkgs = prev.haskell.packages.ghc910.override {
          overrides = hfinal: hprev: { 
          postgresql-libpq-configure = final.haskell.lib.addBuildDepends (hprev.callCabal2nix "postgresql-libpq-configure" 
            ((builtins.fetchGit{
              url = "https://github.com/piq9117/postgresql-libpq.git";
              rev = "24c90657bc231a914060c82052b3787a22ee2316";
            }) + "/postgresql-libpq-configure") { }) [final.postgresql];
          };
        };

        project = final.hsPkgs.developPackage {
          root = ./.;
        };
      };

      packages =forAllSystems(system: 
        let 
          pkgs = nixpkgsFor.${system};
        in {
          default = pkgs.project;
        });

      devShells = forAllSystems (system:
        let
          pkgs = nixpkgsFor.${system};
          libs = with pkgs; [
            zlib
          ];
        in
        {
          default = pkgs.hsPkgs.shellFor {
            packages = hsPkgs: [ ];
            buildInputs = with pkgs; [
              hsPkgs.cabal-install
              hsPkgs.cabal-fmt
              hsPkgs.ghc
              ormolu
              treefmt
              nixpkgs-fmt
              hsPkgs.cabal-fmt
              # postgresql_15
            ] ++ libs;
            shellHook = "export PS1='[$PWD]\n❄ '";
            LD_LIBRARY_PATH = pkgs.lib.makeLibraryPath libs;
          };
        });
    };
}
