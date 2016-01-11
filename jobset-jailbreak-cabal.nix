# jailbreak-cabal-ci.nix

{ jailbreakCabalSrc ? { outPath = ../jailbreak-cabal; revCount = 0; gitTag = "dirty"; }
, supportedSystems ? ["x86_64-linux"]
, supportedCompilers ? ["ghc784" "ghc7103" "ghc801"]
}:

with (import <nixpkgs/pkgs/top-level/release-lib.nix> { inherit supportedSystems; });

let

  lib = pkgs.lib // pkgs.haskell.lib;

  buildFun = { mkDerivation, base, Cabal }: mkDerivation {
    pname = "jailbreak-cabal";
    version = jailbreakCabalSrc.gitTag;
    src = jailbreakCabalSrc;
    isLibrary = false;
    isExecutable = true;
    executableHaskellDepends = [ base Cabal ];
    homepage = "http://github.com/peti/jailbreak-cabal";
    description = "Strip version restrictions from build dependencies in Cabal files";
    license = pkgs.stdenv.lib.licenses.bsd3;
  };

in
{

  jailbreak-cabal = lib.genAttrs supportedCompilers (compiler:
    lib.genAttrs supportedSystems (system:
      let
        pkgs            = pkgsFor system;
        haskellPackages = pkgs.haskell.packages.${compiler};
        Cabal           = if compiler == "ghc801"
                            then null
                            else haskellPackages.Cabal_1_20_0_3;
      in
        haskellPackages.callPackage buildFun { inherit Cabal; }
    )
  );

}
