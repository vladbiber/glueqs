{
  description = "glueqs: a dot-matrix desktop shell for gluewc, on Quickshell";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

  outputs =
    { self, nixpkgs }:
    let
      lib = nixpkgs.lib;
      systems = [
        "x86_64-linux"
        "aarch64-linux"
      ];
      forAllSystems = f: lib.genAttrs systems (system: f nixpkgs.legacyPackages.${system});

      # The QML tree goes under share/glueqs and `glueqs` runs it with the
      # Quickshell from nixpkgs. Settings are written to $XDG_CONFIG_HOME/glueqs,
      # never next to the QML, so the read-only store path is fine. curl and
      # bluetoothctl are on the wrapper's PATH; nmcli comes with NetworkManager
      # when the system has it and is not forced here.
      mkGlueqs =
        pkgs:
        pkgs.stdenvNoCC.mkDerivation {
          pname = "glueqs";
          version = "0-unstable-${self.lastModifiedDate or "unknown"}";
          src = self;
          nativeBuildInputs = [ pkgs.makeWrapper ];
          dontBuild = true;
          dontConfigure = true;
          installPhase = ''
            runHook preInstall
            mkdir -p $out/share/glueqs $out/bin
            cp -r . $out/share/glueqs
            rm -rf $out/share/glueqs/docs $out/share/glueqs/flake.nix $out/share/glueqs/flake.lock
            makeWrapper ${pkgs.quickshell}/bin/qs $out/bin/glueqs \
              --add-flags "-p $out/share/glueqs" \
              --prefix PATH : ${
                lib.makeBinPath (
                  with pkgs;
                  [
                    curl
                    bluez
                    coreutils
                    (python3.withPackages (ps: [ ps.pillow ]))
                  ]
                )
              }
            runHook postInstall
          '';
          meta = {
            description = "Dot-matrix desktop shell for gluewc, on Quickshell";
            homepage = "https://github.com/vladbiber/glueqs";
            license = lib.licenses.gpl3Only;
            mainProgram = "glueqs";
            platforms = lib.platforms.linux;
          };
        };
    in
    {
      packages = forAllSystems (pkgs: rec {
        glueqs = mkGlueqs pkgs;
        default = glueqs;
      });

      overlays.default = final: _prev: { glueqs = mkGlueqs final; };

      formatter = forAllSystems (pkgs: pkgs.nixfmt-tree);
    };
}
