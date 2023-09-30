{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs";
    flake-utils.url = "github:numtide/flake-utils";
    moergo-zmk = {
      url = "github:moergo-sc/zmk";
      flake = false;
    };
  };

  outputs = {self, ...} @ inputs:
    inputs.flake-utils.lib.eachDefaultSystem (system: let
      pkgs = import inputs.nixpkgs {inherit system;};
      firmware = import inputs.moergo-zmk {inherit pkgs;};

      config = {
        keymap = "${self}/config/glove80.keymap";
        kconfig = "${self}/config/glove80.conf";
      };

      glove80_left = firmware.zmk.override config // {board = "glove80_lh";};
      glove80_right = firmware.zmk.override config // {board = "glove80_rh";};
    in {
      devShell = pkgs.mkShell {
        packages = with pkgs; [nix-output-monitor];
      };
      packages = rec {
        default = glove80Firmware;
        glove80Firmware = firmware.combine_uf2 glove80_left glove80_right;
      };

      formatter = pkgs.alejandra;
    });
}
