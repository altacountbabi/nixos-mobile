{
  perSystem =
    { pkgs, lib, ... }:
    {
      lib.buildKernel =
        let
          inherit (lib) optionalString;
          inherit (pkgs) buildLinux dtbTool dtbTool-exynos;

          platform = pkgs.stdenv.hostPlatform;

          maybeString = str: optionalString (str != null) str;
        in

        {
          src,
          version,
          modDirVersion ? version,

          # Handling of QCDT dt.img
          isQcdt ? false,
          qcdt_dtbs ? "arch/${platform.linuxArch}/boot/",

          # Handling of Exynos dt.img
          isExynosDT ? false,
          exynos_dtbs ? "arch/${platform.linuxArch}/boot/dts/*.dtb",
          exynos_platform ? "0x50a6",
          exynos_subtype ? "0x217584da",

          # Enable support for android-specific "Image.gz-dtb" appended images
          isImageGzDtb ? false,

          # Mark the kernel as compressed, assumes .gz
          isCompressed ? "gz",

          # Enable build of dtbo.img
          dtboImg ? false,

          # Usual stdenv arguments we are also setting.
          # Use the ones given by the user for composition.
          patches ? [ ],
          postPatch ? null,
          postInstall ? null,

          # Part of the usual NixOS kernel builder API
          installsFirmware ? true,
          isModular ? true,
          kernelPatches ? [ ],

          # Used as `.file` on the package to know the kernel image filename.
          kernelFile ? kernelTarget + optionalString isImageGzDtb "-dtb",

          # Used to provide the default kernelFile
          kernelFileExtension ? if isCompressed != false then ".${isCompressed}" else "",
          kernelTarget ?
            if platform.linux-kernel.target == "Image" then
              "${platform.linux-kernel.target}${kernelFileExtension}"
            else
              platform.linux-kernel.target,

          ...
        }@inputArgs:
        let
          hasDTB = platform.linux-kernel ? DTB && platform.linux-kernel.DTB;

          # Merge mobile-nixos specific patches with standard kernelPatches
          allPatches = map (p: p.patch) kernelPatches ++ patches;

          kernelDerivation = buildLinux (
            inputArgs
            // {
              inherit src version modDirVersion;
              inherit
                qcdt_dtbs
                exynos_dtbs
                exynos_platform
                exynos_subtype
                ;

              patches = allPatches;

              postPatch = maybeString postPatch;

              postInstall = ''
                echo ":: Mobile NixOS post-install steps"
              ''
              + optionalString hasDTB ''
                echo ":: Installing DTBs"
                mkdir -p $out/dtbs/
                make $makeFlags "''${makeFlagsArray[@]}" dtbs dtbs_install INSTALL_DTBS_PATH=$out/dtbs

              ''
              + optionalString isQcdt ''
                echo ":: Making and installing QCDT dt.img"
                mkdir -p $out/
                ${dtbTool}/bin/dtbTool -s 2048 -p "scripts/dtc/" \
                  -o "$out/dt.img" \
                  "$qcdt_dtbs"

              ''
              + optionalString isExynosDT ''
                echo ":: Making and installing Exynos dt.img"
                mkdir -p $out/
                ${dtbTool-exynos}/bin/dtbTool-exynos -s 2048 \
                  --platform "$exynos_platform" \
                  --subtype "$exynos_subtype" \
                  -o "$out/dt.img" \
                  $exynos_dtbs

              ''
              + optionalString isImageGzDtb ''
                echo ":: Copying platform-specific -dtb image file"
                cp -v "arch/${platform.linuxArch}/boot/${kernelTarget}-dtb" "$out/"

              ''
              + optionalString (dtboImg != false) ''
                echo ":: Building dtbo.img"
                ${pkgs.android-tools}/bin/mkdtboimg.py create \
                  $out/dtbo.img \
                  $(find arch/*/boot/dts/ -iname '*.dtbo' | sort)
              ''
              + maybeString postInstall;

              inherit isModular installsFirmware;

              passthru =
                let
                  baseVersion = version |> lib.splitString "-rc" |> lib.head;
                in
                {
                  # Used by consumers of the kernel derivation to configure the build
                  # appropriately for different quirks.
                  inherit isQcdt isExynosDT;

                  inherit baseVersion modDirVersion;
                  kernelOlder = lib.versionOlder baseVersion;
                  kernelAtLeast = lib.versionAtLeast baseVersion;

                  # Used by consumers to refer to the kernel build product.
                  file = kernelFile;
                };
            }
          );
        in
        kernelDerivation;
    };
}
