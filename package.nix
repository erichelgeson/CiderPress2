{
  lib,
  buildDotnetModule,
  dotnetCorePackages,
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

buildDotnetModule (finalAttrs: {
  pname = "ciderpress2";
  version = "2.0.0-dev3";

  # Read the live working tree, copying only the files needed to build.  This
  # is an explicit allowlist of the top-level entries the build touches, which
  # (a) keeps build artefacts and unrelated files out of the store for
  # reproducibility and (b) sidesteps the char-special / injected dotfiles the
  # dev sandbox bind-mounts over things like .gitmodules and .claude/ (nix
  # cannot serialise those into the store).  On a normal checkout this is just
  # a clean copy of the source projects.
  src =
    let
      root = toString ./.;
      allowedTop = [
        "AppCommon"
        "CommonUtil"
        "DiskArc"
        "DiskArcTests"
        "FileConv"
        "FileConvTests"
        "cp2"
        "cp2_avalonia"
        "deps.json"
        "package.nix"
      ];
    in
    builtins.path {
      path = ./.;
      name = "ciderpress2-src";
      filter =
        path: _type:
        let
          rel = lib.removePrefix (root + "/") path;
          top = builtins.head (lib.splitString "/" rel);
        in
        builtins.elem top allowedTop;
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
    homepage = "https://github.com/fadden/CiderPress2";
    license = lib.licenses.asl20;
    mainProgram = "cp2";
    platforms = [
      "x86_64-linux"
      "aarch64-linux"
    ];
  };
})
