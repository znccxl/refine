#!/usr/bin/env bash

set -x # echo commands
set -e # exit on first error
set -u # Treat unset variables as error

set +x # echo commands
. /usr/local/pkgs/modules/init/bash
module use --append /ump/fldmd/home/wtjones1/Modules/modulefiles
module load OpenCASCADE/6.6.0
module load ESP/svn
module add gcc_4.9.1_64
module list
set -x # echo commands

module_path="/ump/fldmd/home/casb-shared/fun3d/fun3d_users/modules"
parmetis_path="${module_path}/ParMETIS/4.0.3-1.10.2_intel_2013-2013.4.183_64"
zoltan_path="${module_path}/Zoltan/3.82-1.10.2_intel_2013-2013.4.183_64"

egads_path=/ump/fldmd/home/wtjones1/local/pkgs-modules/ESP/svn

root_dir=$(dirname $PWD)
source_dir=${root_dir}/refine
build_dir=${root_dir}/_refine

cd ${source_dir}
LOG=${root_dir}/log.bootstrap
trap "cat $LOG" EXIT
./bootstrap > $LOG 2>&1
trap - EXIT

mkdir -p ${build_dir}
cd ${build_dir}
LOG=${root_dir}/log.configure
trap "cat $LOG" EXIT
${source_dir}/configure \
    --prefix=${build_dir} \
    --with-EGADS=${egads_path} \
    CFLAGS='-g -O2 -pedantic-errors -Wall -Wextra -Werror -Wunused -Wuninitialized' \
    FC=gfortran  > $LOG 2>&1
trap - EXIT

LOG=${root_dir}/log.make
trap "cat $LOG" EXIT
env TMPDIR=${PWD} make -j 8  > $LOG 2>&1
trap - EXIT

LOG=${root_dir}/log.make-check
trap "cat $LOG" EXIT
make check > $LOG 2>&1
trap - EXIT

LOG=${root_dir}/log.make-install
trap "cat $LOG" EXIT
make install > $LOG 2>&1
trap - EXIT




