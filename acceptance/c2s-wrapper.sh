#!/usr/bin/env bash

set -x # echo commands
set -e # exit on first error
set -u # Treat unset variables as error

build_directory_root=/hpnobackup1/fun3d/c2s-ci

build_machine=k4
ssh -o StrictHostKeyChecking=no fun3d@${build_machine} true

BUILD_TAG="${CI_JOB_NAME}-${CI_JOB_ID}"
set +u
if [[ -z "${CI_MERGE_REQUEST_SOURCE_BRANCH_NAME}" || -z "{CI_MERGE_REQUEST_TARGET_BRANCH_NAME}" ]]; then
    checkout_cmd="git checkout ${CI_COMMIT_SHA}"
else
    checkout_cmd="git checkout ${CI_MERGE_REQUEST_SOURCE_BRANCH_NAME} && git merge ${CI_MERGE_REQUEST_TARGET_BRANCH_NAME}"
fi
set -u

ssh -o LogLevel=error fun3d@${build_machine} <<EOF
whoami && \
uname -n && \
mkdir -p ${build_directory_root} && \
cd ${build_directory_root} && \
  mkdir -p ${BUILD_TAG} && \
  cd ${BUILD_TAG} && \
    pwd && \
    git clone ${CI_REPOSITORY_URL} && \
    git clone git@gitlab.larc.nasa.gov:cad-to-solution/acceptance.git && \
    cd refine && \
      pwd && \
      ${checkout_cmd} && \
      ./acceptance/c2s-qsub.sh
EOF

scp -o LogLevel=error fun3d@${build_machine}:${build_directory_root}/${BUILD_TAG}/log-\* .

trap "cat cleanup.log" EXIT
ssh -o LogLevel=error fun3d@${build_machine} > cleanup.log 2>&1 <<EOF
whoami && \
uname -n && \
cd ${build_directory_root}/${BUILD_TAG}/refine && \
 ./acceptance/remove_old_builds.sh \
  "${build_directory_root}"
EOF
trap - EXIT

