#!/bin/bash

pushd `dirname $0` > /dev/null
SCRIPTPATH=`pwd -P`
popd > /dev/null
BEDPOSTDIR=$SCRIPTPATH/bedpost
BEDPOSTOUTDIR=$BEDPOSTDIR.bedpostX
rm -rf $BEDPOSTOUTDIR


time bedpostx_gpu $BEDPOSTDIR