#!/usr/bin/env bash

set -x # echo commands
set -e # exit on first error
set -u # Treat unset variables as error

if [ $# -gt 0 ] ; then
    src=$1/src
else
    src=${HOME}/refine/egads/src
fi

tecplot=-t
egads="-g square-circle.egads"

function adapt_cycle {
    inproj=$1
    outproj=$2
    sweeps=$3

    ${src}/ref adapt \
	  ${inproj}.meshb \
	  ${egads} \
          -x ${outproj}.meshb \
	  -s ${sweeps} \
	  ${tecplot} \
	   | tee ${outproj}.status
}

serveCSM -batch square-circle.csm
ref bootstrap square-circle.egads

adapt_cycle square-circle-vol cycle01 10
adapt_cycle cycle01 cycle02 10
adapt_cycle cycle02 cycle03 10
adapt_cycle cycle03 cycle04 10

cat cycle04.status
../../check.rb cycle04.status 0.30 2.5

