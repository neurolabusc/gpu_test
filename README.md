## About

Graphics cards (GPU) can dramatically accelerate some stages of brain imaging processing. In particular, the FSL tools Bedpostx, Eddy and Probtrackx are all commonly used for diffusion analyses and can be dramatically accelerations using an NVidia GPU that supports the CUDA language. While the performance benefits are huge, setting up these systems can be tricky. This repository contains minimal datasets and scripts for testing these tools. 

These sample datasets are only designed to validate the installation of these tools. They are not designed to showcase the performance benefits of GPU acceleration. Specifically, the datasets are designed to be small allowing for fast download and testing. Typical datasets are much larger and more computationally intensive. Several of these tests are probably constrained by memory speeds or the required CPU-based serial processing stages that precede and follow the parallel processing of the GPU.

## Scripts

* btest for [CUDA accelerated Bedpostx](https://users.fmrib.ox.ac.uk/~moisesf/Bedpostx_GPU/)
  * The script `runme_gpu.sh` will run `Bedpostx_GPU`.
  * If the script fails to run, make sure your version of Bedpostx_GPU matches your version of [CUDA](https://users.fmrib.ox.ac.uk/~moisesf/Bedpostx_GPU/Installation.html).

* etest for [CUDA accelerated Eddy](https://fsl.fmrib.ox.ac.uk/fsl/fslwiki/eddy/UsersGuide#The_eddy_executables)
  * Since there are different versions of Eddy for different generations of CUDA (e.g. `eddy_cuda9.1` only works with CUDA 9.1), the shell script assumes that the executable sym-link `eddy_cuda` exists. In theory, the FSL installer should create this for you, but this requires CUDA is setup prior to installing FSL. If this is not the case, this repository includes the installer script from FSL 6.0.4, which you can run `sudo ./configure_eddy.sh -f /usr/local/fsl`. In my experience, this can fail if you have multiple versions of CUDA installed. As an alternative, I include the script `configure_eddy_cr.sh` which you can run (e.g. `./configure_eddy.sh`) and it will suggest a command you can run to create the symbolic link (e.g. `sudo ln -s /usr/local/fsl/bin/eddy_cuda9.1 /usr/local/fsl/bin/eddy_cuda`.
  
 * ptest for [CUDA accelerated Probtrackx](https://users.fmrib.ox.ac.uk/~moisesf/Probtrackx_GPU/index.html)
  * The script `runme_gpu.sh` will run `Probtrackx_GPU`.
  * If the script fails to run, make sure your version of Probtrackx_GPU matches your version of [CUDA](https://users.fmrib.ox.ac.uk/~moisesf/Probtrackx_GPU/Installation.html).

## Lines

 * [nii_preprocess](https://github.com/neurolabusc/nii_preprocess) leverages these GPU tools for processing datasets.
