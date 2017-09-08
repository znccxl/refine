#include <stdlib.h>
#include <stdio.h>
#include <string.h>
#include <math.h>

#include "ref_grid.h"
#include "ref_cell.h"
#include "ref_edge.h"
#include "ref_node.h"
#include "ref_geom.h"
#include "ref_list.h"
#include "ref_adj.h"
#include "ref_sort.h"
#include "ref_dict.h"
#include "ref_matrix.h"
#include "ref_math.h"

#include "ref_split.h"

#include "ref_mpi.h"

#include "ref_smooth.h"
#include  "ref_twod.h"
#include "ref_collapse.h"
#include "ref_adapt.h"

#include "ref_fixture.h"
#include "ref_export.h"

#include "ref_metric.h"

#include "ref_gather.h"

int main( void )
{

  { /* collapse tet into triangle, keep renumbered edge */
    REF_GRID ref_grid;
    REF_INT node0, node1;

    RSS(ref_fixture_tet_grid(&ref_grid),"set up");
    node0 = 0; node1 = 3;

    RSS(ref_collapse_edge(ref_grid,node0,node1),"collapse");

    REIS(0, ref_cell_n(ref_grid_tet(ref_grid)),"tet");
    REIS(1, ref_cell_n(ref_grid_tri(ref_grid)),"tri");
    REIS(1, ref_cell_n(ref_grid_edg(ref_grid)),"edg");

    RSS( ref_grid_free( ref_grid ), "free grid");
  }

  { /* collapse tet into nothing, keep edge */
    REF_GRID ref_grid;
    REF_INT node0, node1;
    REF_INT nodes[REF_CELL_MAX_SIZE_PER];

    RSS(ref_fixture_tet_grid(&ref_grid),"set up");
    node0 = 0; node1 = 1;

    RSS(ref_collapse_edge(ref_grid,node0,node1),"collapse");

    REIS(0, ref_cell_n(ref_grid_tet(ref_grid)),"tet");
    REIS(0, ref_cell_n(ref_grid_tri(ref_grid)),"tri");
    REIS(1, ref_cell_n(ref_grid_edg(ref_grid)),"edg");

    RSS( ref_cell_nodes(ref_grid_edg(ref_grid),0,nodes),"nodes");
    REIS( 0, nodes[0], "1" );
    REIS( 2, nodes[1], "2" );

    RSS( ref_grid_free( ref_grid ), "free grid");
  }

  { /* collapse tet into nothing, no more edge */
    REF_GRID ref_grid;
    REF_INT node0, node1;

    RSS(ref_fixture_tet_grid(&ref_grid),"set up");
    node0 = 1; node1 = 2;

    RSS(ref_collapse_edge(ref_grid,node0,node1),"collapse");

    REIS(0, ref_cell_n(ref_grid_tet(ref_grid)),"tet");
    REIS(0, ref_cell_n(ref_grid_tri(ref_grid)),"tri");
    REIS(0, ref_cell_n(ref_grid_edg(ref_grid)),"edg");

    RSS( ref_grid_free( ref_grid ), "free grid");
  }

  { /* collapse removes node */
    REF_GRID ref_grid;
    REF_INT node0, node1;

    RSS(ref_fixture_tet_grid(&ref_grid),"set up");
    node0 = 0; node1 = 3;

    RSS(ref_collapse_edge(ref_grid,node0,node1),"collapse");

    REIS(3, ref_node_n(ref_grid_node(ref_grid)),"n");
    REIS( REF_FALSE, ref_node_valid(ref_grid_node(ref_grid),3),"val");

    RSS( ref_grid_free( ref_grid ), "free grid");
  }

  { /* collapse tet, renumber triangle, renumber edge */
    REF_GRID ref_grid;
    REF_INT node0, node1;
    REF_INT nodes[REF_CELL_MAX_SIZE_PER];

    RSS(ref_fixture_tet_grid(&ref_grid),"set up");
    node0 = 3; node1 = 1;

    RSS(ref_collapse_edge(ref_grid,node0,node1),"collapse");

    REIS(0, ref_cell_n(ref_grid_tet(ref_grid)),"tet");
    REIS(1, ref_cell_n(ref_grid_tri(ref_grid)),"tri");
    REIS(1, ref_cell_n(ref_grid_edg(ref_grid)),"edg");

    RSS( ref_cell_nodes(ref_grid_tri(ref_grid),0,nodes),"nodes");
    REIS( 0, nodes[0], "0" );
    REIS( 3, nodes[1], "1" );
    REIS( 2, nodes[2], "2" );

    RSS( ref_cell_nodes(ref_grid_edg(ref_grid),0,nodes),"nodes");
    REIS( 3, nodes[0], "1" );
    REIS( 2, nodes[1], "2" );

    RSS( ref_grid_free( ref_grid ), "free grid");
  }

  { /* geometry: collapse of volume node? */
    REF_GRID ref_grid;
    REF_INT node0, node1;
    REF_BOOL allowed;

    RSS(ref_fixture_tet_grid(&ref_grid),"set up");
    RSS(ref_cell_remove(ref_grid_tri(ref_grid),0),"remove tri" );

    node0 = 0; node1 = 1;
    RSS(ref_collapse_edge_geometry(ref_grid,node0,node1,&allowed),"col geom");

    REIS(REF_TRUE,allowed,"interior edge allowed?");

    RSS( ref_grid_free( ref_grid ), "free grid");
  }

  { /* geometry: collapse allowed on face? */
    REF_GRID ref_grid;
    REF_INT node0, node1;
    REF_INT nodes[4];
    REF_INT tri1, tri2;
    REF_BOOL allowed;

    RSS(ref_fixture_tet_grid(&ref_grid),"set up");
    /*
    2---4
    |\ 1|\
    |0\ | \
    |  \|2 \
    0---1---5
    */
    nodes[0] = 1; nodes[1] = 4, nodes[2] = 2; nodes[3] = 10;
    RSS(ref_cell_add(ref_grid_tri(ref_grid),nodes,&tri1),"add tri");
    nodes[0] = 1; nodes[1] = 5, nodes[2] = 4; nodes[3] = 10;
    RSS(ref_cell_add(ref_grid_tri(ref_grid),nodes,&tri2),"add tri");

    node0 = 0; node1 = 3;
    RSS(ref_collapse_edge_geometry(ref_grid,node0,node1,&allowed),"col geom");
    REIS(REF_TRUE,allowed,"interior node to face?");

    node0 = 0; node1 = 1;
    RSS(ref_collapse_edge_geometry(ref_grid,node0,node1,&allowed),"col geom");
    REIS(REF_TRUE,allowed,"parallel and interior to face?");

    ref_cell_c2n(ref_grid_tri(ref_grid),3,tri2) = 20;

    node0 = 4; node1 = 1;
    RSS(ref_collapse_edge_geometry(ref_grid,node0,node1,&allowed),"col geom");
    REIS(REF_TRUE,allowed,"parallel along geom edge?");

    RSS( ref_grid_free( ref_grid ), "free grid");
  }

  { /* same normal after collapse? */
    REF_GRID ref_grid;
    REF_INT node;
    REF_INT node0, node1;
    REF_INT nodes[4];
    REF_INT tri1, tri2;
    REF_BOOL allowed;

    RSS(ref_fixture_tet_grid(&ref_grid),"set up");
    /*
    2---4      y
    |\ 1|\
    |0\ | \    ^
    |  \|2 \   |
    0---1---5  +-> x
    */

    RSS(ref_node_add(ref_grid_node(ref_grid),4,&node),"add node");
    ref_node_xyz(ref_grid_node(ref_grid),0,node) = 1.0;
    ref_node_xyz(ref_grid_node(ref_grid),1,node) = 1.0;
    ref_node_xyz(ref_grid_node(ref_grid),2,node) = 0.0;

    RSS(ref_node_add(ref_grid_node(ref_grid),5,&node),"add node");
    ref_node_xyz(ref_grid_node(ref_grid),0,node) = 2.0;
    ref_node_xyz(ref_grid_node(ref_grid),1,node) = 0.0;
    ref_node_xyz(ref_grid_node(ref_grid),2,node) = 0.0;

    nodes[0] = 1; nodes[1] = 4, nodes[2] = 2; nodes[3] = 10;
    RSS(ref_cell_add(ref_grid_tri(ref_grid),nodes,&tri1),"add tri");
    nodes[0] = 1; nodes[1] = 5, nodes[2] = 4; nodes[3] = 10;
    RSS(ref_cell_add(ref_grid_tri(ref_grid),nodes,&tri2),"add tri");

    node0 = 2; node1 = 1;
    RSS(ref_collapse_edge_same_normal(ref_grid,node0,node1,&allowed),"norm");
    REIS(REF_TRUE,allowed,"normal will be the same");

    ref_node_xyz(ref_grid_node(ref_grid),2,node) = 0.5;

    RSS(ref_collapse_edge_same_normal(ref_grid,node0,node1,&allowed),"norm");
    REIS(REF_FALSE,allowed,"normal would change");

    ref_node_xyz(ref_grid_node(ref_grid),0,node) = 2.0;
    ref_node_xyz(ref_grid_node(ref_grid),1,node) = -1.0;
    ref_node_xyz(ref_grid_node(ref_grid),2,node) = 0.0;

    node0 = 2; node1 = 4;
    RSS(ref_collapse_edge_same_normal(ref_grid,node0,node1,&allowed),"norm");
    REIS(REF_FALSE,allowed,"tri will have zero area");


    RSS( ref_grid_free( ref_grid ), "free grid");
  }

  { /* mixed: collapse tet allowed? */
    REF_GRID ref_grid;
    REF_INT node0, node1;
    REF_BOOL allowed;

    RSS(ref_fixture_tet_grid(&ref_grid),"set up");

    node0 = 0; node1 = 1;
    RSS(ref_collapse_edge_mixed(ref_grid,node0,node1,&allowed),"col mixed");

    REIS(REF_TRUE,allowed,"pure tet allowed?");

    RSS( ref_grid_free( ref_grid ), "free grid");
  }
  { /* mixed: collapse of/near mixed allowed? */
    REF_GRID ref_grid;
    REF_INT node0, node1;
    REF_BOOL allowed;

    RSS(ref_fixture_pri_tet_cap_grid(&ref_grid),"set up");

    node0 = 5; node1 = 6;
    RSS(ref_collapse_edge_mixed(ref_grid,node0,node1,&allowed),"col mixed");
    REIS(REF_TRUE,allowed,"tet near mixed allowed?");

    node0 = 6; node1 = 5;
    RSS(ref_collapse_edge_mixed(ref_grid,node0,node1,&allowed),"col mixed");
    REIS(REF_FALSE,allowed,"tet changing mixed allowed?");

    node0 = 3; node1 = 4;
    RSS(ref_collapse_edge_mixed(ref_grid,node0,node1,&allowed),"col mixed");
    REIS(REF_FALSE,allowed,"mixed collapse allowed?");

    RSS( ref_grid_free( ref_grid ), "free grid");
  }

  { /* local: collapse allowed? */
    REF_GRID ref_grid;
    REF_INT node0, node1;
    REF_BOOL allowed;

    RSS(ref_fixture_tet_grid(&ref_grid),"set up");

    node0 = 0; node1 = 1;
    RSS(ref_collapse_edge_local_tets(ref_grid,node0,node1,&allowed),"col loc");
    REIS(REF_TRUE,allowed,"local collapse allowed?");

    ref_node_part(ref_grid_node(ref_grid),2) =
      ref_node_part(ref_grid_node(ref_grid),2) + 1;

    node0 = 0; node1 = 1;
    RSS(ref_collapse_edge_local_tets(ref_grid,node0,node1,&allowed),"col loc");
    REIS(REF_FALSE,allowed,"ghost collapse allowed?");

    RSS( ref_grid_free( ref_grid ), "free grid");
  }

  { /* no collapse, close enough */
    REF_GRID ref_grid;

    RSS(ref_fixture_tet_grid(&ref_grid),"set up");
    RSS( ref_metric_unit_node( ref_grid_node(ref_grid)), "id metric" );

    RSS(ref_collapse_pass(ref_grid),"pass");

    REIS( 4, ref_node_n(ref_grid_node(ref_grid)), "nodes");
    REIS( 1, ref_cell_n(ref_grid_tet(ref_grid)), "tets");

    RSS( ref_grid_free( ref_grid ), "free grid");
  }

  { /* top big */
    REF_GRID ref_grid;

    RSS(ref_fixture_tet_grid(&ref_grid),"set up");
    RSS( ref_metric_unit_node( ref_grid_node(ref_grid)), "id metric" );

    ref_node_metric(ref_grid_node(ref_grid),5,3) = 1.0/( 10.0*10.0 );

    RSS(ref_collapse_pass(ref_grid),"pass");

    /* ref_export_by_extension(ref_grid,"ref_collapse_test.tec"); */

    REIS( 3, ref_node_n(ref_grid_node(ref_grid)), "nodes");
    REIS( 0, ref_cell_n(ref_grid_tet(ref_grid)), "tets");

    RSS( ref_grid_free( ref_grid ), "free grid");
  }

  { /* collapse prism, keep qua */
    REF_GRID ref_grid;
    REF_INT keep0, remove0;
    REF_INT keep1, remove1;

    RSS(ref_fixture_pri_grid(&ref_grid),"set up");
    keep0 = 1; remove0 = 2;
    keep1 = 4; remove1 = 5;

    RSS(ref_collapse_face(ref_grid,keep0,remove0,keep1,remove1),"split");

    REIS(0, ref_cell_n(ref_grid_pri(ref_grid)),"pri");
    REIS(0, ref_cell_n(ref_grid_tri(ref_grid)),"tri");
    REIS(1, ref_cell_n(ref_grid_qua(ref_grid)),"qua");

    RSS( ref_grid_free( ref_grid ), "free grid");
  }

  { /* collapse prism and qua */
    REF_GRID ref_grid;
    REF_INT keep0, remove0;
    REF_INT keep1, remove1;

    RSS(ref_fixture_pri_grid(&ref_grid),"set up");
    keep0 = 0; remove0 = 1;
    keep1 = 3; remove1 = 4;

    RSS(ref_collapse_face(ref_grid,keep0,remove0,keep1,remove1),"split");

    REIS(0, ref_cell_n(ref_grid_pri(ref_grid)),"pri");
    REIS(0, ref_cell_n(ref_grid_tri(ref_grid)),"tri");
    REIS(0, ref_cell_n(ref_grid_qua(ref_grid)),"qua");

    RSS( ref_grid_free( ref_grid ), "free grid");
  }

  { /* local prism: collapse allowed? */
    REF_GRID ref_grid;
    REF_INT node0, node1;
    REF_BOOL allowed;

    RSS(ref_fixture_pri_grid(&ref_grid),"set up");

    node0 = 0; node1 = 1;
    RSS(ref_collapse_face_local_pris(ref_grid,node0,node1,&allowed),"col loc");
    REIS(REF_TRUE,allowed,"local collapse allowed?");

    ref_node_part(ref_grid_node(ref_grid),3) =
      ref_node_part(ref_grid_node(ref_grid),3) + 1;

    node0 = 0; node1 = 1;
    RSS(ref_collapse_face_local_pris(ref_grid,node0,node1,&allowed),"col loc");
    REIS(REF_FALSE,allowed,"ghost collapse allowed?");

    RSS( ref_grid_free( ref_grid ), "free grid");
  }

  { /* geometry: collapse of interior face */
    REF_GRID ref_grid;
    REF_INT keep, remove;
    REF_BOOL allowed;

    RSS(ref_fixture_pri_grid(&ref_grid),"set up");
    RSS(ref_cell_remove(ref_grid_qua(ref_grid),0),"remove qua" );

    keep = 0; remove = 1;
    RSS(ref_collapse_face_geometry(ref_grid,keep,remove,&allowed),"col geom");

    REIS(REF_TRUE,allowed,"interior edge allowed?");

    RSS( ref_grid_free( ref_grid ), "free grid");
  }

  { /* face tangent: collapse allowed? */
    REF_GRID ref_grid;
    REF_INT node0, node1, keep, remove;
    REF_INT cell, nodes[REF_CELL_MAX_SIZE_PER];
    REF_BOOL allowed;

    RSS(ref_fixture_pri_grid(&ref_grid),"set up");
    RSS(ref_node_add(ref_grid_node(ref_grid),6,&node0),"add node");
    ref_node_xyz(ref_grid_node(ref_grid),0,node0) = 0.0;
    ref_node_xyz(ref_grid_node(ref_grid),1,node0) = 0.0;
    ref_node_xyz(ref_grid_node(ref_grid),2,node0) = 2.0;
    RSS(ref_node_add(ref_grid_node(ref_grid),7,&node1),"add node");
    ref_node_xyz(ref_grid_node(ref_grid),0,node1) = 0.0;
    ref_node_xyz(ref_grid_node(ref_grid),1,node1) = 1.0;
    ref_node_xyz(ref_grid_node(ref_grid),2,node1) = 2.0;

    nodes[0] = 6; nodes[1] = 7; nodes[2] = 4; nodes[3] = 1;  nodes[4] = 10;
    RSS(ref_cell_add(ref_grid_qua(ref_grid),nodes,&cell),"add qua");

    keep = node0; remove = 1;
    RSS(ref_collapse_face_same_tangent(ref_grid,keep,remove,&allowed),"same");
    REIS(REF_TRUE,allowed,"straight tangent collapse allowed?");

    ref_node_xyz(ref_grid_node(ref_grid),0,node0) = 0.5;
    ref_node_xyz(ref_grid_node(ref_grid),0,node1) = 0.5;

    keep = node0; remove = 0;
    RSS(ref_collapse_face_same_tangent(ref_grid,keep,remove,&allowed),"same");
    REIS(REF_FALSE,allowed,"curved boundary collapse allowed?");

    RSS( ref_grid_free( ref_grid ), "free grid");
  }

  { /* no collapse, close enough, twod */
    REF_GRID ref_grid;

    RSS(ref_fixture_pri_grid(&ref_grid),"set up");
    RSS( ref_metric_unit_node( ref_grid_node(ref_grid)), "id metric" );

    RSS(ref_collapse_twod_pass(ref_grid),"pass");

    REIS( 6, ref_node_n(ref_grid_node(ref_grid)), "nodes");
    REIS( 1, ref_cell_n(ref_grid_pri(ref_grid)), "tets");
    REIS( 2, ref_cell_n(ref_grid_tri(ref_grid)), "tets");

    RSS( ref_grid_free( ref_grid ), "free grid");
  }

  { /* top big, twod */
    REF_GRID ref_grid;

    RSS(ref_fixture_pri_grid(&ref_grid),"set up");
    RSS( ref_metric_unit_node( ref_grid_node(ref_grid)), "id metric" );

    ref_node_metric(ref_grid_node(ref_grid),5,1) = 1.0/( 10.0*10.0 );
    ref_node_metric(ref_grid_node(ref_grid),5,4) = 1.0/( 10.0*10.0 );

    RSS(ref_collapse_twod_pass(ref_grid),"pass");

    REIS( 4, ref_node_n(ref_grid_node(ref_grid)), "nodes");
    REIS( 0, ref_cell_n(ref_grid_tri(ref_grid)), "tri");
    REIS( 0, ref_cell_n(ref_grid_pri(ref_grid)), "pri");

    RSS( ref_grid_free( ref_grid ), "free grid");
  }

  return 0;
}
