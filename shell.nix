with import <nixpkgs> { };
mkShellNoCC {
  buildInputs = [
    neovim
    gnat11 # gcc with ada
    #gnatboot # gnat1
    ncurses # make menuconfig
    m4 flex bison # Generate flashmap descriptor parser
    #clang
    zlib
    #acpica-tools # iasl
    pkgconfig
    qemu # test the image
  ];
  shellHook = ''
    # TODO remove?
    NIX_LDFLAGS="$NIX_LDFLAGS -lncurses"
  '';
}
