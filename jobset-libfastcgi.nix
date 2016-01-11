# libfastcgi-ci.nix

{ fastcgiSrc ? { outPath = ../fastcgi; revCount = 0; gitTag = "dirty"; }
, supportedSystems ? ["x86_64-linux"]
}:

with (import <nixpkgs/pkgs/top-level/release-lib.nix> { inherit supportedSystems; });

rec {

  tarball = pkgs.releaseTools.sourceTarball {
    name = "libfastcgi";
    src = fastcgiSrc;
    version = fastcgiSrc.gitTag;
  };

  build = pkgs.lib.genAttrs supportedSystems (system:
    let
      pkgs = pkgsFor system;
    in
      pkgs.releaseTools.nixBuild {
        name = "libfastcgi";
        src = tarball;
        buildInputs = [ pkgs.boost.out ];
      }
  );
}
