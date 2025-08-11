{
  lib,
  stdenv,
  fetchFromGitHub,
  fetchurl,
  unzip,
  imagemagick,
  makeWrapper,
  python3,
  xdg-utils,
  writeText,
  runtimeShell,
}:
stdenv.mkDerivation rec {
  pname = "quiver";
  version = "1.5.5";

  src = fetchFromGitHub {
    owner = "varkor";
    repo = "quiver";
    rev = "0381c286cac02c2c551e38fd533ecd5720482e39";
    sha256 = "sha256-dgkyQtXog4/6tQLbZA4/l+iJymfAiuMb4+2fo0fksWE=";
  };

  # Fetch KaTeX dependency
  katexSrc = fetchurl {
    url = "https://github.com/KaTeX/KaTeX/releases/download/v0.16.9/katex.zip";
    sha256 = "sha256-TRbpqcfOtzqqlMmAI6gwf1YaF02B7bnSWBEVCLHnS+s=";
  };

  # Fetch Workbox dependency
  workboxSrc = fetchurl {
    url = "https://storage.googleapis.com/workbox-cdn/releases/7.0.0/workbox-sw.js";
    sha256 = "sha256-9/nR9tSoKxemoLPvKLvN49jgUzqH5BWb2EQRyK006iE=";
  };

  nativeBuildInputs = [
    unzip
    imagemagick
    makeWrapper
  ];

  buildPhase = ''
    # Extract KaTeX
    unzip ${katexSrc} -d katex_temp
    mv katex_temp/katex src/KaTeX
    rm -rf katex_temp

    # Setup Workbox
    mkdir -p src/Workbox
    cp ${workboxSrc} src/Workbox/workbox-sw.js

    # Generate icons
    magick src/icon.png -resize 192x192 src/icon-192.png
    magick src/icon.png -resize 512x512 src/icon-512.png
  '';

  launcherTemplate = writeText "quiver-launcher" ''
    #!${runtimeShell}
    QUIVER_DIR="@QUIVER_SHARE@"
    PORT=''${QUIVER_PORT:-24271}

    echo "Starting Quiver on http://localhost:$PORT"
    echo "Press Ctrl+C to stop the server"

    # Try to open browser if available
    if command -v xdg-open >/dev/null 2>&1; then
      (sleep 1 && xdg-open "http://localhost:$PORT") &
    elif command -v open >/dev/null 2>&1; then
      (sleep 1 && open "http://localhost:$PORT") &
    fi

    cd "$QUIVER_DIR"
    exec python3 -m http.server -d "$QUIVER_DIR/src/" "$PORT"
  '';

  installPhase = ''
    # Install application files
    mkdir -p $out/share/quiver
    cp -r ./* $out/share/quiver/

    mkdir -p $out/bin

    # Create the main executable by substituting the placeholder
    substitute ${launcherTemplate} $out/bin/quiver \
      --subst-var-by QUIVER_SHARE $out/share/quiver
    chmod +x $out/bin/quiver

    # Wrap the executable to make runtime dependencies available in PATH
    wrapProgram $out/bin/quiver \
      --prefix PATH : ${
        lib.makeBinPath [
          python3
          xdg-utils
        ]
      }
  '';

  meta = with lib; {
    description = "A modern commutative diagram editor";
    homepage = "https://github.com/varkor/quiver";
    license = licenses.mit;
    platforms = platforms.all;
    mainProgram = "quiver";
  };
}
