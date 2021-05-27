#!/usr/bin/env bash
#
# This script configures eddy based on the current system (cuda found or not)
#
# Call with -f <FSLDIR path>, e.g. /usr/local/fsl (will use FSLDIR if given
# no arguments)
platform=`uname -s`
# Where is this script?
script_dir=$( cd $(dirname $0) ; pwd)
script_name=${0##*/}
# Set some defaults
OPTIND=1
fsl_dir=""
quiet=0
dryrun=0
dropprivileges=0
OLDIFS=$IFS
# Have we been called by sudo?
if [ ! -z "${SUDO_UID}" ]; then
    dropprivileges=1
fi

function syntax {
    echo "$script_name [-f <FSLDIR>] [-q] [-d]"
    echo "  -f <FSLDIR> Location of installed FSL, e.g. /usr/local/fsl"
    echo "                  if not provided looks for FSLDIR in environment"
    echo "  -q          Install quietly"
    echo "  -d          Dry run. Does not actually make symlinks"
}

while getopts "h?qdf:" opt; do
    case "${opt}" in
    h|\?)
        syntax
        exit 0
        ;;
    q)  quiet=1
        ;;
    f)  fsl_dir=${OPTARG}
        ;;
    d)  dryrun=1
        ;;
    esac
done

shift $((OPTIND-1))

[ "$1" = "--" ] && shift

if [ -z "${fsl_dir}" ]; then
    if [ -z "${FSLDIR}" ]; then
        echo "Error - FSLDIR not given as an argument and \$FSLDIR not set!" >&2
        exit 1
    else
        fsl_dir=${FSLDIR}
    fi
fi

if [ ! -e "${fsl_dir}/bin" ]; then
    echo "Error - ${fsl_dir}/bin does not exist!" >&2
    exit 1
fi

if [ ! -w "${fsl_dir}" ]; then
    echo "Error - cannot write to ${fsl_dir}!" >&2
    exit 1
fi

if [ ! -w "${fsl_dir}/bin" ]; then
    echo "Error - cannot write to ${fsl_dir}/bin!" >&2
    exit 1
fi

if [ ! -e "${fsl_dir}/etc/fslversion" ]; then
    echo "${fsl_dir} doesn't look like an FSL installation folder!" >&2
    exit 1
fi

function drop_sudo {
    if [ ${dropprivileges} -eq 1 ]; then
        sudo -u \#${SUDO_UID} "$@"
        if [ $? -eq 1 ]; then
            sudo -u \#${SUDO_UID} -g \#${SUDO_GID} "$@"
        fi
    else
        "$@"
    fi
}

#####################################
# Configure eddy
#####################################

# If Darwin (macOS) then no need to configure eddy_openmp or eddy_cuda
if [ "$platform" = "Darwin" ]; then
    exit 0
fi

# If Linux, run the following configuration steps:
# check if no eddy, but eddy_openmp exists, then link to eddy
if [ ! -f "${fsl_dir}/bin/eddy" ]; then
	if [ -f "${fsl_dir}/bin/eddy_openmp" ]; then
		if [[ dryrun -eq 0 ]]
        then
            ln -sf ${fsl_dir}/bin/eddy_openmp ${fsl_dir}/bin/eddy
        else
            echo "would do: ln -sf ${fsl_dir}/bin/eddy_openmp ${fsl_dir}/bin/eddy"
        fi
	fi
fi

# does eddy_cuda exist?
if [ -f "${fsl_dir}/bin/eddy_cuda" ]; then
    exit 0
else
	# list installed fsl eddy_cuda versions (puts versions into array)
	eddycudas=($(ls -d ${fsl_dir}/bin/eddy_cuda*))
    if [ -z "$eddycudas" ]
    then
        exit 0
    fi

	# List installed cuda versions in /opt/cuda* (put into array)
    ls -d /opt/cuda* > /dev/null 2>&1
    if [ $? -eq 0 ]
    then
        syscudas=($(ls -d /opt/cuda* | sort -V))
    else
        ls -d /usr/local/cuda* > /dev/null 2>&1
        if [ $? -eq 0 ]
        then
            syscudas=($(ls -d /usr/local/cuda* | sort -V))
        else
            exit 0
        fi
    fi
    if [ -z "$syscudas" ]
    then
        exit 0
    fi

	# loop through eddy_cuda versions found
	for eddycudaversionstring in "${eddycudas[@]}"
	do
		# parse full path string into parts separated by "/"
		IFS='/' read -r -a parts <<< "$eddycudaversionstring"
		# get the last part
        len=${#parts[@]}
        i=$((len-1))
		fslcudastring="${parts[$i]}"
        IFS=$OLDIFS
		# parse again to get version string
		IFS='eddy_cuda' read -a verstring <<< "$fslcudastring"
        len=${#verstring[@]}
        i=$((len-1))
		fslcudaver="${verstring[$i]}"
        IFS=$OLDIFS

		for syscudaversionstring in "${syscudas[@]}"
		do
			# parse full path string into parts separated by "/"
			IFS='/' read -a parts <<< "$syscudaversionstring"
			# get the last part
            len=${#parts[@]}
            i=$((len-1))
			syscudastring="${parts[$i]}"
            IFS=$OLDIFS
			# parse again to get version string
			IFS='-' read -a verstring <<< "$syscudastring"
            len=${#verstring[@]}
            i=$((len-1))
			syscudaver="${verstring[$i]}"
            IFS=$OLDIFS
			# if version strings are equal, we know that the user has version X available, so we can link to version X for eddy_cuda
			if [ "$fslcudaver" == "$syscudaver" ]; then
				if [[ dryrun -eq 0 ]]
          then
              ln -sf ${fsl_dir}/bin/eddy_cuda$fslcudaver ${fsl_dir}/bin/eddy_cuda
          else
              echo "would do: ln -sf ${fsl_dir}/bin/eddy_cuda$fslcudaver ${fsl_dir}/bin/eddy_cuda"
          fi
			fi
		done
	done
fi


