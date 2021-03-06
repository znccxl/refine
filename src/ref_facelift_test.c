
/* Copyright 2014 United States Government as represented by the
 * Administrator of the National Aeronautics and Space
 * Administration. No copyright is claimed in the United States under
 * Title 17, U.S. Code.  All Other Rights Reserved.
 *
 * The refine platform is licensed under the Apache License, Version
 * 2.0 (the "License"); you may not use this file except in compliance
 * with the License. You may obtain a copy of the License at
 * http://www.apache.org/licenses/LICENSE-2.0.
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or
 * implied. See the License for the specific language governing
 * permissions and limitations under the License.
 */

#include "ref_facelift.h"

#include <math.h>
#include <stdio.h>
#include <stdlib.h>

#include "ref_adj.h"
#include "ref_args.h"
#include "ref_cell.h"
#include "ref_dict.h"
#include "ref_egads.h"
#include "ref_export.h"
#include "ref_face.h"
#include "ref_gather.h"
#include "ref_grid.h"
#include "ref_import.h"
#include "ref_list.h"
#include "ref_metric.h"
#include "ref_migrate.h"
#include "ref_mpi.h"
#include "ref_node.h"
#include "ref_part.h"
#include "ref_sort.h"

int main(int argc, char *argv[]) {
  REF_MPI ref_mpi;
  REF_INT pos = REF_EMPTY;

  RSS(ref_mpi_start(argc, argv), "start");
  RSS(ref_mpi_create(&ref_mpi), "make mpi");

  RXS(ref_args_find(argc, argv, "--viz", &pos), REF_NOT_FOUND, "arg search");
  if (pos != REF_EMPTY) {
    REF_GRID ref_grid;
    REIS(4, argc, "required args: --viz grid.ext geom.egads");
    REIS(1, pos, "required args: --viz grid.ext geom.egads");
    printf("import grid %s\n", argv[2]);
    RSS(ref_import_by_extension(&ref_grid, ref_mpi, argv[2]), "argv import");
    ref_mpi_stopwatch_stop(ref_grid_mpi(ref_grid), "grid import");
    printf("load geom %s\n", argv[3]);
    RSS(ref_egads_load(ref_grid_geom(ref_grid), argv[3]), "ld egads");
    ref_mpi_stopwatch_stop(ref_grid_mpi(ref_grid), "geom load");
    printf("write tec %s\n", "ref_facelift_viz.tec");
    RSS(ref_facelift_attach(ref_grid), "attach");
    {
      REF_FACELIFT ref_facelift = ref_geom_facelift(ref_grid_geom(ref_grid));
      RSS(ref_facelift_tec(ref_facelift, "ref_facelift_viz.tec"),
          "facelift tec");
      RSS(ref_geom_tec(ref_grid, "ref_facelift_geom.tec"), "facelift tec");
      RSS(ref_export_tec_surf(ref_facelift_grid(ref_facelift),
                              "ref_facelift_surf.tec"),
          "facelift tec");
      RSS(ref_export_by_extension(ref_facelift_grid(ref_facelift),
                                  "ref_facelift_surrogate.meshb"),
          "facelift export");
    }
    RSS(ref_grid_free(ref_grid), "free");
    RSS(ref_mpi_free(ref_mpi), "free");
    RSS(ref_mpi_stop(), "stop");
    return 0;
  }

  RXS(ref_args_find(argc, argv, "--metric", &pos), REF_NOT_FOUND, "arg search");
  if (pos != REF_EMPTY) {
    REF_GRID ref_grid;
    REF_DBL complexity;
    REIS(5, argc, "required args: --metric grid.ext geom.egads complexity");
    REIS(1, pos, "required args: --metric grid.ext geom.egads complexity");
    printf("import grid %s\n", argv[2]);
    RSS(ref_import_by_extension(&ref_grid, ref_mpi, argv[2]), "argv import");
    ref_mpi_stopwatch_stop(ref_grid_mpi(ref_grid), "grid import");
    printf("load geom %s\n", argv[3]);
    RSS(ref_egads_load(ref_grid_geom(ref_grid), argv[3]), "ld egads");
    ref_mpi_stopwatch_stop(ref_grid_mpi(ref_grid), "geom load");
    complexity = atof(argv[4]);
    printf("complexity %f\n", complexity);
    RSS(ref_metric_interpolated_curvature(ref_grid), "interp curve");
    ref_mpi_stopwatch_stop(ref_mpi, "curvature metric");
    RSS(ref_metric_interpolated_curvature(ref_grid), "interp curve");
    RSS(ref_export_tec_metric_ellipse(ref_grid, "ref_facelift_curve"), "al");
    RSS(ref_facelift_multiscale(ref_grid, complexity), "facelift multiscale");
    RSS(ref_export_tec_metric_ellipse(ref_grid, "ref_facelift_multiscale"),
        "al");
    RSS(ref_grid_free(ref_grid), "free");
    RSS(ref_mpi_free(ref_mpi), "free");
    RSS(ref_mpi_stop(), "stop");
    return 0;
  }

  RXS(ref_args_find(argc, argv, "--import", &pos), REF_NOT_FOUND, "arg search");
  if (pos != REF_EMPTY) {
    REF_GRID ref_grid;
    REIS(5, argc, "required args: --import grid.ext geom.egads facelift.meshb");
    REIS(1, pos, "required args: --import grid.ext geom.egads facelift.meshb");
    printf("import grid %s\n", argv[2]);
    RSS(ref_import_by_extension(&ref_grid, ref_mpi, argv[2]), "argv import");
    ref_mpi_stopwatch_stop(ref_grid_mpi(ref_grid), "grid import");
    printf("load geom %s\n", argv[3]);
    RSS(ref_egads_load(ref_grid_geom(ref_grid), argv[3]), "ld egads");
    ref_mpi_stopwatch_stop(ref_grid_mpi(ref_grid), "geom load");
    printf("import facelift %s\n", argv[4]);
    RSS(ref_facelift_import(ref_grid, argv[4]), "attach");
    ref_mpi_stopwatch_stop(ref_grid_mpi(ref_grid), "facelift load");
    {
      REF_FACELIFT ref_facelift = ref_geom_facelift(ref_grid_geom(ref_grid));
      RSS(ref_facelift_tec(ref_facelift, "ref_facelift_import_viz.tec"),
          "facelift tec");
      RSS(ref_geom_tec(ref_grid, "ref_facelift_import_geom.tec"),
          "facelift tec");
      RSS(ref_export_tec_surf(ref_facelift_grid(ref_facelift),
                              "ref_facelift_import_surf.tec"),
          "facelift tec");
    }
    RSS(ref_grid_free(ref_grid), "free");
    RSS(ref_mpi_free(ref_mpi), "free");
    RSS(ref_mpi_stop(), "stop");
    return 0;
  }

  {
    REF_FACELIFT ref_facelift;
    REF_GRID freeable_ref_grid;
    RSS(ref_grid_create(&freeable_ref_grid, ref_mpi), "create");
    RSS(ref_facelift_create(&ref_facelift, freeable_ref_grid), "create");
    RSS(ref_facelift_free(ref_facelift), "free");
  }

  RSS(ref_mpi_free(ref_mpi), "mpi free");
  RSS(ref_mpi_stop(), "stop");

  return 0;
}
