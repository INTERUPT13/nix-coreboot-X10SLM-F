
{
  # what depth is this, we should just need 1
  inputs = {
    nixpkgs.url = github:NixOS/nixpkgs;
    coreboot-src = {
      #url = "https://github.com/INTERUPT13/coreboot-nix-patches.git";
      url = "https://review.coreboot.org/coreboot.git";
      #ref = "nix-patches-experimental";
      flake = false;
      type = "git";
      # TODO do we need this?
      submodules = true;
    };

    seabios-src = {
      url = "https://review.coreboot.org/seabios.git";
      #ref = "coreboot";
      flake = false;
      type = "git";
    };
  };


  outputs = {self, nixpkgs, coreboot-src, seabios-src }: 
      with import nixpkgs { system = "x86_64-linux"; };
  let

    corebootEnv = pkgs.buildFHSUserEnv {
      name = "coreboot-env";
      targetPkgs = pkgs: [ 
        binutils
        gnumake
        coreutils
        patch
        zlib
        zlib.dev
        curl
        git
        m4
        bison
        flex
      ];
    };

  gmpTarName = "gmp-6.2.1.tar.xz";
  gmpTar = pkgs.fetchurl {
    url = "https://ftpmirror.gnu.org/gmp/${gmpTarName}";
    sha256 = "/UgpkSzd0S+EGBw0Ucx1K+IkZD6H+sSXtp7d2txJtPI=";
  };

  mpfrTarName = "mpfr-4.1.0.tar.xz";
  mpfrTar = pkgs.fetchurl {
    url = "https://ftpmirror.gnu.org/mpfr/${mpfrTarName}";
    sha256 = "0zwaanakrqjf84lfr5hfsdr7hncwv9wj0mchlr7cmxigfgqs760c";
  };

  mpcTarName = "mpc-1.2.1.tar.gz";
  mpcTar = pkgs.fetchurl {
    url = "https://ftpmirror.gnu.org/mpc/${mpcTarName}";
    sha256 = "F1A9LDld/PEGtiLcFCaDwRmUMdCVNnxqrLpu7DA0BFk=";
  };
  
  binutilsTarName = "binutils-2.37.tar.xz";
  binutilsTar = pkgs.fetchurl {
    url = "https://ftpmirror.gnu.org/binutils/${binutilsTarName}";
    sha256 = "gg2XJPAgo+acszeJOgtjwtsWHa3LDgb8Edwp6x6Eoyw=";
  };

  gccVersion = "11.2.0";
  gccTarName = "gcc-${gccVersion}.tar.xz";
  gccTar = pkgs.fetchurl {
    url = "https://ftpmirror.gnu.org/gcc/gcc-${gccVersion}/${gccTarName}";
    sha256 = "0I7cU2tUw3KhAQ/2YZ3SdMDxYDqkkhK6IPeqLNo2+os=";
  };

  nasmVersion = "2.15.05";
  nasmTarName = "nasm-${nasmVersion}.tar.bz2";
  nasmTar = pkgs.fetchurl {
    url = "https://www.nasm.us/pub/nasm/releasebuilds/${nasmVersion}/${nasmTarName}";
    sha256 = "PEuDOeWrVLG8sjFhAfiYWl2lCj+eUE1D+m81ZovuL9A=";
  };

  acpicaTarName = "acpica-unix2-20211217.tar.gz";
  acpicaTar = pkgs.fetchurl {
    url = "https://acpica.org/sites/acpica/files/${acpicaTarName}";
    sha256 = "JIWfiJGVI4/7eQylvgjFz03fBorCKftuBRF+wVWFQRQ=";
  };


  in {
    packages.x86_64-linux."coreboot-toolchain-x86" = 
      with import nixpkgs { system = "x86_64-linux"; };
      stdenv.mkDerivation {
        name = "coreboot-toolchain-x86";

        src = coreboot-src;

        #buildPhase = 
        #  let buildScript = writeText "" ''
        #    export PATH=/bin:/sbin:/usr/bin:/usr/sbin

        #    export -p $out
        #    make crossgcc-i386 CPUS=$(nproc) DEST=$out
        #  ''; in
        #  ''
        #    coreboot-env ${buildScript}
        #  '';

        postUnpack = ''
          tar --version
          cd source
          mkdir -p util/crossgcc/tarballs
          ln -s ${gmpTar} util/crossgcc/tarballs/${gmpTarName}
          ln -s ${mpfrTar} util/crossgcc/tarballs/${mpfrTarName}
          ln -s ${mpcTar} util/crossgcc/tarballs/${mpcTarName}
          ln -s ${binutilsTar} util/crossgcc/tarballs/${binutilsTarName}
          ln -s ${gccTar} util/crossgcc/tarballs/${gccTarName}
          ln -s ${nasmTar} util/crossgcc/tarballs/${nasmTarName}
          ln -s ${acpicaTar} util/crossgcc/tarballs/${acpicaTarName}


          echo pigz
          grep -lir pigz 

          cd .. #todo can we remove this?
        '';
            
        # TODO can we remove this later on :(
        hardeningDisable = [ "format" ];

        buildPhase = 
          let buildScript = writeText "" ''
            #export PATH=/bin:/sbin:/usr/bin:/usr/sbin


            make crossgcc-i386 CPUS=$(nproc) DEST=$out
          ''; in
          ''
            sh ${buildScript}
          '';

        nativeBuildInputs = [
        
          # won't work on all kernels
          #corebootEnv

          autoPatchelfHook

          
          binutils
          gnumake
          coreutils
          patch
          zlib
          zlib.dev
          curl
          git
          m4
          bison
          flex

          pigz
          lbzip2
        ];

        buildInputs = [
          bison
          flex
          util-linux

          flex
          zlib
          gcc.cc.lib
        ];



        installPhase = "
          #mkdir $out
          echo done
        ";

    };
    


    #defaultPackage.x86_64-linux  =  self.packages.x86_64-linux."coreboot-toolchain-x86";


    defaultPackage.x86_64-linux  =
      with import nixpkgs { system = "x86_64-linux"; };
      stdenv.mkDerivation {
        name = "coreboot-X10-SLM+F";

        nativeBuildInputs = [
          self.packages.x86_64-linux.coreboot-toolchain-x86
          git
        ];

        src = coreboot-src;

        unpackPhase = ''
          #ls -la ${seabios-src}
          cp -r ${coreboot-src}/. .
          chmod u+w -R .
          cp -r ${seabios-src} payloads/external/SeaBIOS/seabios
          chmod u+w -R .
          #git init payloads/external/SeaBIOS/seabios
        '';

        buildPhase = ''
          cp ${self}/X10-SLM+F.config .config
          chmod u+w .config
          
          touch mrc.bin
          make -j $(nproc) CPUS=$(nproc)
        '';



        installPhase = "
          mkdir -p $out
          cp build/coreboot.rom $out
        ";
    };
  };
}
