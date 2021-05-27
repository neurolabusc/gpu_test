#!/bin/bash
fnm=/usr/local/cuda/version.txt
if [ ! -f $fnm ]; then
    echo "CUDA not installed: unable to find '$fnm'"
    exit 1
fi
value=`cat $fnm`
#value = "CUDA Version 10.1.243"
# echo "$value"
var2=${value##* }
#var2= "10.1.243" or "10.1"
dots="${var2//[^.]}"
dots=${#dots}
if [[ "$dots" -eq 2 ]]; then
 # "10.1.221" -> "10.1"
 var2=${var2%.*}
fi
#var2 = "10.1"
exe=eddy_cuda$var2
pth=$(which $exe)
if [ -z "$pth" ]; then
    echo "CUDA version not supported: unable to find '$exe'"
    exit 1
fi
# echo "Executing '$exe'"
# $exe "$@"
echo Run the following command: 
echo sudo ln -s $pth $(dirname $pth)/eddy_cuda

