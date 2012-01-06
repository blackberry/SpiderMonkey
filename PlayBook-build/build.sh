#!/bin/bash

build_spidermonkey_for_playbook()
{
    ###########################################################################
    # Setup environment                                                       #
    ###########################################################################
    set -e

    local BUILD_ROOT=`pwd`

    ###########################################################################
    # Setup PlayBook Environment Variables                                    #
    ###########################################################################

    # ensure required BBNDK env variables are set
    : ${QNX_HOST:?"Error: QNX_HOST environment variable is not set."}
    : ${QNX_TARGET:?"Error: QNX_TARGET environment variable is not set."}

    #set up env for cross-compiling for PlayBook
    export PATH=$QNX_HOST/usr/bin:$PATH
    export CC="$QNX_HOST/usr/bin/qcc -V4.4.2,gcc_ntoarmv7le_cpp "
    export CFLAGS="-V4.4.2,gcc_ntoarmv7le_cpp -g "
    export CPP="$QNX_HOST/usr/bin/qcc -V4.4.2,gcc_ntoarmv7le_cpp -E"
    export LD="$QNX_HOST/usr/bin/ntoarmv7-ld "
    export RANLIB="$QNX_HOST/usr/bin/ntoarmv7-ranlib "
    export AR="$QNX_HOST/usr/bin/ntoarmv7-ar "

    ###########################################################################
    # Build SpiderMonkey 1.8.0                                                #   
    ###########################################################################
    pushd $BUILD_ROOT/../js/src

    export JS_INSTALL_DIR=$BUILD_ROOT
    local JS_TARGET=arm-unknown-nto-qnx6.5.0eabi
    export SPIDERMONKEY_TARGET_OS=QNX
    export LDFLAGS="-L$QNX_TARGET/armle-v7/usr/lib -L$QNX_TARGET/armle-v7/lib"
    export CPPFLAGS="-D__QNXNTO__ -I$QNX_TARGET/usr/include -I$QNX_TARGET/usr/local/include"

    # Build release version
    export BUILD_OPT=1

    # Will use provided jsautocfg.h
    export PREBUILT_CPUCFG=1

    export CPPFLAGS="$CPPFLAGS -Wall"
    export HOST_CC="/usr/bin/gcc"
    export HOST_CFLAGS=""
    export HOST_LDFLAGS=" "
    export HOST_AR=/usr/bin/ar
    export HOST_RANLIB=/usr/bin/ranlib

    if [ ! -d $JS_INSTALL_DIR/bin ] ; then
        mkdir -p $JS_INSTALL_DIR/bin
    fi

    if [ ! -d $JS_INSTALL_DIR/lib ] ; then
        mkdir -p $JS_INSTALL_DIR/lib
    fi

    if [ ! -d QNX6.6.0_OPT.OBJ ] ; then
        mkdir QNX6.6.0_OPT.OBJ
    fi

    # Copy the prebuilt CPU config file
    cp $BUILD_ROOT/jsautocfg.h .

    # build fails with -j8 option
    make -f Makefile.ref all install

    # couchdb looks for libmozjs.so, but SpiderMonkey 1.8.0 creates libjs.so. Link the one it's looking for to the one that's created.
    pushd $JS_INSTALL_DIR/lib
    if [ -f libmozjs.so ]; then
        rm -f libmozjs.so
    fi
    ln -s libjs.so libmozjs.so
    popd
}

build_spidermonkey_for_playbook
