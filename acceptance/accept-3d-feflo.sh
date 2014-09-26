#!/usr/bin/env bash

bin=${HOME}/refine/strict/two

${bin}/ref_acceptance 1 ref_adapt_test.b8.ugrid

function adapt_cycle {
    proj=$1

    cp ref_adapt_test.b8.ugrid ${proj}.b8.ugrid

    ${bin}/ref_translate ${proj}.b8.ugrid ${proj}.html
    ${bin}/ref_translate ${proj}.b8.ugrid ${proj}.tec

    ${bin}/ref_acceptance ${proj}.b8.ugrid ${proj}.metric 0.001

    ${bin}/ref_translate ${proj}.b8.ugrid ${proj}.meshb
    ~/refine/util/metric2sol.sh ${proj}.metric ${proj}.sol

    ~/inria-file-tools/mac_bin/feflo.a -in ${proj}.meshb -met ${proj}.sol -out ref_adapt_test.meshb

    ${bin}/ref_translate ref_adapt_test.meshb ref_adapt_test.b8.ugrid

}

adapt_cycle accept-3d-00
adapt_cycle accept-3d-01
adapt_cycle accept-3d-02
adapt_cycle accept-3d-03
adapt_cycle accept-3d-04
adapt_cycle accept-3d-05
adapt_cycle accept-3d-06

