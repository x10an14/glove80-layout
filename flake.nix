{
  inputs = {
    flake-utils.url = "github:numtide/flake-utils";
    nixpkgs.url = "github:nixos/nixpkgs";
    moergo-zmk = {
      url = "github:moergo-sc/zmk";
      flake = false;
    };
  };

  outputs = {self, ...} @ inputs:
    inputs.flake-utils.lib.eachDefaultSystem (system: let
      ###   ZMK / Glove80 firmware stuff:
      moergo = let
        moergoPin = builtins.fromJSON (builtins.readFile "${inputs.moergo-zmk}/nix/pinned-nixpkgs.json");
        moergoNixpkgs = builtins.fetchTarball {
          inherit (moergoPin) url sha256;
        };
        pkgs = import moergoNixpkgs {localSystem = {inherit system;};};
      in
        import inputs.moergo-zmk {inherit pkgs;};

      config = {
        keymap = "${self}/config/glove80.keymap";
        kconfig = "${self}/config/glove80.conf";
      };
      glove80Firmware =
        moergo.combine_uf2
        (moergo.zmk.override config // {board = "glove80_lh";})
        (moergo.zmk.override config // {board = "glove80_rh";});

      ###   ZMK / Glove80 independent stuff:
      pkgs = import inputs.nixpkgs {localSystem = {inherit system;};};
    in {
      devShell = pkgs.mkShell {
        packages = with pkgs; [
          nix-output-monitor
          (python3.withPackages (pyPackage: with pyPackage; [pipx]))
        ];
        # Add used tooling to build firmware to devShell so as to enable manual building
        inputsFrom = [glove80Firmware];
        shellHook = ''
          export PATH="$PATH:$HOME/.local/bin"
        '';
      };

      packages = {
        inherit glove80Firmware;
        default = glove80Firmware;
      };

      formatter = pkgs.alejandra;
    });
}
