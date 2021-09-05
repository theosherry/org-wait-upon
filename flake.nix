{
  description = "Org Wait Upon";

  inputs = {

    nixpkgs.url = "github:NixOS/nixpkgs?rev=bad3ccd099ebe9a8aa017bda8500ab02787d90aa";

    flake-utils.url = "github:numtide/flake-utils?rev=98c8d36b1828009b20f12544214683c7489935a1";

  };

  outputs = { self, nixpkgs, flake-utils, ... }:
  flake-utils.lib.simpleFlake {
    inherit self nixpkgs;
    name = "org-wait-upon";
    overlay = ./overlay.nix;
  };
}






