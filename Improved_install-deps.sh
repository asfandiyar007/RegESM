#!/bin/bash
set -eo pipefail

# Function to check if a directory exists
check_dir() {
    if [ ! -d "$1" ]; then
        echo "Error: Directory $1 does not exist."
        exit 1
    fi
}

# Function to safely move files
safe_move() {
    if [ -e "$2" ]; then
        echo "Warning: $2 already exists. Creating backup."
        mv "$2" "${2}.bak"
    fi
    mv "$1" "$2"
}

PROGS=$1
OCN_LINK=$2
RTM_LINK=$3
WAV_LINK=$4

# Check if PROGS directory exists
check_dir "$PROGS"

#------------------------------------
# parameters
ZLIB_VER="1.2.8"
HDF5_VER="1.8.16"
NCCC_VER="c-4.9.2"
NCXX_VER="cxx4-4.3.1"
NCFC_VER="4.6.1"
XERC_VER="3.2.5"
OMPI_VER="1.10.2"
ESMF_VER="7_0_0"

# compilers
CC=${CC:-gcc}
FC=${FC:-gfortran}
CXX=${CXX:-g++}

export CC=$CC
export FC=$FC
export CXX=$CXX

# arch
gcc -march=native -Q --help=target

# Function to download and extract
download_and_extract() {
    local url=$1
    local filename=$(basename "$url")
    
    if [ ! -f "$filename" ]; then
        wget "$url"
    else
        echo "$filename already exists. Skipping download."
    fi
    
    tar -zxvf "$filename" > extract.log
    rm -f "$filename"
}

# install zlib
cd "${PROGS}"
download_and_extract "https://github.com/madler/zlib/archive/v${ZLIB_VER}.tar.gz"
cd "zlib-${ZLIB_VER}"
./configure --prefix="${PROGS}/zlib-${ZLIB_VER}"
make > make.log 
make install >> make.log
cd ..
safe_move extract.log "${PROGS}/zlib-${ZLIB_VER}/extract.log"

export ZLIB="${PROGS}/zlib-${ZLIB_VER}"
export LD_LIBRARY_PATH="${PROGS}/zlib-${ZLIB_VER}/lib:${LD_LIBRARY_PATH}"

# install hdf5
cd "${PROGS}"
download_and_extract "https://support.hdfgroup.org/ftp/HDF5/releases/hdf5-1.8/hdf5-${HDF5_VER}/src/hdf5-${HDF5_VER}.tar.gz"
cd "hdf5-${HDF5_VER}"
./configure --prefix="${PROGS}/hdf5-${HDF5_VER}" --with-zlib="${PROGS}/zlib-${ZLIB_VER}" --enable-fortran --enable-cxx CC="${CC}" FC="${FC}" CXX="${CXX}"
make > make.log
make install >> make.log
cd ..
safe_move extract.log "${PROGS}/hdf5-${HDF5_VER}/extract.log"

export HDF5="${PROGS}/hdf5-${HDF5_VER}"
export PATH="${HDF5}/bin:${PATH}"
export LD_LIBRARY_PATH="${HDF5}/lib:${LD_LIBRARY_PATH}"


# install netcdf c
check_dir "${PROGS}"
mkdir -p "${PROGS}/netcdf-${NCCC_VER}"
cd "${PROGS}/netcdf-${NCCC_VER}"
download_and_extract "https://downloads.unidata.ucar.edu/netcdf-c/4.9.2/netcdf-${NCCC_VER}.tar.gz"
safe_move "netcdf-${NCCC_VER}" src
cd src
./configure --prefix="${PROGS}/netcdf-${NCCC_VER}" CC="${CC}" FC="${FC}" \
    LDFLAGS="-L${PROGS}/zlib-${ZLIB_VER}/lib -L${PROGS}/hdf5-${HDF5_VER}/lib" \
    CPPFLAGS="-I${PROGS}/zlib-${ZLIB_VER}/include -I${PROGS}/hdf5-${HDF5_VER}/include"
make > make.log
make install >> make.log

export NETCDF="${PROGS}/netcdf-${NCCC_VER}"
export PATH="${NETCDF}/bin:${PATH}"
export LD_LIBRARY_PATH="${NETCDF}/lib:${LD_LIBRARY_PATH}"

# install netcdf c++
check_dir "${PROGS}"
mkdir -p "${PROGS}/netcdf-${NCXX_VER}"
cd "${PROGS}/netcdf-${NCXX_VER}"
download_and_extract "https://downloads.unidata.ucar.edu/netcdf-cxx/4.3.1/netcdf-cxx4-4.3.1.tar.gz"
safe_move "netcdf-${NCXX_VER}" src
cd src
./configure --prefix="${PROGS}/netcdf-${NCXX_VER}" CC="${CC}" CXX="${CXX}" \
    LDFLAGS="-L${PROGS}/zlib-${ZLIB_VER}/lib -L${PROGS}/hdf5-${HDF5_VER}/lib -L${PROGS}/netcdf-${NCCC_VER}/lib" \
    CPPFLAGS="-I${PROGS}/zlib-${ZLIB_VER}/include -I${PROGS}/hdf5-${HDF5_VER}/include -I${PROGS}/netcdf-${NCCC_VER}/include"
