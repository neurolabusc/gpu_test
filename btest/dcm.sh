#!/bin/bash

for i in $*;
do
    params=" $params $i"
done
exe=dcm2niix
$exe -i y $params




