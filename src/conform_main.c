
/* Michael A. Park
 * Computational Modeling & Simulation Branch
 * NASA Langley Research Center
 * Phone:(757)864-6604
 * Email:m.a.park@larc.nasa.gov
 */

/* $Id$ */

#include <stdlib.h>
#include <stdio.h>
#include <string.h>
#include <math.h>
#include <values.h>
#include "grid.h"
#include "gridmetric.h"
#include "gridswap.h"
#include "gridinsert.h"
#include "gridcad.h"
#include "gridshape.h"
#include "gridmove.h"
#include "gridmpi.h"
#include "gridfiller.h"
#include "gridedger.h"
#include "gridfacer.h"
#include "gridmove.h"
#include "layer.h"

void bl_metric_flat(Grid *grid, double h0) {
  int node;
  double xyz[3];
  double dx[3] = {1.0,0.0,0.0};
  double dy[3] = {0.0,1.0,0.0};
  double dz[3] = {0.0,0.0,1.0};
  double hx,hy,hz;
  double y0;
  for(node=0;node<gridMaxNode(grid);node++){
    if (grid==gridNodeXYZ(grid,node,xyz)) {
      hx=0.1; hy=0.1; hz=0.1;
      //      y0 = 0.5-ABS(0.5*(xyz[0]-0.5)*(xyz[2]-0.5));
      y0 = 0.5;
      hy = ABS(xyz[1]-y0)/0.5;
      hy = MIN(1.0,hy);
      hy = 0.1*((1.0-h0)*hy+h0);

      hx=0.5; hy=0.5; hz=0.5;

      gridSetMapWithSpacingVectors(grid,node,
				   dx,dy,dz,hx,hy,hz);
    }
  }   
}

void bl_metric_sphere(Grid *grid, double h0) {
  int node;
  double xyz[3];
  double x,y,z;
  double x0=-0.5;
  double y0=-0.5;
  double z0=-0.5;
  double dx[3] = {1.0,0.0,0.0};
  double dy[3] = {0.0,1.0,0.0};
  double dz[3] = {0.0,0.0,1.0};
  double hx,hy,hz;
  double h1 = 0.1;
  double r0 = sqrt(3.0);
  double r, rp;
  for(node=0;node<gridMaxNode(grid);node++){
    if (grid==gridNodeXYZ(grid,node,xyz)) {
      x = xyz[0] - x0;
      y = xyz[1] - y0;
      z = xyz[2] - z0;
      r  = sqrt(x*x+y*y+z*z);
      dx[0] = x/r;
      dx[1] = y/r;
      dx[2] = z/r;
      rp = sqrt(x*x+y*y);
      dy[0] = -y/rp;
      dy[1] = x/rp;
      dy[2] = 0;
      gridCrossProduct(dx,dy,dz);
      gridVectorNormalize(dz);
      hx=0.1; hy=0.1; hz=0.1;
      r = ABS(r - r0)/0.5;
      r = MIN(1.0,r);
      hx = 0.1*((1.0-h0)*r+h0);
      gridSetMapWithSpacingVectors(grid,node,
				   dx,dy,dz,hx,hy,hz);
    }
  }   
}

void bl_metric(Grid *grid, double h0) {
  bl_metric_flat(grid, h0);
  if (FALSE) {
    int node;
    double xyz[3], map[6];
    for(node=0;node<gridMaxNode(grid);node++){
      if (grid==gridNodeXYZ(grid,node,xyz)) {
	gridMap( grid, node, map );
	printf(" %10.5f %10.5f %10.5f %10.5f %10.5f %10.5f\n",
	       map[0], map[1], map[2], map[3], map[4], map[5]);
      }
    }
  }
}

#define PRINT_STATUS {double l0,l1;gridEdgeRatioRange(grid,&l0,&l1);printf("Len %12.5e %12.5e AR %8.6f MR %8.6f Vol %10.6e\n", l0,l1, gridMinThawedAR(grid),gridMinThawedFaceMR(grid), gridMinVolume(grid)); fflush(stdout);}

#define DUMP_TEC if (tecplotOutput) { \
 iview++;printf("Frame %d\n",iview);\
 gridWriteTecplotSurfaceGeom(grid,NULL); \
  {int cell, nodes[4]; \
    for (cell=0;cell<gridMaxCell(grid);cell++) \
      if (grid==gridCell(grid, cell, nodes)) { \
        if ( -0.5 > gridAR(grid,nodes) ) \
          gridWriteTecplotCellGeom(grid,nodes,NULL,NULL); \
   }}; }

#define STATUS { \
  PRINT_STATUS; \
}

Grid *gridHistogram( Grid *grid, char *filename ) 
{
  int nodes[4];
  int cell;
  double cost;

  FILE *file;

  if (NULL == filename) {
    file = fopen( "histogram.m", "w" );
  }else{
    file = fopen( filename, "w" );
  }

  fprintf( file, "cost = [\n" );
  for ( cell = 0 ; cell < gridMaxCell(grid) ; cell++ ) {
    if ( grid == gridCell( grid, cell, nodes ) ) {
      cost = gridAR(grid, nodes);
      fprintf( file, "%e\n", cost );
    }
  }
  fprintf( file, "];\n" );

  fclose(file);

  return grid;
}

