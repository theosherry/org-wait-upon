{
  description = "Org Wait Upon";

  inputs = {

    nixpkgs.url = "github:theosherry/nixpkgs/theo-working";

    flake-utils.url = "github:numtide/flake-utils?rev=98c8d36b1828009b20f12544214683c7489935a1";

  };

  outputs = { self, nixpkgs, flake-utils, ... }:
  let
    overlay = final: prev: {
      theoNix.emacsPackages.org-wait-upon = prev.emacsPackagesNg.melpaBuild {
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
    sysSpecific = flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = import nixpkgs {
          inherit system;
          overlays = [ overlay ];
        };
        packages = { org-wait-upon = pkgs.theoNix.emacsPackages.org-wait-upon; };
        defaultPackage = packages.org-wait-upon;
      in
        { inherit packages defaultPackage; });
    in
    { inherit overlay; } // sysSpecific;
}

