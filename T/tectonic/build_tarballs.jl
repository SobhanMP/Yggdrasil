# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "tectonic"
version = v"0.9.0"

# Collection of sources required to build tar
sources = [
    ArchiveSource(
        "https://github.com/tectonic-typesetting/tectonic/archive/tectonic@$(version).tar.gz",
        "a239ca85bff1955792b2842fabfa201ba9576d916ece281278781f42c7547b9f"
    )
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/tectonic-*/

if [[ "${target}" == *-mingw* ]]; then
    export RUSTFLAGS="-Clink-args=-L${libdir}"
fi

cargo build --release --locked --features external-harfbuzz
cp target/${rust_target}/release/tectonic${exeext} ${bindir}/
"""

# Some platforms disabled for now due issues with rust and musl cross compilation. See #1673.
platforms = supported_platforms(; experimental=true)
# We dont have all dependencies for armv6l
filter!(p -> arch(p) != "armv6l", platforms)
# Rust toolchain for i686 Windows is unusable
filter!(p -> !Sys.iswindows(p) || arch(p) != "i686", platforms)
platforms = expand_cxxstring_abis(platforms)

# The products that we will ensure are always built
products = [
    ExecutableProduct("tectonic", :tectonic),
]

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency("Fontconfig_jll"),
    Dependency("FreeType2_jll"),
    Dependency("Graphite2_jll"),
    Dependency("HarfBuzz_jll"; compat="2.8.1"),
    Dependency("HarfBuzz_ICU_jll"),
    Dependency("ICU_jll"; compat="69.1"),
    Dependency("OpenSSL_jll"),
    Dependency("Zlib_jll"),
    Dependency("libpng_jll"),
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; compilers=[:c, :rust], preferred_gcc_version=v"7", lock_microarchitecture=false, julia_compat="1.6")
