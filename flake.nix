{
  inputs = {
    flake-utils.url = "github:numtide/flake-utils";
    nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";
    rust-overlay = {
      url = "github:oxalica/rust-overlay";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    moergo-zmk = {
      url = "github:moergo-sc/zmk";
      flake = false;
    };
  };

  outputs = {self, ...} @ inputs:
    inputs.flake-utils.lib.eachDefaultSystem (system: let
      ###   ZMK / Glove80 firmware stuff:
      moergo = let
        moergoPin = builtins.fromJSON (
          builtins.readFile "${inputs.moergo-zmk}/nix/pinned-nixpkgs.json"
        );
        moergoNixpkgs = fetchTarball {
          inherit (moergoPin) url sha256;
        };
        pkgs = import moergoNixpkgs {localSystem = {inherit system;};};
      in
        import inputs.moergo-zmk {inherit pkgs;};

      config = {
        keymap = "${self}/config/glove80.keymap";
        kconfig = "${self}/config/glove80.conf";
      };
      right_hand = moergo.zmk.override (config // {board = "glove80_rh";});
      left_hand = moergo.zmk.override (config // {board = "glove80_lh";});
      # Combine the firmware for each half to 1x .u2f file
      glove80Firmware = moergo.combine_uf2 left_hand right_hand;

      ###   ZMK / Glove80 independent stuff:
      pkgs = import inputs.nixpkgs {
        localSystem = {inherit system;};
        overlays = [(import inputs.rust-overlay)];
      };
      rustToolchain = pkgs.rust-bin.stable.latest.default;
      rustPlatform = pkgs.makeRustPlatform {
        cargo = rustToolchain;
        rustc = rustToolchain;
      };
      oxeylyzer = pkgs.callPackage ./oxeylyzer.nix {inherit rustPlatform;};

      # Generate .dof layout file from the ZMK keymap
      layoutDof = pkgs.runCommand "engrammerno.dof" {} ''
        ${pkgs.python314}/bin/python3 ${./keymap-to-dof.py} ${self}/config/glove80.keymap > $out
      '';
    in {
      devShell = pkgs.mkShell {
        shellHook = ''
          # Linting
          ${pkgs.deadnix}/bin/deadnix --hidden
          ${pkgs.statix}/bin/statix check .

          # Required for pipx -> used to install keymap-drawer
          export PATH="$PATH:$HOME/.local/bin"

          # For ./generate_dof_score.py standalone usage
          export OXEYLYZER_STATIC="${oxeylyzer.src}/static"
        '';

        packages = with pkgs; [
          nix-output-monitor
          alejandra
          oxeylyzer
          (python314.withPackages (pyPackage: with pyPackage; [pipx]))
        ];

        # Add used tooling to build firmware to devShell so as to enable manual building
        inputsFrom = [glove80Firmware];
      };

      packages = {
        inherit glove80Firmware right_hand left_hand oxeylyzer layoutDof;
        default = glove80Firmware;
      };

      checks = {
        inherit glove80Firmware right_hand left_hand oxeylyzer layoutDof;
        oxeylyzer-smoke = pkgs.runCommand "oxeylyzer-smoke-test" {} ''
          cp ${self}/config.toml .
          cp -r --no-preserve=mode ${oxeylyzer.src}/static .
          printf 'quit\n' | ${oxeylyzer}/bin/oxeylyzer || true
          rm -rf config.toml static
          touch $out
        '';
      };

      apps.default = let
        analyze = pkgs.writeShellScript "analyze-layout" ''
          set -euo pipefail
          export PATH="${pkgs.lib.makeBinPath [pkgs.git pkgs.coreutils pkgs.gnugrep pkgs.python314 oxeylyzer]}:$PATH"
          export OXEYLYZER_STATIC="${oxeylyzer.src}/static"
          export CONFIG_TOML="${self}/config.toml"

          REPO="$(git rev-parse --show-toplevel)"
          CSV="$REPO/dof_results.csv"
          REV="$(git -C "$REPO" rev-parse --short HEAD)"
          HASH="$(sha256sum "$REPO/config/glove80.keymap" | cut -c1-8)"

          if [ -f "$CSV" ] && grep -q "^$REV,$HASH," "$CSV"; then
            echo "Already recorded $REV/$HASH — $(tail -1 "$CSV")" >&2
            exit 0
          fi

          ROW="$REV,$HASH,$(python3 ${self}/keymap-to-dof.py "$REPO/config/glove80.keymap" | python3 ${self}/generate_dof_score.py)"
          echo "$ROW" >> "$CSV"
          echo "Appended: $ROW" >&2
        '';
      in {
        type = "app";
        program = "${analyze}";
      };

      formatter = pkgs.alejandra;
    });
}
