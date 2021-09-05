final: prev: {
  org-wait-upon= {
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
     
}
