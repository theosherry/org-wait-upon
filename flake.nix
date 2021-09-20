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
    overlay = final: prev: {
      org-wait-upon = {
        org-wait-upon = prev.emacsPackagesNg.melpaBuild {
          pname = "org-wait-upon";
          ename = "org-wait-upon";
          version = "0.10";

          recipe = builtins.toFile "recipe" ''
            (org-wait-upon :fetcher github
            :repo "theosherry/org-wait-upon")
          '';
          src = ./org-wait-upon.el;
        };
      };
    };
  };
}





