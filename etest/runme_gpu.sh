#!/bin/bash

eddyExeName=eddy_cuda
pth=$(which $eddyExeName)
if [ -z "$pth" ]; then
    echo "CUDA version not supported (try running `configure_eddy.sh`): unable to find '$eddyExeName'"
    exit 1
fi


dti=DTIap

if [ ! -e ${dti}.nii.gz ]; then
 echo "Error: Unable to find ${dti}.nii.gz"
 exit 1
fi

if ! hash $eddyExeName 2>/dev/null; then
 echo "Error: Unable to find $eddyExeName"
 exit 1
fi

dti_b=${dti}b #brain-extracted dti
dti_b0=${dti}b0
dti_u=${dti}u #undistorted dti
dti_bvec=${dti}.bvec
dti_bval=${dti}.bval

fslroi $dti $dti_b0 0 1
bet $dti_b0 $dti_b  -f 0.2 -R -n -m
dti_b=${dti}b_mask #masked brain-extracted dti
#create acq_param: dummies as we will not run TOPUP
dti_txt=${dti}_acq_param.txt
printf "0 1 0 0.03388\n0 -1 0 0.03388\n" > $dti_txt
#create index files: all = 1 as we will not run TOPUP
dti_txt2=${dti}_index.txt
nvol=$(fslnvols $dti)
indx=""
for ((i=1; i<=nvol; i+=1)); do indx="$indx 1"; done
echo $indx > $dti_txt2
echo $eddyExeName --imain=$dti --mask=$dti_b --acqp=$dti_txt --index=$dti_txt2 --bvecs=$dti_bvec --bvals=$dti_bval --repol --out=$dti_u
time $eddyExeName --imain=$dti --mask=$dti_b --acqp=$dti_txt --index=$dti_txt2 --bvecs=$dti_bvec --bvals=$dti_bval --repol --out=$dti_u
