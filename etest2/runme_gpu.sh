#!/bin/bash
# Detect OS
if [[ "$(uname)" == "Darwin" ]]; then
    eddyExeName=eddy_metal
else
    eddyExeName=eddy_cuda
fi

pth=$(which "$eddyExeName")
if [ -z "$pth" ]; then
    echo "Required version not supported: unable to find '$eddyExeName'"
    exit 1
fi

time $eddyExeName --imain=merged.nii.gz --mask=brain_mask.nii.gz --acqp=acq_param.txt --index=index.txt --bvecs=merged.bvec --bvals=merged.bval --topup=topup_results --data_is_shelled --repol --out=./out/eddy
