{ pkgs }:

pkgs.mkShell {
  packages = with pkgs; [
    git
    git-lfs
    python3
    cmake
    ninja
    pkg-config
    ccache
    lldb
    SDL2
    vulkan-tools
    steam-run

    llvmPackages_18.clang
    llvmPackages_18.lld
  ];

  shellHook = ''
    export CC=clang
    export CXX=clang++
    export CCACHE_DIR="$HOME/.cache/ccache"
  '';
}
