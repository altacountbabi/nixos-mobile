{
  perSystem =
    { pkgs, lib, ... }:
    {
      packages.dtbtool =
        let
          inherit (pkgs)
            stdenv
            fetchurl
            python3
            python3Packages
            ;
          inherit (pkgs.buildPackages) dtc;
        in
        stdenv.mkDerivation {
          name = "dtbtool";
          version = "1.6.0";

          src = fetchurl {
            url = "https://source.codeaurora.org/quic/kernel/skales/plain/dtbTool?id=1.6.0";
            sha256 = "0lbzpqbar0fr9y53v95v0yrrn2pnm8m1wj43h3l83f7awqma68x2";
          };

          patches = [
            ./00_fix_version_detection.patch
            ./01_find_dtb_in_subfolders.patch
          ];

          buildInputs = [
            python3
          ];

          nativeBuildInputs = [
            python3Packages.wrapPython
            dtc
          ];

          pythonPath = [ dtc ];

          postPatch = ''
            substituteInPlace dtbTool \
              --replace "libfdt.so" "${dtc}/lib/libfdt.so"
          '';

          unpackCmd = "mkdir out; cp $curSrc out/dtbTool";

          installPhase = ''
            patchShebangs ./
            mkdir -p $out/bin
            cp -v dtbTool $out/bin/
            chmod +x $out/bin/dtbTool
            wrapPythonPrograms
          '';

          meta = with lib; {
            homepage = "https://source.codeaurora.org/quic/kernel/skales/plain/dtbTool";
            description = "Tool for compiling device tree blobs (dtb)";
            license = licenses.bsd3;
            platforms = platforms.unix;
            mainProgram = "dtbTool";
            longDescription = ''
              dtbTool is a utility for compiling device tree blobs (dtb) used in 
              Linux kernel device tree management, particularly for embedded systems 
              and mobile devices.
            '';
          };
        };
    };
}
