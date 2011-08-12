
#ifndef REF_CELL_H
#define REF_CELL_H

#include "ref_defs.h"

BEGIN_C_DECLORATION
typedef struct REF_CELL_STRUCT REF_CELL_STRUCT;
typedef REF_CELL_STRUCT * REF_CELL;
END_C_DECLORATION

BEGIN_C_DECLORATION

struct REF_CELL_STRUCT {
  REF_INT node_per, n, max;
  REF_INT blank;
  REF_INT *c2n;
};

REF_STATUS ref_cell_create( REF_INT node_per, REF_CELL *ref_cell );
REF_STATUS ref_cell_free( REF_CELL ref_cell );

REF_STATUS ref_cell_inspect( REF_CELL ref_cell );

#define ref_cell_n(ref_cell) ((ref_cell)->n)
#define ref_cell_max(ref_cell) ((ref_cell)->max)
#define ref_cell_node_per(ref_cell) ((ref_cell)->node_per)
#define ref_cell_blank(ref_cell) ((ref_cell)->blank)
#define ref_cell_c2n(ref_cell,node,cell) \
  ((ref_cell)->c2n[(node)+ref_cell_node_per(ref_cell)*(cell)])

REF_STATUS ref_cell_add( REF_CELL ref_cell, REF_INT *nodes, REF_INT *cell );
REF_STATUS ref_cell_nodes( REF_CELL ref_cell, REF_INT cell, REF_INT *nodes );

END_C_DECLORATION

#endif /* REF_CELL_H */