make > make.log
make install >> make.log

# install netcdf fortran
check_dir "${PROGS}"
mkdir -p "${PROGS}/netcdf-fortran-${NCFC_VER}"
cd "${PROGS}/netcdf-fortran-${NCFC_VER}"
download_and_extract "https://downloads.unidata.ucar.edu/netcdf-fortran/4.6.1/netcdf-fortran-4.6.1.tar.gz"
safe_move "netcdf-fortran-${NCFC_VER}" src
cd src
./configure --prefix="${PROGS}/netcdf-fortran-${NCFC_VER}" CC="${CC}" FC="${FC}" \
    LDFLAGS="-L${PROGS}/zlib-${ZLIB_VER}/lib -L${PROGS}/hdf5-${HDF5_VER}/lib -L${PROGS}/netcdf-${NCCC_VER}/lib" \
    CPPFLAGS="-I${PROGS}/zlib-${ZLIB_VER}/include -I${PROGS}/hdf5-${HDF5_VER}/include -I${PROGS}/netcdf-${NCCC_VER}/include"
make > make.log
make install >> make.log

# link netcdf c++ and fortran to c
check_dir "${PROGS}/netcdf-${NCCC_VER}/bin"
ln -sf ../../netcdf-fortran-${NCFC_VER}/bin/* "${PROGS}/netcdf-${NCCC_VER}/bin/"

check_dir "${PROGS}/netcdf-${NCCC_VER}/lib"
ln -sf ../../netcdf-cxx-${NCXX_VER}/lib/* "${PROGS}/netcdf-${NCCC_VER}/lib/"
rm -rf "${PROGS}/netcdf-${NCCC_VER}/lib/pkgconfig"
ln -sf ../../netcdf-fortran-${NCFC_VER}/lib/* "${PROGS}/netcdf-${NCCC_VER}/lib/"

check_dir "${PROGS}/netcdf-${NCCC_VER}/include"
ln -sf ../../netcdf-cxx-${NCXX_VER}/include/* "${PROGS}/netcdf-${NCCC_VER}/include/"
ln -sf ../../netcdf-fortran-${NCFC_VER}/include/* "${PROGS}/netcdf-${NCCC_VER}/include/"

# install xerces
check_dir "${PROGS}"
cd "${PROGS}"
download_and_extract "http://ftp.itu.edu.tr/Mirror/Apache//xerces/c/3/sources/xerces-c-${XERC_VER}.tar.gz"
cd "xerces-c-${XERC_VER}"
./configure --prefix="${PROGS}/xerces-c-${XERC_VER}" CC="${CC}" CXX="${CXX}"
make > make.log
make install >> make.log
cd "${PROGS}"
safe_move extract.log "${PROGS}/xerces-c-${XERC_VER}/extract.log"

export XERCES="${PROGS}/xerces-c-${XERC_VER}"
export LD_LIBRARY_PATH="${XERCES}/lib:${LD_LIBRARY_PATH}"

# install openmpi
check_dir "${PROGS}"
cd "${PROGS}"
download_and_extract "https://www.open-mpi.org/software/ompi/v1.10/downloads/openmpi-${OMPI_VER}.tar.gz"
cd "openmpi-${OMPI_VER}"
./configure --prefix="${PROGS}/openmpi-${OMPI_VER}" CC="${CC}" CXX="${CXX}" FC="${FC}"
make > make.log
make install >> make.log
cd "${PROGS}"
safe_move extract.log "${PROGS}/openmpi-${OMPI_VER}/extract.log"

export PATH="${PROGS}/openmpi-${OMPI_VER}/bin:${PATH}"
export LD_LIBRARY_PATH="${PROGS}/openmpi-${OMPI_VER}/lib:${LD_LIBRARY_PATH}"

# install esmf
check_dir "${PROGS}"
cd "${PROGS}"
download_and_extract "https://sourceforge.net/projects/esmf/files/ESMF_${ESMF_VER}/esmf_${ESMF_VER}_src.tar.gz"
safe_move "esmf" "esmf-${ESMF_VER//_/.}"
cd "esmf-${ESMF_VER//_/.}"

# ESMF environment variables
declare -A esmf_vars=(
    ["ESMF_DIR"]="${PROGS}/esmf-${ESMF_VER//_/.}"
    ["ESMF_INSTALL_PREFIX"]="${PROGS}/esmf-${ESMF_VER//_/.}/install_dir"
    ["ESMF_OS"]="Linux"
    ["ESMF_TESTMPMD"]="OFF"
    ["ESMF_TESTHARNESS_ARRAY"]="RUN_ESMF_TestHarnessArray_default"
    ["ESMF_TESTHARNESS_FIELD"]="RUN_ESMF_TestHarnessField_default"
    ["ESMF_TESTWITHTHREADS"]="OFF"
    ["ESMF_COMM"]="openmpi"
    ["ESMF_TESTEXHAUSTIVE"]="ON"
    ["ESMF_BOPT"]="O"
    ["ESMF_OPENMP"]="OFF"
    ["ESMF_SITE"]="default"
    ["ESMF_ABI"]="64"
    ["ESMF_COMPILER"]="$([[ $FC == gfortran ]] && echo gfortran || echo intel)"
    ["ESMF_PIO"]="internal"
    ["ESMF_NETCDF"]="split"
    ["ESMF_NETCDF_INCLUDE"]="${NETCDF}/include"
    ["ESMF_NETCDF_LIBPATH"]="${NETCDF}/lib"
    ["ESMF_XERCES"]="standard"
    ["ESMF_XERCES_INCLUDE"]="${XERCES}/include"
    ["ESMF_XERCES_LIBPATH"]="${XERCES}/lib"
)

# Export ESMF environment variables
for var in "${!esmf_vars[@]}"; do
    export "$var"="${esmf_vars[$var]}"
done

# Set ESMF_LIB after other variables are set
export ESMF_LIB="${ESMF_INSTALL_PREFIX}/lib/lib${ESMF_BOPT}/${ESMF_OS}.${ESMF_COMPILER}.${ESMF_ABI}.${ESMF_COMM}.${ESMF_SITE}"

# Build and install ESMF
make info > make_info.log
make > make.log
make install >> make.log

# Move back to PROGS directory and save extract log
cd "${PROGS}"
safe_move extract.log "${PROGS}/esmf-${ESMF_VER//_/.}/extract.log"


# create file for environment variables
cd "${PROGS}"
cat > env_progs << EOL
export CC=$CC
export FC=$FC
export CXX=$CXX
export PROGS=${PROGS}
export ZLIB=${PROGS}/zlib-${ZLIB_VER}
export HDF5=${PROGS}/hdf5-${HDF5_VER}
export NETCDF=${PROGS}/netcdf-${NCCC_VER}
export XERCES=${PROGS}/xerces-c-${XERC_VER}
export ESMF_OS=Linux
export ESMF_TESTMPMD=OFF
export ESMF_TESTHARNESS_ARRAY=RUN_ESMF_TestHarnessArray_default
export ESMF_TESTHARNESS_FIELD=RUN_ESMF_TestHarnessField_default
export ESMF_DIR=${PROGS}/esmf-${ESMF_VER//_/.}
export ESMF_TESTWITHTHREADS=OFF
export ESMF_INSTALL_PREFIX=${PROGS}/esmf-${ESMF_VER//_/.}/install_dir
export ESMF_COMM=openmpi
export ESMF_TESTEXHAUSTIVE=ON
export ESMF_BOPT=O
export ESMF_OPENMP=OFF
export ESMF_SITE=default
export ESMF_ABI=64
export ESMF_COMPILER=$([ "$FC" == "gfortran" ] && echo "gfortran" || echo "intel")
export ESMF_PIO=internal
export ESMF_NETCDF=split
export ESMF_NETCDF_INCLUDE=${NETCDF}/include
export ESMF_NETCDF_LIBPATH=${NETCDF}/lib
export ESMF_XERCES=standard
export ESMF_XERCES_INCLUDE=${XERCES}/include
export ESMF_XERCES_LIBPATH=${XERCES}/lib
export ESMF_LIB=${ESMF_INSTALL_PREFIX}/lib/lib${ESMF_BOPT}/${ESMF_OS}.${ESMF_COMPILER}.${ESMF_ABI}.${ESMF_COMM}.${ESMF_SITE}
export ESMFMKFILE=${ESMF_LIB}/esmf.mk
export PATH=${HDF5}/bin:${NETCDF}/bin:${ESMF_DIR}/apps/apps${ESMF_BOPT}/${ESMF_OS}.${ESMF_COMPILER}.${ESMF_ABI}.${ESMF_COMM}.${ESMF_SITE}:${ESMF_INSTALL_PREFIX}/bin/bin${ESMF_BOPT}/${ESMF_OS}.${ESMF_COMPILER}.${ESMF_ABI}.${ESMF_COMM}.${ESMF_SITE}:${PATH}
export LD_LIBRARY_PATH=${ZLIB}/lib:${HDF5}/lib:${NETCDF}/lib:${XERCES}/lib:${ESMF_LIB}:${LD_LIBRARY_PATH}
EOL

echo "Installation and setup complete. Environment variables have been written to ${PROGS}/env_progs"
