#!/bin/bash

pushd `dirname $0` > /dev/null
SCRIPTPATH=`pwd -P`
popd > /dev/null
COMMANDNAME=$SCRIPTPATH/command.txt
LOGNAME=$SCRIPTPATH/logs
	
rm -f $COMMANDNAME
for i in {1..172}
do
   echo "probtrackx2 -x $SCRIPTPATH/masks/$i.nii.gz --dir=$SCRIPTPATH/probtrackx/$i --forcedir  -P 200 -s $SCRIPTPATH/bedpost.bedpostX/merged -m $SCRIPTPATH/bedpost.bedpostX/nodif_brain_mask --opd --pd -l -c 0.2 --distthresh=0" >> $COMMANDNAME
done

echo "fsl_sub running $COMMANDNAME with parallel processing disabled"
FSLPARALLEL=0; export FSLPARALLEL
time fsl_sub -l $LOGNAME -N probtrackx -T 1 -t $COMMANDNAME

echo "fsl_sub running $COMMANDNAME with x2 parallel processing enabled"
FSLPARALLEL=2
time fsl_sub -l $LOGNAME -N probtrackx -T 1 -t $COMMANDNAME

echo "fsl_sub running $COMMANDNAME with x4 parallel processing enabled"
FSLPARALLEL=4
time fsl_sub -l $LOGNAME -N probtrackx -T 1 -t $COMMANDNAME

echo "fsl_sub running $COMMANDNAME with x8 parallel processing enabled"
FSLPARALLEL=8
time fsl_sub -l $LOGNAME -N probtrackx -T 1 -t $COMMANDNAME

echo "fsl_sub running $COMMANDNAME with x12 parallel processing enabled"
FSLPARALLEL=12
time fsl_sub -l $LOGNAME -N probtrackx -T 1 -t $COMMANDNAME
