
#include "ruby.h"
#include "queue.h"

#define GET_QUEUE_FROM_SELF Queue *queue; Data_Get_Struct( self, Queue, queue );

static void queue_free( void *queue )
{
  queueFree( queue );
}

VALUE queue_new( VALUE class )
{
  Queue *queue;
  VALUE obj;
  queue = queueCreate(  );
  obj = Data_Wrap_Struct( class, 0, queue_free, queue );
  return obj;
}

VALUE queue_reset(VALUE self )
{
  GET_QUEUE_FROM_SELF;
  return (queue==queueReset(queue)?self:Qnil);
}

VALUE queue_transactions( VALUE self )
{
  GET_QUEUE_FROM_SELF;
  return INT2NUM(queueTransactions(queue));
}

VALUE queue_newTransaction( VALUE self )
{
  GET_QUEUE_FROM_SELF;
  return (queue==queueNewTransaction(queue)?self:Qnil);
}

/* ****************************** cells ****************************** */

VALUE queue_removeCell( VALUE self, VALUE rb_nodes )
{
  int i, nodes[4];
  GET_QUEUE_FROM_SELF;
  for (i=0;i<4;i++) nodes[i]=NUM2INT(rb_ary_entry(rb_nodes,i));
  return (queue==queueRemoveCell(queue,nodes)?self:Qnil);
}

VALUE queue_removedCells( VALUE self, VALUE transaction )
{
  GET_QUEUE_FROM_SELF;
  return INT2NUM(queueRemovedCells(queue,NUM2INT(transaction)));
}

VALUE queue_removedCellNodes( VALUE self, VALUE index )
{
  int i, nodes[4];
  VALUE rb_nodes;
  GET_QUEUE_FROM_SELF;
  if (queue != queueRemovedCellNodes(queue,NUM2INT(index),nodes)) return Qnil;
  rb_nodes = rb_ary_new2(4);
  for (i=0;i<4;i++) rb_ary_store(rb_nodes,i,INT2NUM(nodes[i]));
  return rb_nodes;
}

VALUE queue_addCell( VALUE self, VALUE rb_nodes, VALUE rb_xyzs )
{
  int i, nodes[5];
  double xyzs[12];
  GET_QUEUE_FROM_SELF;
  for (i=0;i< 5;i++) nodes[i]=NUM2INT(rb_ary_entry(rb_nodes,i));
  for (i=0;i<12;i++) xyzs[i] =NUM2DBL(rb_ary_entry(rb_xyzs,i));
  return (queue==queueAddCell(queue,nodes,xyzs)?self:Qnil);
}

VALUE queue_addedCells( VALUE self, VALUE transaction )
{
  GET_QUEUE_FROM_SELF;
  return INT2NUM(queueAddedCells(queue,NUM2INT(transaction)));
}

VALUE queue_addedCellNodes( VALUE self, VALUE index )
{
  int i, nodes[5];
  VALUE rb_nodes;
  GET_QUEUE_FROM_SELF;
  if (queue != queueAddedCellNodes(queue,NUM2INT(index),nodes)) return Qnil;
  rb_nodes = rb_ary_new2(5);
  for (i=0;i<5;i++) rb_ary_store(rb_nodes,i,INT2NUM(nodes[i]));
  return rb_nodes;
}

VALUE queue_addedCellXYZs( VALUE self, VALUE index )
{
  int i;
  double xyzs[12];
  VALUE rb_xyzs;
  GET_QUEUE_FROM_SELF;
  if (queue != queueAddedCellXYZs(queue,NUM2INT(index),xyzs)) return Qnil;
  rb_xyzs = rb_ary_new2(12);
  for (i=0;i<12;i++) rb_ary_store(rb_xyzs,i,rb_float_new(xyzs[i]));
  return rb_xyzs;
}

VALUE queue_totalRemovedCells( VALUE self )
{
  GET_QUEUE_FROM_SELF;
  return INT2NUM(queueTotalRemovedCells(queue));
}

/* ****************************** faces ****************************** */

VALUE queue_removeFace( VALUE self, VALUE rb_nodes )
{
  int i, nodes[3];
  GET_QUEUE_FROM_SELF;
  for (i=0;i<3;i++) nodes[i]=NUM2INT(rb_ary_entry(rb_nodes,i));
  return (queue==queueRemoveFace(queue,nodes)?self:Qnil);
}

VALUE queue_removedFaces( VALUE self, VALUE transaction )
{
  GET_QUEUE_FROM_SELF;
  return INT2NUM(queueRemovedFaces(queue,NUM2INT(transaction)));
}

VALUE queue_removedFaceNodes( VALUE self, VALUE index )
{
  int i, nodes[3];
  VALUE rb_nodes;
  GET_QUEUE_FROM_SELF;
  if (queue != queueRemovedFaceNodes(queue,NUM2INT(index),nodes)) return Qnil;
  rb_nodes = rb_ary_new2(3);
  for (i=0;i<3;i++) rb_ary_store(rb_nodes,i,INT2NUM(nodes[i]));
  return rb_nodes;
}

