#include <stdlib.h>
#include <stdio.h>
#include <string.h>

#include "ref_part.h"
#include "ref_mpi.h"
#include "ref_fixture.h"
#include "ref_export.h"

#include "ref_dict.h"
#include "ref_cell.h"
#include "ref_node.h"
#include "ref_list.h"
#include "ref_adj.h"
#include "ref_matrix.h"
#include "ref_geom.h"
#include  "ref_math.h"
#include "ref_import.h"
#include "ref_twod.h"


#include "ref_sort.h"
#include "ref_migrate.h"
#include "ref_edge.h"
#include "ref_gather.h"

int main( int argc, char *argv[] )
{

  RSS( ref_mpi_start( argc, argv ), "start" );

  if ( 1 < argc )
    { /* part */
      REF_GRID import_grid;
      char viz_file[256];

      ref_mpi_stopwatch_start();
      RSS(ref_part_b8_ugrid( &import_grid, argv[1] ), "import" );
      ref_mpi_stopwatch_stop("import");

      sprintf(viz_file, "ref_part_test_n%d_p%d.tec", ref_mpi_n, ref_mpi_id);
      RSS( ref_export_by_extension( import_grid, viz_file ), "export");
      ref_mpi_stopwatch_stop("export");

      RSS( ref_gather_tec_part( import_grid, "ref_part_test.tec" ), "part_viz");
      ref_mpi_stopwatch_stop("gather");

      RSS(ref_grid_free(import_grid),"free");

      RSS( ref_mpi_stop( ), "stop" );
      return 0;
    }

  { /* one even */
    REIS( 0, ref_part_first( 4, 4, 0 ), "first");
    REIS( 1, ref_part_first( 4, 4, 1 ), "first");
    REIS( 2, ref_part_first( 4, 4, 2 ), "first");
    REIS( 3, ref_part_first( 4, 4, 3 ), "first");
    REIS( 4, ref_part_first( 4, 4, 4 ), "first");
  }

  { /* one run out */
    REIS( 0, ref_part_first( 2, 4, 0 ), "first");
    REIS( 1, ref_part_first( 2, 4, 1 ), "first");
    REIS( 2, ref_part_first( 2, 4, 2 ), "first");
    REIS( 2, ref_part_first( 2, 4, 3 ), "first");
    REIS( 2, ref_part_first( 2, 4, 4 ), "first");
  }

  { /* two run out */
    REIS( 0, ref_part_first( 7, 4, 0 ), "first");
    REIS( 2, ref_part_first( 7, 4, 1 ), "first");
    REIS( 4, ref_part_first( 7, 4, 2 ), "first");
    REIS( 6, ref_part_first( 7, 4, 3 ), "first");
    REIS( 7, ref_part_first( 7, 4, 4 ), "first");
  }

  { /* two even */
    REIS( 0, ref_part_first( 4, 2, 0 ), "first");
    REIS( 2, ref_part_first( 4, 2, 1 ), "first");
    REIS( 4, ref_part_first( 4, 2, 2 ), "first");
  }

  { /* single */
    REIS( 0, ref_part_implicit( 4, 1, 0 ), "part");
    REIS( 0, ref_part_implicit( 4, 1, 1 ), "part");
    REIS( 0, ref_part_implicit( 4, 1, 2 ), "part");
    REIS( 0, ref_part_implicit( 4, 1, 3 ), "part");
  }

  { /* one even */
    REIS( 0, ref_part_implicit( 4, 4, 0 ), "part");
    REIS( 1, ref_part_implicit( 4, 4, 1 ), "part");
    REIS( 2, ref_part_implicit( 4, 4, 2 ), "part");
    REIS( 3, ref_part_implicit( 4, 4, 3 ), "part");
  }

  { /* one run out */
    REIS( 0, ref_part_implicit( 2, 4, 0 ), "part");
    REIS( 1, ref_part_implicit( 2, 4, 1 ), "part");
  }

  { /* two run out */
    REIS( 0, ref_part_implicit( 7, 4, 0 ), "part");
    REIS( 0, ref_part_implicit( 7, 4, 1 ), "part");
    REIS( 1, ref_part_implicit( 7, 4, 2 ), "part");
    REIS( 1, ref_part_implicit( 7, 4, 3 ), "part");
    REIS( 2, ref_part_implicit( 7, 4, 4 ), "part");
    REIS( 2, ref_part_implicit( 7, 4, 5 ), "part");
    REIS( 3, ref_part_implicit( 7, 4, 6 ), "part");
  }

  { /* two even */
    REIS( 0, ref_part_implicit( 4, 2, 0 ), "part");
    REIS( 0, ref_part_implicit( 4, 2, 1 ), "part");
    REIS( 1, ref_part_implicit( 4, 2, 2 ), "part");
    REIS( 1, ref_part_implicit( 4, 2, 3 ), "part");
  }

  { /* part b8.ugrid */
    REF_GRID export_grid, import_grid;
    char grid_file[] = "ref_part_test.b8.ugrid";
    
    RSS(ref_fixture_pri_stack_grid( &export_grid ), "set up tet" );
    if ( ref_mpi_master ) 
      {
	RSS(ref_export_b8_ugrid( export_grid, grid_file ), "export" );
      }
    RSS(ref_part_b8_ugrid( &import_grid, grid_file ), "import" );

    RSS(ref_grid_free(import_grid),"free");
    RSS(ref_grid_free(export_grid),"free");
    if ( ref_mpi_master ) REIS(0, remove( grid_file ), "test clean up");
  }

  { /* part meshb */
    REF_GRID export_grid, import_grid;
    char grid_file[] = "ref_part_test.meshb";
    
    if ( ref_mpi_master ) 
      {
	RSS(ref_fixture_tet_brick_grid( &export_grid ), "set up tet" );
	RSS(ref_export_meshb( export_grid, grid_file ), "export" );
	RSS(ref_grid_free(export_grid),"free");
      }

    RSS(ref_part_meshb( &import_grid, grid_file ), "import" );
    RSS( ref_gather_tec_part( import_grid, "ref_part_test.tec" ), "part_viz");

    RSS(ref_grid_free(import_grid),"free");
    if ( REF_FALSE && ref_mpi_master ) REIS(0, remove( grid_file ), "test clean up");
  }

  { /* metric */
    REF_GRID ref_grid;
    char metric_file[] = "ref_part_test.metric";
    
    RSS(ref_fixture_tet_grid( &ref_grid ), "set up tet" );

    if ( ref_mpi_master ) 
      {
	REF_INT node;
	FILE *file;
	file = fopen(metric_file,"w");
	RNS(file, "unable to open file" );

	for (node=0;node<4;node++)
	  fprintf(file, " %f %f %f %f %f %f\n",
		  1.0, 0.0, 0.0, 2.0, 0.0, 4.0 );
	
	fclose(file);
      }
	  
    RSS(ref_part_metric( ref_grid_node(ref_grid), metric_file ), "metric" );

    RSS(ref_grid_free(ref_grid),"free");

    if ( ref_mpi_master ) REIS(0, remove( metric_file ), "test clean up");
  }

  RSS( ref_mpi_stop( ), "stop" );

  return 0;
}
