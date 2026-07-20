{
  lib,
  buildDotnetModule,
  fetchFromGitHub,
  dotnetCorePackages,
  copyDesktopItems,
  makeDesktopItem,
  imagemagick,
  # Runtime libraries needed by the Avalonia GUI on Linux.
  fontconfig,
  libX11,
  libICE,
  libSM,
  libXi,
  libXcursor,
  libXext,
  libXrandr,
  libGL,
  libxkbcommon,
}:

let
  # Upstream release pin.  CI (.github/workflows/update-nix-deps.yml) rewrites
  # this file when fadden/CiderPress2 publishes a newer tag.
  source = lib.importJSON ./source.json;
in
buildDotnetModule (finalAttrs: {
  pname = "ciderpress2";
  inherit (source) version;

  # Build the upstream release source at the pinned tag, not this repo's tree.
  src = fetchFromGitHub {
    inherit (source) owner repo rev hash;
  };

  # Build the cross-platform CLI and the new (2.0) Avalonia GUI.
  projectFile = [
    "cp2/cp2.csproj"
    "cp2_avalonia/cp2_avalonia.csproj"
  ];

  nugetDeps = ./deps.json;

  dotnet-sdk = dotnetCorePackages.sdk_10_0;
  dotnet-runtime = dotnetCorePackages.runtime_10_0;

  # buildDotnetModule wraps the framework-dependent output itself, so disable
  # the single-file / ReadyToRun packaging the projects request for their own
  # release pipeline (they need an explicit RID and don't play well with the
  # nix wrapper).
  dotnetFlags = [
    "-p:PublishSingleFile=false"
    "-p:PublishReadyToRun=false"
  ];

  executables = [
    "cp2"
    "CiderPress2"
  ];

  nativeBuildInputs = [
    copyDesktopItems
    imagemagick
  ];

  # Menu entry for the GUI (the CLI stays terminal-only).
  desktopItems = [
    (makeDesktopItem {
      name = "ciderpress2";
      exec = "CiderPress2";
      icon = "ciderpress2";
      desktopName = "CiderPress II";
      genericName = "Disk Image Utility";
      comment = "Manage Apple II and vintage Mac disk images and file archives";
      categories = [
        "Utility"
        "Archiving"
      ];
      keywords = [
        "Apple II"
        "disk image"
        "ProDOS"
        "archive"
        "emulator"
      ];
    })
  ];

  postInstall = ''
    # LegalStuff.txt is read at runtime by the GUI's About box, which looks for
    # it next to the executable (AppContext.BaseDirectory).  Upstream's release
    # bundle ships it alongside the binaries, so mirror that here.
    install -Dm644 "${finalAttrs.src}/LegalStuff.txt" \
      "$out/lib/${finalAttrs.pname}/LegalStuff.txt"

    # Documentation that upstream packs into the release archive.
    install -Dm644 \
      "${finalAttrs.src}/ndocs/top/README.md" \
      "${finalAttrs.src}/docs/Manual-cp2.md" \
      "${finalAttrs.src}/Pkg/sample.cp2rc" \
      -t "$out/share/doc/${finalAttrs.pname}"

    # The upstream app icon is a single 256x256 PNG-based .ico; drop it into the
    # hicolor theme so the desktop entry has an icon.
    install -d "$out/share/icons/hicolor/256x256/apps"
    magick "${finalAttrs.src}/cp2_avalonia/Res/cp2_app.ico" \
      "$out/share/icons/hicolor/256x256/apps/ciderpress2.png"
  '';

  # Native libraries the Avalonia GUI dlopen()s at runtime, wrapped into
  # LD_LIBRARY_PATH.  The CLI does not need any of these.
  runtimeDeps = [
    fontconfig
    libX11
    libICE
    libSM
    libXi
    libXcursor
    libXext
    libXrandr
    libGL
    libxkbcommon
  ];

  meta = {
    description = "Utility for managing Apple II and vintage Mac disk images and file archives (CLI + Avalonia GUI)";
    homepage = "https://github.com/${source.owner}/${source.repo}";
    license = lib.licenses.asl20;
    mainProgram = "cp2";
    platforms = [
      "x86_64-linux"
      "aarch64-linux"
    ];
  };
})
