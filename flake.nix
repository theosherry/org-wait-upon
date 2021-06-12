{
  description = "Org Wait Upon";

  inputs = {

    nixpkgs.url = "github:NixOS/nixpkgs/nixos-21.05";

  };

  outputs = { self, nixpkgs, ... }:
  let
    system = "x86_64-linux";
  in
  {

    packages."${system}".orgWaitUpon = 
    with import nixpkgs { inherit system; };

    emacsPackagesNg.melpaBuild {
      pname = "org-wait-upon";
      ename = "org-wait-upon";
      version = "0.10";

      recipe = builtins.toFile "recipe" ''
        (org-wait-upon :fetcher github
        :repo "theosherry/org-wait-upon")
      '';
      src = ./org-wait-upon.el;
    };

    defaultPackage."${system}" = self.packages."${system}".orgWaitUpon;
  };
}