VALUE queue_addFace( VALUE self, VALUE rb_nodes, VALUE rb_uvs )
{
  int i, nodes[4];
  double uvs[6];
  GET_QUEUE_FROM_SELF;
  for (i=0;i<4;i++) nodes[i]=NUM2INT(rb_ary_entry(rb_nodes,i));
  for (i=0;i<6;i++) uvs[i] =NUM2DBL(rb_ary_entry(rb_uvs,i));
  return (queue==queueAddFace(queue,nodes,uvs)?self:Qnil);
}

VALUE queue_addedFaces( VALUE self, VALUE transaction )
{
  GET_QUEUE_FROM_SELF;
  return INT2NUM(queueAddedFaces(queue,NUM2INT(transaction)));
}

VALUE queue_addedFaceNodes( VALUE self, VALUE index )
{
  int i, nodes[4];
  VALUE rb_nodes;
  GET_QUEUE_FROM_SELF;
  if (queue != queueAddedFaceNodes(queue,NUM2INT(index),nodes)) return Qnil;
  rb_nodes = rb_ary_new2(4);
  for (i=0;i<4;i++) rb_ary_store(rb_nodes,i,INT2NUM(nodes[i]));
  return rb_nodes;
}

VALUE queue_addedFaceUVs( VALUE self, VALUE index )
{
  int i;
  double uvs[6];
  VALUE rb_uvs;
  GET_QUEUE_FROM_SELF;
  if (queue != queueAddedFaceUVs(queue,NUM2INT(index),uvs)) return Qnil;
  rb_uvs = rb_ary_new2(6);
  for (i=0;i<6;i++) rb_ary_store(rb_uvs,i,rb_float_new(uvs[i]));
  return rb_uvs;
}

VALUE queue_dump( VALUE self )
{
  VALUE array;
  int i, nInt, nDouble;
  int *ints;
  double *doubles;
  GET_QUEUE_FROM_SELF;

  if (queue != queueDumpSize(queue,&nInt,&nDouble)) return Qnil;

  ints = malloc(nInt * sizeof(int));
  doubles = malloc(nDouble * sizeof(double));

  if (queue != queueDump(queue,ints,doubles)) {
    free(ints);
    free(doubles);
    return Qnil;
  }

  array = rb_ary_new2(nInt+nDouble);
  for (i=0;i<nInt;i++) rb_ary_store(array,i,INT2NUM(ints[i]));
  for (i=0;i<nDouble;i++) rb_ary_store(array,nInt+i,rb_float_new(doubles[i]));
  return array;
}

VALUE queue_load( VALUE self, VALUE rb_ints, VALUE rb_doubles )
{
  Queue *result;
  int i, nInt, nDouble;
  int *ints;
  double *doubles;
  GET_QUEUE_FROM_SELF;

  nInt = RARRAY(rb_ints)->len;
  nDouble = RARRAY(rb_doubles)->len;

  ints = malloc(nInt * sizeof(int));
  doubles = malloc(nDouble * sizeof(double));

  for (i=0;i<nInt;i++) ints[i] = NUM2INT(rb_ary_entry(rb_ints,i));
  for (i=0;i<nDouble;i++) doubles[i] = NUM2DBL(rb_ary_entry(rb_doubles,i));

  result = queueLoad( queue, ints, doubles );

  free(ints);
  free(doubles);

  return (queue==result?self:Qnil);
}

VALUE cQueue;

void Init_Queue() 
{
  cQueue = rb_define_class( "Queue", rb_cObject );
  rb_define_singleton_method( cQueue, "new", queue_new, 0 );
  rb_define_method( cQueue, "reset", queue_reset, 0 );
  rb_define_method( cQueue, "transactions", queue_transactions, 0 );
  rb_define_method( cQueue, "newTransaction", queue_newTransaction, 0 );

  rb_define_method( cQueue, "removeCell", queue_removeCell, 1 );
  rb_define_method( cQueue, "removedCells", queue_removedCells, 1 );
  rb_define_method( cQueue, "removedCellNodes", queue_removedCellNodes, 1 );
  rb_define_method( cQueue, "addCell", queue_addCell, 2 );
  rb_define_method( cQueue, "addedCells", queue_addedCells, 1 );
  rb_define_method( cQueue, "addedCellNodes", queue_addedCellNodes, 1 );
  rb_define_method( cQueue, "addedCellXYZs", queue_addedCellXYZs, 1 );
  rb_define_method( cQueue, "totalRemovedCells", queue_totalRemovedCells, 0 );
  
  rb_define_method( cQueue, "removeFace", queue_removeFace, 1 );
  rb_define_method( cQueue, "removedFaces", queue_removedFaces, 1 );
  rb_define_method( cQueue, "removedFaceNodes", queue_removedFaceNodes, 1 );
  rb_define_method( cQueue, "addFace", queue_addFace, 2 );
  rb_define_method( cQueue, "addedFaces", queue_addedFaces, 1 );
  rb_define_method( cQueue, "addedFaceNodes", queue_addedFaceNodes, 1 );
  rb_define_method( cQueue, "addedFaceUVs", queue_addedFaceUVs, 1 );

  rb_define_method( cQueue, "dump", queue_dump, 0 );  
  rb_define_method( cQueue, "load", queue_load, 2 );
}
