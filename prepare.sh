#!/bin/bash

# SPDX-FileCopyrightText: 2025 Smooth-E
# SPDX-License-Identifier: GPL-3.0-or-later

# Example project used as reference:
# https://gitlab.com/omprussia/python/PySideWithSystemQt/-/blob/c25aa8da4c280246f5ea1f5959a3344ec889a1ff/build_python3.sh

target=""
arch=""
cpython_version="3.8"
package_name="moe.smoothie.audioworks"

# The following vars are controlled by arguments
select_all=1
select_cpython=
select_pyotherside=
select_pydub=
select_ffmpeg=
select_lame=
cpython_enable_optimizations=""

help()
{
   # Display Help
   echo "Syntax: prepare REQUIRED [SELECTIVE] [EXTRA]"
   echo "Required args. You need to specify on of the following args:"
   echo "  -t   Set the target to build. Example: AuroraOS-5.1.1.60-base-armv7hl."
   echo "  -h   Print this help."
   echo "Selective build. If one of the below options is present, only execute selected steps."
   echo "  --build-cpython      Build cpython."
   echo "  --build-pyotherside  Build pyotherside."
   echo "  --install-pydub      Copy pydub module files into vendor."
   echo "  --build-ffmpeg       Build FFmpeg libraries and programs."
   echo "  --build-lame         Build LAME MP3 encoder."
   echo "Extra opts:"
   echo "  --enable-optimizations  Pass --enable-optimizations to ./configure when building cpython for aarch64/x86_64."  
   echo
}

init_target_vars()
{
	# Initialize the $target and $arch variables
	# target=$OPTARG
	arch=$(echo ${target##*-})

	if [ "$arch" = "armv7hl" ]; then
        # Cmake defines the architecture of target AuroraOS-5.1.1.60-base-armv7hl as armv7l.
	    # Need to rename it for the correct project building
		arch="armv7l"
        # Tests fail when building cpython with --enable-optimizations in Aurora Platform SDK 5.1.5.105 for armv7hl
        cpython_enable_optimizations=""
	fi
}

install_dependencies()
{
	sb2 -t $target -R zypper install -y libopenssl-devel \
	libxml2-devel libxslt-devel qt5-qtprintsupport-devel \
	qt5-qttools-qtdesigner qt5-qttools-qtdesigner-devel \
	qt5-qttools-qtuitools-devel libqtwebkit5-widgets-devel \
	qt5-qtscript-devel qt5-qttools-qthelp-devel \
	qt5-qtwebsockets-devel qt5-qttest-devel \
	qt5-qttools-qtuiplugin-devel \
    sqlite-devel mpg123-devel libvorbis-devel || exit 1
}

build_cpython()
{
    echo Building cpython...

    # Create output directory
    mkdir -p vendor/$arch

    # Someone refers to this as 'shadow' build
    cd libs/cpython
    mkdir -p build
    cd build

    # Obtain build flags
    build_flags=$(sb2 -t $target rpm --eval '%set_build_flags')
    echo Obtained build flags: $build_flags

    # Build cpython with mb2
    sb2 -t $target bash -c "$build_flags && \
	  ../configure --prefix=$(pwd)/../../../vendor/$arch \
                   --enable-shared $cpython_enable_optimizations \
                   LDFLAGS='$LDFLAGS -Wl,-rpath /usr/share/$package_name/lib/python$python_version/lib-dynload/' && \
	  make -j$(nproc --all) && \
	  make install || exit 1"

      # Return to project root
      cd ../../../
}

build_pyotherside()
{
    echo Building pyotherside...

    mkdir -p vendor/$arch
    
    cd libs/pyotherside
    mkdir -p build
    cd build

    build_flags=$(sb2 -t $target rpm --eval '%set_build_flags')

    sb2 -t $target bash -c " \
        echo Building pyotherside: build_flags... && \
        $build_flags && \
        echo Building pyotherside: qmake... && \
        qmake PREFIX=$(pwd)/../../../vendor/$arch/ \
              INCLUDEPATH+=$(pwd)/../../../vendor/$arch/include/python$cpython_version/ \
              LIBS+=-L$(pwd)/../../../vendor/$arch/lib/ .. && \
        echo Building pyotherside: make... && \
        PATH=$(pwd)/../../../vendor/$arch/bin/:$PATH make -j$(nproc --all) && \
        echo Building pyotherside: make install... && \
        make INSTALL_ROOT=$(pwd)/../../../vendor/$arch/ install || exit 1"

    # Return to project root
    cd ../../../
}

install_pydub() {
    echo Copying pydub module into vendor/site-packages
    rm -rf vendor/$arch/lib/python$cpython_version/pydub
    cp -r libs/pydub/pydub vendor/$arch/lib/python$cpython_version/ || exit 1
}

build_ffmpeg() {
    echo Building ffmpeg...

    cd libs/ffmpeg
    mkdir -p build
    cd build

    build_flags=$(sb2 -t $target rpm --eval '%set_build_flags')

    sb2 -t $target bash -c "\
        echo Building ffmpeg: build_flags... && \
        $build_flags && \
        echo Building ffmpeg: configure... && \
        ../configure --prefix=$(pwd)/../../../vendor/$arch \
                     --enable-shared \
                     --enable-libvorbis \
                     --disable-ffplay \
                     --disable-doc && \
        echo Building ffmpeg: make... && \
        make -j$(nproc --all) && \
        echo Building ffmpeg: make install... && \
        make install || exit 1"
    
    cd ../../../
}

build_lame()
{
    echo Building lame...

    cd libs/lame
    mkdir -p build
    cd build

    build_flags=$(sb2 -t $target rpm --eval '%set_build_flags')

    sb2 -t $target bash -c " \
        echo Building lame: build_flags... && \
        $build_flags && \
        echo Building lame: configure... && \
        ../configure --prefix=$(pwd)/../../../vendor/$arch && \
        echo Building lame: make... && \
        make -j$(nproc --all) && \
        echo Building lame: make install... && \
        make install || exit 1"
    
    cd ../../../
}

clear()
{
	echo "Clear build folders..."

    # Remove build dirs
    cd libs
	rm -rf cpython/build
    rm -rf pyotherside/build
    rm -rf ffmpeg/build
    cd ..

    # Remove pycache folders
	cd vendor
	find . -type d -name __pycache__ -exec rm -r {} +

    # Return to project root
	cd ..
}

if [[ $# = 0 ]];
then 
	help;
    exit 0;
fi

while [[ $# -gt 0 ]]; do
    case $1 in 
        (-t)
            target="$2"
            shift
            shift
        ;;
        (--build-cpython)
            select_cpython=1
            select_all=0
            shift
        ;;
        (--build-pyotherside)
            select_pyotherside=1
            select_all=0
            shift
        ;;
        (--install-pydub)
            select_pydub=1
            select_all=0
            shift
        ;;
        (--build-ffmpeg)
            select_ffmpeg=1
            select_all=0
            shift
        ;;
        (--build-lame)
            select_lame=1
            select_all=0
            shift
        ;;
        (--enable-optimizations)
            cpython_enable_optimizations="--enable-optimizations"
            shift
        ;;
        (-h)
            help
            exit 0
        ;;
        (*)
            echo Unsupported argument: $1
            echo
            help
            exit 1
        ;;
    esac
done

init_target_vars
install_dependencies
if (( select_all || select_cpython )); then build_cpython; fi
if (( select_all || select_pydub )); then install_pydub; fi
if (( select_all || select_pyotherside )); then build_pyotherside; fi
if (( select_all || select_ffmpeg )); then build_ffmpeg; fi
if (( select_all || select_lame )); then build_lame; fi
clear
