{
  lib,
  rustPlatform,
  fetchFromGitHub,
}:
rustPlatform.buildRustPackage rec {
  pname = "oxeylyzer";
  version = "0.1.0-unstable-2026-03-15";

  src = fetchFromGitHub {
    owner = "O-X-E-Y";
    repo = "oxeylyzer";
    rev = "92628ae7765365cd54b0dd1771b40fb6bc874555";
    hash = "sha256-1o7hKiN3oTRHL4BrOhN745QpgdTaAH986X43fxL8jMI=";
  };

  # Upstream hardcodes `CARGO_MANIFEST_DIR` for `config.toml` and `static/` paths.
  # Patch to use `CWD` instead so the installed binary works outside the source tree.
  postPatch = ''
    substituteInPlace oxeylyzer-repl/src/repl.rs \
      --replace-fail 'concat!(std::env!("CARGO_MANIFEST_DIR"), "/../config.toml")' '"config.toml"' \
      --replace-fail 'concat!(std::env!("CARGO_MANIFEST_DIR"), "/../static")' '"static"'
    substituteInPlace oxeylyzer-core/src/generate.rs \
      --replace-fail 'concat!(
                std::env!("CARGO_MANIFEST_DIR"),
                "/../config.toml"
            )' '"config.toml"'
  '';

  cargoLock = {
    lockFile = "${src}/Cargo.lock";
    allowBuiltinFetchGit = true;
  };

  meta = with lib; {
    description = "A keyboard layout analyzer";
    homepage = "https://github.com/O-X-E-Y/oxeylyzer";
    license = licenses.asl20;
    mainProgram = "oxeylyzer";
  };
}
