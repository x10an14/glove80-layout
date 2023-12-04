{
  inputs = {
    flake-utils.url = "github:numtide/flake-utils";
    moergo-zmk = {
      url = "github:moergo-sc/zmk";
      flake = false;
    };
  };

  outputs = {self, ...} @ inputs:
    inputs.flake-utils.lib.eachDefaultSystem (system: let
      pkgs = let
        moergoPin = builtins.fromJSON (builtins.readFile "${inputs.moergo-zmk}/nix/pinned-nixpkgs.json");
        nixpkgs = builtins.fetchTarball {
          inherit (moergoPin) url sha256;
        };
      in
        import nixpkgs {localSystem = {inherit system;};};
      firmware = import inputs.moergo-zmk {inherit pkgs;};

      config = {
        keymap = "${self}/config/glove80.keymap";
        kconfig = "${self}/config/glove80.conf";
      };

      glove80_left = firmware.zmk.override config // {board = "glove80_lh";};
      glove80_right = firmware.zmk.override config // {board = "glove80_rh";};
      glove80Firmware = firmware.combine_uf2 glove80_left glove80_right;
    in {
      devShell = pkgs.mkShell {
        # Add used tooling to build firmware to devShell so as to enable manual building
        inputsFrom = [glove80Firmware];
      };
      packages = {
        inherit glove80Firmware;
        default = glove80Firmware;
      };

      formatter = pkgs.alejandra;
    });
}
