using BinaryBuilder, Pkg

name = "NOMAD"
version = v"4.2.0"

# Collection of sources required to complete build
sources = [
    GitSource("https://github.com/bbopt/nomad.git","02ffde35e70441f9d275f17f952ffc86956c57c1"),
]

# Bash recipe for building across all platforms
script = raw"""
cd "${WORKSPACE}/srcdir/nomad"
mkdir "${WORKSPACE}/path"
export PATH="${WORKSPACE}/path:$PATH}"
mkdir build
cd build
sed s/'set(CMAKE_INSTALL_PREFIX ${PROJECT_BINARY_DIR} CACHE PATH "..." FORCE)'// -i ../CMakeLists.txt
g++ ${WORKSPACE}/srcdir/nomad/src/Attribute/WriteAttributeDefinitionFile.cpp -o ${WORKSPACE}/path/WriteAttributeDefinitionFile
cmake -DBUILD_INTERFACE_C=ON -DTEST_OPENMP=OFF -DCMAKE_INSTALL_PREFIX=${prefix} -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} -DCMAKE_BUILD_TYPE=Release ..
make -j${nproc}
make install
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = expand_cxxstring_abis(supported_platforms())
# The products that we will ensure are always built
products = [
    LibraryProduct("libnomadCInterface", :libnomadCInterface),
    LibraryProduct("libnomadAlgos", :libnomadAlgos),
    LibraryProduct("libnomadEval", :libnomadEval),
    LibraryProduct("libnomadUtils", :libnomadUtils),
    LibraryProduct("libsgtelib", :libsgtelib),
    ExecutableProduct("nomad", :nomad),
]

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency(PackageSpec(name="CompilerSupportLibraries_jll", 
    uuid="e66e0078-7015-5450-92f7-15fbd957f2ae"))
]
# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; preferred_gcc_version = v"12", julia_compat="v1.8")
