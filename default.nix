# Non-flake entry point.
#
# The flake (flake.nix) is the canonical way to build/host CiderPress II.  This
# file exists so the package can also be built with classic `nix-build` — handy
# in restricted environments where the flake source fetcher trips over
# char-special dotfiles, since `package.nix` reads the working tree through an
# explicit `builtins.path` filter instead.
#
#   nix-build                 # builds the default package
#   nix-build -A fetch-deps   # builds the NuGet lockfile generator
{
  pkgs ? import <nixpkgs> { },
}:
pkgs.callPackage ./package.nix { }
