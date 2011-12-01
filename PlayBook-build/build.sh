#!/bin/bash

build_spidermonkey_for_playbook()
{
    ###########################################################################
    # Setup environment                                                       #
    ###########################################################################
    set -e

    source bbndk.env

    local BUILD_ROOT=`pwd`

    ###########################################################################
    # Setup PlayBook Environment Variables                                    #
    ###########################################################################

    # ensure required BBNDK env variables are set
    : ${BBNDK_DIR:?"Error: BBNDK_DIR environment variable is not set."}
    : ${BBNDK_HOST:?"Error: BBNDK_HOST environment variable is not set."}
    : ${BBNDK_TARGET:?"Error: BBNDK_TARGET environment variable is not set."}

    #set up env for cross-compiling for PlayBook
    export PATH=$BBNDK_HOST/usr/bin:$PATH
    export CC="$BBNDK_HOST/usr/bin/qcc -V4.4.2,gcc_ntoarmv7le_cpp "
    export CFLAGS="-V4.4.2,gcc_ntoarmv7le_cpp -g "
    export CPP="$BBNDK_HOST/usr/bin/qcc -V4.4.2,gcc_ntoarmv7le_cpp -E"
    export LD="$BBNDK_HOST/usr/bin/ntoarmv7-ld "
    export RANLIB="$BBNDK_HOST/usr/bin/ntoarmv7-ranlib "

    ###########################################################################
    # Build SpiderMonkey 1.8.0                                                #   
    ###########################################################################
    pushd $BUILD_ROOT/../js/src

    export JS_INSTALL_DIR=$BUILD_ROOT
    local JS_TARGET=arm-unknown-nto-qnx6.5.0eabi
    export SPIDERMONKEY_TARGET_OS=QNX
    export LDFLAGS="-L$BBNDK_TARGET/armle-v7/usr/lib -L$BBNDK_TARGET/armle-v7/lib"
    export CPPFLAGS="-D__QNXNTO__ -I$BBNDK_TARGET/usr/local/include"

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