void relax_grid(Grid *grid)
{
  int node;
  if (TRUE) {
    STATUS;
    printf("adapt\n");
    gridAdapt2( grid );
    STATUS;
  }
  if (TRUE) {
    STATUS;
    printf("swap\n");
    gridSwap(grid,1.0);
    STATUS;
  }
  if (TRUE) {
    STATUS;
    printf("smooth\n");
    for (node=0;node<gridMaxNode(grid);node++) {
      if ( gridValidNode(grid,node) && !gridNodeFrozen( grid, node ) ) {
	if ( gridGeometryNode( grid, node ) ) continue;
	if ( gridGeometryEdge( grid, node ) ) {
	  //gridLineSearchT(grid, node, gridMinSurfaceSmoothCost(grid) );
	  continue;
	}
	if ( gridGeometryBetweenFace( grid, node ) ) continue;
	if ( gridGeometryFace( grid, node ) ) {
	  gridSmoothNodeARFace(grid, node);
	  continue;
	}
	gridSmartLaplacian(grid, node );
	gridSmoothNode(grid,node, FALSE);
      }
    }
    STATUS;
  }
}


#ifdef PROE_MAIN
int GridEx_Main( int argc, char *argv[] )
#else
int main( int argc, char *argv[] )
#endif
{
  Grid *grid;
  char modeler[256];
  char project[256];
  char ref_input[256];
  char ref_output[256];
  double h0 = 1.0;
  GridBool tecplotOutput = TRUE;

  int i;
  int iview=0;

  sprintf( modeler,    "Unknown" );
  sprintf( project,    "" );
  sprintf( ref_input,  "" );
  sprintf( ref_output, "" );

  i = 1;
  while( i < argc ) {
    if( strcmp(argv[i],"-p") == 0 ) {
      i++; sprintf( project, "%s", argv[i] );
      printf("-p argument %d: %s\n",i, project);
    } else if( strcmp(argv[i],"-r") == 0 ) {
      i++; sprintf( ref_input, "%s", argv[i] );
      printf("-r argument %d: %s\n",i, ref_input);
    } else if( strcmp(argv[i],"-o") == 0 ) {
      i++; sprintf( ref_output, "%s", argv[i] );
      printf("-o argument %d: %s\n",i, ref_output);
    } else if( strcmp(argv[i],"-s") == 0 ) {
      i++; h0 = atof(argv[i]);
      printf("-s argument %d: %f\n",i, h0);
    } else if( strcmp(argv[i],"-h") == 0 ) {
      printf("Usage: flag value pairs:\n");
      printf(" -p input project name\n");
      printf(" -r input ref name\n");
      printf(" -o output ref name\n");
      printf(" -s bl height\n");
      return(0);
    } else {
      fprintf(stderr,"Argument \"%s %s\" Ignored\n",argv[i],argv[i+1]);
      i++;
    }
    i++;
  }
  
  if(strcmp(project,"")==0) sprintf( project, "box1" );
  if(strcmp(ref_output,"")==0) sprintf( ref_output, "box_out" );

  if(!(strcmp(ref_input,"")==0)) {
    printf("running ref %s\n",ref_input);
    grid = gridImportRef( ref_input );
    if(strcmp(project,"")==0){
      printf("no geom specified.\n");
      printf("Done.\n");  
      return 0;
    }
    printf("loading geometry %s\n",project);
    gridGeomStartOnly( grid, project );
  }else{
    if(!(strcmp(project,"")==0)) {
      printf("running project %s\n",project);
      grid = gridLoadPart( modeler, project, 50000 );
    }
  }

  printf("restart grid size: %d nodes %d faces %d cells.\n",
	 gridNNode(grid),gridNFace(grid),gridNCell(grid));

  if (!gridRightHandedBoundary(grid)) {
    printf("ERROR: loaded part does not have right handed boundaries\n");
    return 1;
  }

  gridSetCostFunction(grid, gridCOST_FCN_CONFORMITY );
  gridSetCostConstraint(grid, gridCOST_CNST_VOLUME );
  gridSetMinInsertCost( grid, 1.0e-16 );
  gridSetMinSurfaceSmoothCost( grid, 1.0e-16 );

  h0 = 1.0;
  bl_metric(grid,h0);
  //gridCacheCurrentGridAndMap(grid);
  STATUS;

  gridHistogram(grid,"hist0.m");

  for(i=0;i<5;i++) {
    relax_grid(grid);
    STATUS;
    DUMP_TEC;
  }

  gridHistogram(grid,"hist1.m");

  gridExportFAST( grid, "grid_h1000.fgrid" );

  if (!gridRightHandedBoundary(grid)) 
    printf("ERROR: modifed grid does not have right handed boundaries\n");
  
  printf("writing output ref %s\n",ref_output);
  gridExportRef( grid, ref_output );

  printf("Done.\n");
  
  return 0;
}

