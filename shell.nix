{ pkgs ? import <nixpkgs> {} }:
pkgs.mkShell {
    buildInputs = [
      pkgs.neovim
      pkgs.stylua
      pkgs.git
      pkgs.luajitPackages.busted
      pkgs.luajitPackages.tl
    ];
}
