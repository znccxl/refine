#!/usr/bin/env bash

set -x

./bootstrap

module_path="/u/shared/fun3d/fun3d_users/modules"
zoltan_path="${module_path}/Zoltan/3.82-mpt-2.19-intel_2018.3.222"
parmetis_path="${module_path}/ParMETIS/4.0.3-mpt-2.19-intel_2018.3.222"
gcc_parmetis_path="${module_path}/ParMETIS/4.0.3-mpt-2.17r14-gcc_6.2.0"
egads_path="${module_path}/ESP/119-beta.2020.09.29.1106/EngSketchPad"
occ_path="${module_path}/ESP/119-beta.2020.09.29.1106/OpenCASCADE-7.3.1"
meshlink_path="/u/mpark/local/pkgs/MeshLink"

mpi_path="/opt/hpe/hpc/mpt/mpt-2.19"

gcc_flags="-g -O2 -pedantic-errors -Wall -Wextra -Werror -Wunused -Wuninitialized"
icc_flags="-g -O2 -traceback -Wall -w3 -wd1418,2259,2547,981,11074,11076,1572,49,1419 -ftrapuv"

mkdir -p egads
( cd egads && \
    ../configure \
    --prefix=`pwd` \
    --with-MeshLink=${meshlink_path} \
    --with-EGADS=${egads_path} \
    --with-OpenCASCADE=${occ_path} \
    --with-mpi=${mpi_path} \
    --with-parmetis=${parmetis_path} \
    --with-zoltan=${zoltan_path} \
    CC=icc \
    CFLAGS="${icc_flags}" \
    ) \
    || exit
