#!/bin/bash

# SPDX-FileCopyrightText: 2025 Smooth-E
# SPDX-License-Identifier: GPL-3.0-or-later

# Example project used as reference:
# https://gitlab.com/omprussia/python/PySideWithSystemQt/-/blob/c25aa8da4c280246f5ea1f5959a3344ec889a1ff/build_python3.sh

target=""
arch=""
cpython_version="3.13"
# cpython_enable_optimizations="--enable-optimizations"
cpython_enable_optimizations=""

help()
{
   # Display Help
   echo "Syntax: prepare [-t <TARGET>|-h]"
   echo "options:"
   echo "  -t   Set the target to build. Example: AuroraOS-5.1.1.60-base-armv7hl."
   echo "  -h   Print this help."
   echo
}

init_target_vars()
{
	# Initialize the $target and $arch variables
	target=$OPTARG
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
	qt5-qttools-qtuiplugin-devel sqlite-devel || exit 1
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
	  ../configure --prefix=$(pwd)/../../../vendor/$arch --enable-shared $cpython_enable_optimizations && \
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
    # This is needed when running this function by itself
    mkdir -p libs/cpython/build/

    sb2 -t $target bash -c "$(pwd)/vendor/$arch/bin/python3 -m \
        pip install -t $(pwd)/vendor/$arch/lib/python$cpython_version/site-packages/ pydub || exit 1"
}

build_ffmpeg() {
    echo Building ffmpeg...

    cd libs/ffmpeg
    mkdir -p build
    cd build

    build_flags=$(sb2 -t $target rpm --eval '%set_build_flags')

    sb2 -t $target bash -c "\
        echo Building ffmpeg: build_flags && \
        $build_flags && \
        echo Building ffmpeg: configure... && \
        ../configure --prefix=$(pwd)/../../../vendor/$arch \
                     --enable-shared \
                     --disable-ffplay \
                     --disable-ffprobe \
                     --disable-doc && \
        echo Building ffmpeg: make... && \
        make -j$(nproc --all) && \
        echo Building ffmpeg: make install... && \
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

while getopts ":t:h" option; do
   case $option in
      (t) # build stuff
      	init_target_vars
        install_dependencies
        build_cpython
        build_pyotherside
        install_pydub
        build_ffmpeg
        clear;;
      (h) # display help
        help;;
      (*)
        help
   esac
done

if [ $OPTIND -eq 1 ]
then 
	help;
fi
