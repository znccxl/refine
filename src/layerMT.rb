#!/usr/bin/env ruby
#
# $Id$
#
# Mobility test for layer c lib

GC.disable # layer does not mark grid, so bug on GC

exit 1 unless system 'ruby makeRubyExtension.rb Grid adj.c gridStruct.h master_header.h'
exit 1 unless system 'ruby makeRubyExtension.rb GridMetric adj.c grid.c gridStruct.h master_header.h'
exit 1 unless system 'ruby makeRubyExtension.rb GridCAD FAKEGeom adj.c grid.c gridmetric.h gridinsert.h gridStruct.h master_header.h'
exit 1 unless system 'ruby makeRubyExtension.rb Layer adj.c grid.h gridmetric.h gridcad.h gridinsert.h master_header.h'

require 'test/unit'
require 'Grid/Grid'
require 'GridMetric/GridMetric'
require 'GridCAD/GridCAD'
require 'Layer/Layer'

class Grid
 include GridMetric
 include GridCAD
end

class TestLayer < Test::Unit::TestCase

 def testInit
  assert_not_nil  grid = Grid.new(2,0,0,0)
  assert_not_nil  layer = Layer.new(grid)
  assert_equal 2, layer.maxnode
  assert_equal 0, layer.ntriangle
  assert_equal 0, layer.maxtriangle
  assert_equal 0, layer.nnormal
  assert_equal 0, layer.maxnormal
 end

 def XtestInitGC # GC is disabled now
  assert_not_nil  grid = Grid.new(2,0,0,0)
  assert_not_nil  layer = Layer.new(grid)
  assert_equal 2, layer.maxnode
  assert_not_nil  grid = String.new("hello")
  assert_nil      GC.start
  assert_equal 2, layer.maxnode
 end

 def testInsertTriangleIntoLayer
  layer = Layer.new(Grid.new(4,0,2,0))
  assert_nil               layer.triangle(0)
  assert_nil               layer.triangleNormals(0)
  assert_equal layer,      layer.addTriangle(0,1,2)
  assert_equal 1,          layer.ntriangle
  assert                   layer.maxtriangle>=1
  assert_nil               layer.triangle(-1)
  assert_equal [0,1,2],    layer.triangle(0)
  assert_equal [0,1,2],    layer.triangleNormals(0)
  assert_equal 0,          layer.constrainedSide(0,0)
  assert_equal 0,          layer.constrainedSide(0,1)
  assert_equal 0,          layer.constrainedSide(0,2)
  assert_equal 0,          layer.parentGeomEdge(0,0)
  assert_equal 0,          layer.parentGeomEdge(0,1)
  assert_equal 0,          layer.parentGeomEdge(0,2)
  assert_nil               layer.triangle(1)
 end

 def testPopulateAdvancingFront
  assert_not_nil        grid = Grid.new(4,0,2,0)
  assert_equal grid,    grid.addFace(0,1,2,1)
  assert_equal grid,    grid.addFace(0,1,3,2)
  assert_equal 2,       grid.nface
  assert_not_nil        layer = Layer.new(grid)
  assert_equal layer,   layer.populateAdvancingFront([1,2])
  assert_equal 2,       layer.ntriangle
  assert_equal [0,1,2], layer.triangle(0)
  assert_equal [0,1,3], layer.triangle(1)
 end

 def testRememberTriangleParentGeomFaces
  layer = Layer.new(Grid.new(0,0,0,0))
  assert_equal false,   layer.parentGeomFace(5)
  assert_equal false,   layer.parentGeomFace(12)
  assert_equal layer,   layer.addParentGeomFace(12)
  assert_equal false,   layer.parentGeomFace(5)
  assert_equal true,    layer.parentGeomFace(12)
  assert_equal layer,   layer.addParentGeomFace(5)
  assert_equal true,    layer.parentGeomFace(5)
  assert_equal true,    layer.parentGeomFace(12)
  assert_nil            layer.addParentGeomFace(5)
 end

 def testAddNormalDynamicAllocates
  layer = Layer.new(Grid.new(235,0,0,0))
  assert_equal(-1,         layer.addNormal(-1) )
  assert_equal(-1,         layer.addNormal(layer.maxnode) )
  assert_equal 0,          layer.nnormal
  assert_equal 0,          layer.addNormal(33)
  assert_equal 1,          layer.addNormal(234)
  assert_equal 2,          layer.nnormal
  assert                   layer.maxnormal>=layer.nnormal
 end

 def testWeGetUniqueNormals
  layer = Layer.new(Grid.new(42,0,0,0))
  assert_equal 0, layer.uniqueNormalId(40)
  assert_equal 0, layer.uniqueNormalId(40)
  assert_equal 1, layer.uniqueNormalId(24)
  assert_equal 0, layer.uniqueNormalId(40)
 end

 def testUniqueNormalSetsANormalsRootToGlobalNode
  layer = Layer.new(Grid.new(42,0,0,0))
  assert_equal 0,  layer.uniqueNormalId(40)
  assert_equal 1,  layer.uniqueNormalId(24)
  assert_equal 40, layer.normalRoot(0)  
  assert_equal 24, layer.normalRoot(1)  
 end

 def testMakeNormals
  assert_not_nil        grid = Grid.new(5,0,2,0)
  assert_equal grid,    grid.addFace(1,2,3,1)
  assert_equal grid,    grid.addFace(1,2,4,2)
  assert_not_nil        layer = Layer.new(grid)
  assert_equal layer,   layer.populateAdvancingFront([1,2])
  assert_equal 4,       layer.nnormal
  assert_equal [0,1,2], layer.triangleNormals(0)
  assert_equal [0,1,3], layer.triangleNormals(1)
  assert_equal 1,       layer.normalRoot(0)
  assert_equal 2,       layer.normalRoot(1)
  assert_equal 3,       layer.normalRoot(2)
  assert_equal 4,       layer.normalRoot(3)
 end

 def testConstrainNormals
  assert_not_nil        grid = Grid.new(6,0,3,0)
  assert_equal grid,    grid.addFace(0,1,2,1)
  assert_equal grid,    grid.addFace(0,1,3,2)
  assert_equal grid,    grid.addFace(0,3,4,773)
  assert_not_nil        layer = Layer.new(grid)
  assert_nil            layer.constrainNormal(3)
  assert_equal 0,       layer.constrained(0)
  assert_equal layer,   layer.populateAdvancingFront([1,2])
  assert_equal 2,       layer.ntriangle
  assert_equal 4,       layer.nnormal
  assert_equal 0,       layer.constrained(0)
  assert_equal 0,       layer.constrained(1)
  assert_equal 0,       layer.constrained(2)
  assert_equal 0,       layer.constrained(3)
  assert_nil            layer.constrainNormal(0)
  assert_equal layer,   layer.constrainNormal(773)
  assert_equal 773,     layer.constrained(0)
  assert_equal 0,       layer.constrained(1)
  assert_equal 0,       layer.constrained(2)
  assert_equal 773,     layer.constrained(3)

  assert_equal 0,       layer.nConstrainedSides(0)
  assert_equal 1,       layer.nConstrainedSides(773)
 end

 def testRememberConstrainingFacesAndEdges
  assert_not_nil        grid = Grid.new(3,0,1,0)
  assert_equal grid,    grid.addFace(0,1,2,1)
  assert_not_nil        layer = Layer.new(grid)
  assert_equal layer,   layer.populateAdvancingFront([1])
  assert_nil            layer.constrainNormal(0)
  assert_equal layer,   layer.constrainNormal(2)
  assert_equal layer,   layer.constrainNormal(-1)
  assert_equal false,   layer.constrainingGeometry(-2)
  assert_equal true,    layer.constrainingGeometry(-1)
  assert_equal false,   layer.constrainingGeometry(0)
  assert_equal false,   layer.constrainingGeometry(1)
  assert_equal true,    layer.constrainingGeometry(2)
  assert_equal false,   layer.constrainingGeometry(3)
 end

 def testConstrainNormalForEdge
  assert_not_nil        grid = Grid.new(6,0,3,1)
  assert_equal grid,    grid.addFace(1,2,3,1)
  assert_equal grid,    grid.addFace(1,2,0,2)
  assert_equal grid,    grid.setNGeomNode(2)
  assert_equal grid,    grid.setNGeomEdge(1)
  assert_equal grid,    grid.addGeomEdge(1,0,2)
  assert_equal grid,    grid.addEdge(0,1,1,0.0,1.0)
  assert_not_nil        layer = Layer.new(grid)
  assert_equal layer,   layer.populateAdvancingFront([1])
  assert_equal 3,       layer.nnormal
  assert_equal layer,   layer.constrainNormal(-1)
  assert_equal layer,   layer.constrainNormal(2)
  assert_equal(-1,      layer.constrained(0))
  assert_equal 2,       layer.constrained(1)
  assert_equal 0,       layer.constrained(2)
 end

 def testConstrainTriangleSide
  assert_not_nil        grid = Grid.new(6,0,3,0)
  assert_equal grid,    grid.addFace(0,1,2,1)
  assert_not_nil        layer = Layer.new(grid)
  assert_equal 0,       layer.constrainedSide(0,0)
  assert_equal layer,   layer.populateAdvancingFront([1])
  assert_equal 0,       layer.constrainedSide(0,0)
  assert_equal 0,       layer.constrainedSide(0,1)
  assert_equal 0,       layer.constrainedSide(0,2)
  assert_equal 0,       layer.constrainedSide(0,3)
  assert_equal 0,       layer.constrainedSide(1,0)
  assert_nil   layer.constrainTriangleSide(-1,0,0)
  assert_nil   layer.constrainTriangleSide(layer.nnormal,0,0)
  assert_nil   layer.constrainTriangleSide(0,-1,0)
  assert_nil   layer.constrainTriangleSide(0,layer.nnormal,0)
  assert_equal 0,       layer.constrainedSide(0,0)
  assert_equal 0,       layer.constrainedSide(0,1)
  assert_equal 0,       layer.constrainedSide(0,2)
  assert_equal layer,   layer.constrainTriangleSide(0,1,1)
  assert_equal layer,   layer.constrainTriangleSide(1,2,2)
  assert_equal layer,   layer.constrainTriangleSide(0,2,3)
  assert_equal 1,       layer.constrainedSide(0,0)
  assert_equal 2,       layer.constrainedSide(0,1)
  assert_equal 3,       layer.constrainedSide(0,2)
 end

 def testConstrainTriangleSideWithBCFace
  assert_not_nil        grid = Grid.new(6,0,3,0)
  assert_equal grid,    grid.addFace(0,1,2,1)
  assert_equal grid,    grid.addFace(1,2,3,2)
  assert_not_nil        layer = Layer.new(grid)
  assert_equal layer,   layer.populateAdvancingFront([1])
  assert_equal 0,       layer.constrainedSide(0,0)
  assert_equal 0,       layer.constrainedSide(0,1)
  assert_equal 0,       layer.constrainedSide(0,2)
  assert_equal layer,   layer.constrainNormal(2)
  assert_equal 0,       layer.constrainedSide(0,0)
  assert_equal 2,       layer.constrainedSide(0,1)
  assert_equal 0,       layer.constrainedSide(0,2)
 end

 def testRememberTriangleEdgeParent
  assert_not_nil        grid = Grid.new(6,0,3,0)
  assert_equal grid,    grid.addFace(0,1,2,1)
  assert_not_nil        layer = Layer.new(grid)
  assert_equal 0,       layer.parentGeomEdge(0,0)
  assert_equal layer,   layer.populateAdvancingFront([1])
  assert_equal 0,       layer.parentGeomEdge(0,0)
  assert_equal 0,       layer.parentGeomEdge(0,1)
  assert_equal 0,       layer.parentGeomEdge(0,2)
  assert_equal 0,       layer.parentGeomEdge(0,3)
  assert_equal 0,       layer.parentGeomEdge(1,0)
  assert_nil            layer.setParentGeomEdge(-1,0,0)
  assert_nil            layer.setParentGeomEdge(layer.nnormal,0,0)
  assert_nil            layer.setParentGeomEdge(0,-1,0)
  assert_nil            layer.setParentGeomEdge(0,layer.nnormal,0)
  assert_equal 0,       layer.parentGeomEdge(0,0)
  assert_equal 0,       layer.parentGeomEdge(0,1)
  assert_equal 0,       layer.parentGeomEdge(0,2)
  assert_equal 0,       layer.nParentGeomEdgeSegments(0)
  assert_equal 0,       layer.nParentGeomEdgeSegments(1)
  assert_equal layer,   layer.setParentGeomEdge(0,1,1)
  assert_equal layer,   layer.setParentGeomEdge(1,2,2)
  assert_equal layer,   layer.setParentGeomEdge(0,2,3)
  assert_equal 1,       layer.parentGeomEdge(0,0)
  assert_equal 2,       layer.parentGeomEdge(0,1)
  assert_equal 3,       layer.parentGeomEdge(0,2)
  assert_equal 0,       layer.nParentGeomEdgeSegments(0)
  assert_equal 1,       layer.nParentGeomEdgeSegments(1)
 end

 def testFindParentalEdgesForTriangle
  assert_not_nil        grid = Grid.new(10,10,10,10)
  assert_equal grid,    grid.addFace(0,1,2,1)
  assert_equal grid,    grid.addEdge(0,1,1,0,1)
  assert_equal grid,    grid.addEdge(0,4,1,0,1)
  assert_not_nil        layer = Layer.new(grid)
  assert_nil            layer.findParentGeomEdges
  assert_equal layer,   layer.populateAdvancingFront([1])
  assert_equal 0,       layer.parentGeomEdge(0,0)
  assert_equal 0,       layer.parentGeomEdge(0,1)
  assert_equal 0,       layer.parentGeomEdge(0,2)
  assert_equal 0,       layer.nParentGeomEdgeSegments(1)
  assert_equal layer,   layer.findParentGeomEdges
  assert_equal 1,       layer.parentGeomEdge(0,0)
  assert_equal 0,       layer.parentGeomEdge(0,1)
  assert_equal 0,       layer.parentGeomEdge(0,2)
  assert_equal 1,       layer.nParentGeomEdgeSegments(1)
 end

 def testNormalTriangleNeighbors
  assert_not_nil        grid = Grid.new(4,0,3,0)
  assert_equal grid,    grid.addFace(0,1,2,1)
  assert_equal grid,    grid.addFace(0,1,3,2)
  assert_equal grid,    grid.addFace(1,2,3,3)
  assert_not_nil        layer = Layer.new(grid)
  assert_equal 0,       layer.normalDeg(0)
  assert_nil            layer.normalTriangles(0)
  assert_equal layer,   layer.populateAdvancingFront([1,2,3])
  assert_equal [0,1,2], layer.triangleNormals(0)
  assert_equal [0,1,3], layer.triangleNormals(1)
  assert_equal [1,2,3], layer.triangleNormals(2)
  assert_equal 2,       layer.normalDeg(0)
  assert_equal 3,       layer.normalDeg(1)
  assert_equal [1,0],   layer.normalTriangles(0)
  assert_equal [2,1,0], layer.normalTriangles(1)
  assert_equal [2,0],   layer.normalTriangles(2)
  assert_equal [2,1],   layer.normalTriangles(3)
 end

 def testNormalDirection1Face
  assert_not_nil          grid = Grid.new(3,0,1,0)
  assert_equal 0,         grid.addNode(0,0,0)
  assert_equal 1,         grid.addNode(1,0,0)
  assert_equal 2,         grid.addNode(0,1,0)
  assert_equal grid,      grid.addFace(0,1,2,1)
  assert_not_nil          layer = Layer.new(grid)
  assert_nil              layer.triangleDirection(-1)
  assert_nil              layer.triangleDirection(0)
  assert_nil              layer.normalDirection(0)
  assert_equal layer,     layer.populateAdvancingFront([1])
  direction = [0.0,0.0,1.0]
  assert_equal direction, layer.triangleDirection(0)
  assert_equal direction, layer.normalDirection(0)
  assert_equal direction, layer.normalDirection(1)
  assert_equal direction, layer.normalDirection(2)
 end

 def testNormalDirection2Face
  assert_not_nil          grid = Grid.new(4,0,2,0)
  assert_equal 0,         grid.addNode(0,0,0)
  assert_equal 1,         grid.addNode(1,0,0)
  assert_equal 2,         grid.addNode(0,1,0)
  assert_equal 3,         grid.addNode(0,0,1)
  assert_equal grid,      grid.addFace(0,1,2,1)
  assert_equal grid,      grid.addFace(0,3,1,1)
  assert_not_nil          layer = Layer.new(grid)
  assert_equal layer,     layer.populateAdvancingFront([1])
  assert_equal [0.0,0.0,1.0], layer.triangleDirection(0)
  assert_equal [0.0,1.0,0.0], layer.triangleDirection(1)
  halfSqrt2 = 0.5 * Math::sqrt(2)
  direction = [0.0, halfSqrt2, halfSqrt2]
  assert_equal direction, layer.normalDirection(0)
  assert_equal direction, layer.normalDirection(1)
  assert_equal [0.0,0.0,1.0], layer.normalDirection(2)
  assert_equal [0.0,1.0,0.0], layer.normalDirection(3)
 end

 def testNormalDirectionVisible
  assert_not_nil          grid = Grid.new(5,0,3,0)
  assert_equal 0,         grid.addNode( 0, 0, 0)
  assert_equal 1,         grid.addNode( 1, 0, 0)
  assert_equal 2,         grid.addNode(-1, 0, 0)
  assert_equal 3,         grid.addNode( 0, 1,-0.1)
  assert_equal 4,         grid.addNode( 0, 1, 0.1)
  assert_equal grid,      grid.addFace(0,3,1,1)
  assert_equal grid,      grid.addFace(0,1,4,1)
  assert_equal grid,      grid.addFace(0,4,2,1)
  assert_not_nil          layer = Layer.new(grid)
  assert_equal layer,     layer.populateAdvancingFront([1])
  norm = layer.normalDirection(0)
  assert_in_delta(  0.000, norm[0], 1e-3)
  assert_in_delta( -0.287, norm[1], 1e-3)
  assert_in_delta(  0.957, norm[2], 1e-3)
  assert_equal layer,     layer.visibleNormals
  norm = layer.normalDirection(0)
  assert_in_delta(  0.000, norm[0], 1e-3)
  assert_in_delta( -1.000, norm[1], 1e-4)
  assert_in_delta(  0.000, norm[2], 1e-2)
 end

 def testProjectNormalToEdge
  assert_not_nil          grid = Grid.new(9,9,9,9)
  assert_equal 0,         grid.addNode( 0, 0, 0)
  assert_equal 1,         grid.addNode( 0, 1, 0)
  assert_equal 2,         grid.addNode( 1, 0, 1)
  assert_equal 3,         grid.addNode( 1, 0, 0)
  assert_equal grid,      grid.addFace(0,1,2,22)
  assert_equal grid,      grid.addEdge(0,3,1,0,1)
  assert_equal grid,      grid.setNGeomEdge(1)
  assert_equal grid,      grid.addGeomEdge(1,0,3)
  assert_not_nil          layer = Layer.new(grid).populateAdvancingFront([22])
  assert_equal layer,     layer.constrainNormal(-1)
  norm = layer.normalDirection(0)
  assert_in_delta(  0.707, norm[0], 1e-3)
  assert_in_delta(  0.000, norm[1], 1e-3)
  assert_in_delta( -0.707, norm[2], 1e-3)
  assert_equal layer, layer.projectNormalsToConstraints
  norm = layer.normalDirection(0)
  assert_in_delta( 1.000, norm[0], 1e-3)
  assert_in_delta( 0.000, norm[1], 1e-3)
  assert_in_delta( 0.000, norm[2], 1e-3)
 end

 def testProjectNormalToFace
  assert_not_nil          grid = Grid.new(9,9,9,9)
  assert_equal 0,         grid.addNode( 0, 0, 0)
  assert_equal 1,         grid.addNode( 0, 1, 0)
  assert_equal 2,         grid.addNode( 1, 0, 1)
  assert_equal 3,         grid.addNode( 1, 0, 0)
  assert_equal grid,      grid.addFace(0,1,2,22)
  assert_equal grid,      grid.addFace(0,3,1,1)
  assert_not_nil          layer = Layer.new(grid).populateAdvancingFront([22])
  assert_equal layer,     layer.constrainNormal(1)
  norm = layer.normalDirection(0)
  assert_in_delta(  0.707, norm[0], 1e-3)
  assert_in_delta(  0.000, norm[1], 1e-3)
  assert_in_delta( -0.707, norm[2], 1e-3)
  assert_equal layer, layer.projectNormalsToConstraints
  norm = layer.normalDirection(0)
  assert_in_delta( 1.000, norm[0], 1e-3)
  assert_in_delta( 0.000, norm[1], 1e-3)
  assert_in_delta( 0.000, norm[2], 1e-3)
 end

 def testAdvanceLayerIntoVolume
  assert_not_nil          grid = Grid.new(7,4,1,0)
  assert_equal 0,         grid.addNode(0,0,0)
  assert_equal 1,         grid.addNode(1,0,0)
  assert_equal 2,         grid.addNode(0,1,0)
  assert_equal 3,         grid.addNode(0,0,1)
  grid.addCell(0,1,2,3)
  assert_equal 1,         grid.ncell
  assert_equal grid,      grid.addFace(0,1,2,1)
  assert_equal true,      grid.rightHandedFace(0)
  assert_equal true,      grid.rightHandedBoundary
  assert       0<         grid.minVolume, "negative volumes"
  assert_not_nil          layer = Layer.new(grid)
  assert_equal layer,     layer.populateAdvancingFront([1])
  assert_equal [0,1,2,3], grid.cell(0)
  assert_equal layer,     layer.advanceConstantHeight(0.1)
  assert_equal 7,         grid.nnode
  assert_equal [0,0,0.1], grid.nodeXYZ(4)
  assert_equal [1,0,0.1], grid.nodeXYZ(5)
  assert_equal [0,1,0.1], grid.nodeXYZ(6)
  assert_equal layer,     layer.wiggle(0.1)
  assert_equal [0,0,0.2], grid.nodeXYZ(4)
  assert_equal [1,0,0.2], grid.nodeXYZ(5)
  assert_equal [0,1,0.2], grid.nodeXYZ(6)
  assert_equal [4,5,6,3], grid.cell(0)
  assert_equal 4,         grid.ncell
  assert_equal true,      grid.rightHandedFace(0)
  assert_equal true,      grid.rightHandedBoundary
  assert       0<         grid.minVolume, "negative volumes"
 end

 def testAdvanceLayerIntoVolumeWithTwoFrontFacesOfVolumeCell
  assert_not_nil          grid = Grid.new(10,10,10,10)
  assert_equal 0,         grid.addNode(0,0,0)
  assert_equal 1,         grid.addNode(1,0,0)
  assert_equal 2,         grid.addNode(0,1,0)
  assert_equal 3,         grid.addNode(1,1,0.1)
  grid.addCell(0,1,2,3)
  assert_equal grid,      grid.addFace(0,1,2,1)
  assert_equal grid,      grid.addFace(1,3,2,1)
  assert_not_nil          layer = Layer.new(grid)
  assert_equal layer,     layer.populateAdvancingFront([1])
  assert_equal [0,1,2,3], grid.cell(0)
  assert_equal false,     layer.cellInLayer(0)
  assert_equal layer,     layer.advanceConstantHeight(0.1)
  assert_equal [4,5,6,7], grid.cell(0)
  assert_equal false,     layer.cellInLayer(0)
  assert_equal true,      layer.cellInLayer(1)
  assert_equal true,      layer.cellInLayer(2)
  assert_equal true,      layer.cellInLayer(3)
 end

 def testAdvanceLayerOnSymPlane
  assert_not_nil          grid = Grid.new(17,14,14,0)
  assert_equal 0,         grid.addNode(0,0,0)
  assert_equal 1,         grid.addNode(1,0,0)
  assert_equal 2,         grid.addNode(0,1,0)
  assert_equal 3,         grid.addNode(0,0,1)
  grid.addCell(0,1,2,3)
  assert_equal 1,         grid.ncell
  assert_equal grid,      grid.addFace(0,3,1,1)
  assert_equal grid,      grid.addFace(0,1,2,2)
  assert_equal true,      grid.rightHandedBoundary
  assert_not_nil          layer = Layer.new(grid)
  assert_equal layer,     layer.populateAdvancingFront([1])
  assert_equal layer,     layer.constrainNormal(2)
  assert_equal 2,         layer.constrained(0)
  assert_equal 0,         layer.constrained(1)
  assert_equal 2,         layer.constrained(2)
  assert_equal 0,         layer.constrainedSide(0,0)
  assert_equal 0,         layer.constrainedSide(0,1)
  assert_equal 2,         layer.constrainedSide(0,2)
  assert_equal [0,1,2,3], grid.cell(0)
  assert_equal [0,3,1,1], grid.face(0)
  assert_equal [0,1,2,2], grid.face(1)
  assert_equal true,      layer.faceInLayer(0)
  assert_equal false,     layer.faceInLayer(1)
  assert_equal layer,     layer.advanceConstantHeight(0.1)
  assert_equal 7,         grid.nnode
  assert_equal [4,6,2,5], grid.cell(0)
  assert_equal 4,         grid.ncell
  assert_equal [0,3,1,1], grid.face(0)
  assert_equal [4,6,2,2], grid.face(1)
  assert_equal [0,1,6,2], grid.face(2)
  assert_equal [0,6,4,2], grid.face(3)
  assert_equal true,      layer.faceInLayer(0)
  assert_equal false,     layer.faceInLayer(1)
  assert_equal true,      layer.faceInLayer(2)
  assert_equal true,      layer.faceInLayer(3)
  assert_equal 4,         grid.nface
  assert_equal true,      grid.rightHandedBoundary
 end

 def testAdvanceLayerOnSymPlane0
  assert_not_nil          grid = Grid.new(17,14,14,0)
  assert_equal 0,         grid.addNode(0,0,0)
  assert_equal 1,         grid.addNode(1,0,0)
  assert_equal 2,         grid.addNode(0,1,0)
  assert_equal 3,         grid.addNode(0,0,1)
  grid.addCell(0,1,2,3)
  assert_equal 1,         grid.ncell
  assert_equal grid,      grid.addFace(0,1,2,1)
  assert_equal grid,      grid.addFace(0,3,1,2)
  assert_not_nil          layer = Layer.new(grid)
  assert_equal layer,     layer.populateAdvancingFront([1])
  assert_equal layer,     layer.constrainNormal(2)
  assert_equal 2,         layer.constrainedSide(0,0)
  assert_equal 0,         layer.constrainedSide(0,1)
  assert_equal 0,         layer.constrainedSide(0,2)
  assert_equal layer,     layer.advanceConstantHeight(0.1)
  assert_equal [1,0,5,2], grid.face(2)
  assert_equal [5,0,4,2], grid.face(3)
 end

 def testAdvanceLayerOnSymPlane1
  assert_not_nil          grid = Grid.new(17,14,14,0)
  assert_equal 0,         grid.addNode(0,0,0)
  assert_equal 1,         grid.addNode(1,0,0)
  assert_equal 2,         grid.addNode(0,1,0)
  assert_equal 3,         grid.addNode(0,0,1)
  grid.addCell(0,1,2,3)
  assert_equal 1,         grid.ncell
  assert_equal grid,      grid.addFace(0,1,2,1)
  assert_equal grid,      grid.addFace(1,3,2,2)
  assert_not_nil          layer = Layer.new(grid)
  assert_equal layer,     layer.populateAdvancingFront([1])
  assert_equal layer,     layer.constrainNormal(2)
  assert_equal 0,         layer.constrainedSide(0,0)
  assert_equal 2,         layer.constrainedSide(0,1)
  assert_equal 0,         layer.constrainedSide(0,2)
  assert_equal layer,     layer.advanceConstantHeight(0.1)
  assert_equal [2,1,6,2], grid.face(2)
  assert_equal [6,1,5,2], grid.face(3)
 end

 def testAdvanceLayerOnSymPlane2
  assert_not_nil          grid = Grid.new(17,14,14,0)
  assert_equal 0,         grid.addNode(0,0,0)
  assert_equal 1,         grid.addNode(1,0,0)
  assert_equal 2,         grid.addNode(0,1,0)
  assert_equal 3,         grid.addNode(0,0,1)
  grid.addCell(0,1,2,3)
  assert_equal 1,         grid.ncell
  assert_equal grid,      grid.addFace(0,1,2,1)
  assert_equal grid,      grid.addFace(2,3,0,2)
  assert_not_nil          layer = Layer.new(grid)
  assert_equal layer,     layer.populateAdvancingFront([1])
  assert_equal layer,     layer.constrainNormal(2)
  assert_equal 0,         layer.constrainedSide(0,0)
  assert_equal 0,         layer.constrainedSide(0,1)
  assert_equal 2,         layer.constrainedSide(0,2)
  assert_equal layer,     layer.advanceConstantHeight(0.1)
  assert_equal [0,2,6,2], grid.face(2)
  assert_equal [0,6,4,2], grid.face(3)
 end

 def testAdvanceLayerOnSymPlane0TwoFace
  assert_not_nil          grid = Grid.new(17,14,14,0)
  assert_equal 0,         grid.addNode(0,0,0)
  assert_equal 1,         grid.addNode(1,0,0)
  assert_equal 2,         grid.addNode(0,1,0)
  assert_equal 3,         grid.addNode(1,1,0)
  assert_equal 4,         grid.addNode(0,0,1)
  assert_equal grid,      grid.addFace(1,3,2,1)
  assert_equal grid,      grid.addFace(0,1,2,1)
  assert_equal grid,      grid.addFace(0,4,1,2)
  assert_not_nil          layer = Layer.new(grid)
  assert_equal layer,     layer.populateAdvancingFront([1])
  assert_equal layer,     layer.constrainNormal(2)
  assert_equal 0,         layer.constrainedSide(0,0)
  assert_equal 0,         layer.constrainedSide(0,1)
  assert_equal 0,         layer.constrainedSide(0,2)
  assert_equal 2,         layer.constrainedSide(1,0)
  assert_equal 0,         layer.constrainedSide(1,1)
  assert_equal 0,         layer.constrainedSide(1,2)
  assert_equal layer,     layer.advanceConstantHeight(0.1)
  assert_equal [1,0,8,2], grid.face(3)
  assert_equal [1,8,5,2], grid.face(4)
 end

 def testAdvanceLayerTwiceOnSymPlane
  assert_not_nil          grid = Grid.new(15,17,16,0)
  assert_equal 0,         grid.addNode(0,0,0)
  assert_equal 1,         grid.addNode(1,0,0)
  assert_equal 2,         grid.addNode(0,1,0)
  assert_equal 3,         grid.addNode(0,0,1)
grid.addCell(0,1,2,3)
  assert_equal 1,         grid.ncell
  assert_equal grid,      grid.addFace(0,3,1,1)
  assert_equal grid,      grid.addFace(0,1,2,2)
  assert_equal true,      grid.rightHandedBoundary
  assert_not_nil          layer = Layer.new(grid)
  assert_equal layer,     layer.populateAdvancingFront([1])
  assert_equal layer,     layer.constrainNormal(2)
  assert_equal [0,1,2,3], grid.cell(0)
  assert_equal [0,3,1,1], grid.face(0)
  assert_equal [0,1,2,2], grid.face(1)
  assert_equal layer,     layer.advanceConstantHeight(0.1)
  assert_equal 7,         grid.nnode
  assert_equal [4,6,2,5], grid.cell(0)
  assert_equal [0,5,6,4], grid.cell(1)
  assert_equal [0,3,6,5], grid.cell(2)
  assert_equal [1,0,3,6], grid.cell(3)
  assert_equal 4,         grid.ncell
  assert_equal [0,3,1,1], grid.face(0)
  assert_equal [4,6,2,2], grid.face(1)
  assert_equal [0,1,6,2], grid.face(2)
  assert_equal [0,6,4,2], grid.face(3)
  assert_equal 4,         grid.nface

  assert_equal layer,     layer.advanceConstantHeight(0.1)
  assert_equal [7,9,2,8], grid.cell(0)
  assert_equal [0,5,6,4], grid.cell(1)
  assert_equal [0,3,6,5], grid.cell(2)
  assert_equal [1,0,3,6], grid.cell(3)
  assert_equal [4,8,9,7], grid.cell(4)
  assert_equal [4,5,9,8], grid.cell(5)
  assert_equal [6,4,5,9], grid.cell(6)
 
  assert_equal [0,3,1,1], grid.face(0)
  assert_equal [7,9,2,2], grid.face(1)
  assert_equal [0,1,6,2], grid.face(2)
  assert_equal [0,6,4,2], grid.face(3)
  assert_equal [4,6,9,2], grid.face(4)
  assert_equal [4,9,7,2], grid.face(5)

  assert_equal true,      grid.rightHandedBoundary
 end

 def testAdvanceLayerOnEdge
  assert_not_nil          grid = Grid.new(17,14,20,14)
  assert_equal 0,         grid.addNode(0,0,0)
  assert_equal 1,         grid.addNode(1,0,0)
  assert_equal 2,         grid.addNode(0,1,0)
  assert_equal 3,         grid.addNode(0,0,1)
  grid.addCell(0,1,2,3)
  assert_equal grid,      grid.addFace(0,2,3,1)
  assert_equal grid,      grid.addFace(0,1,2,2)
  assert_equal grid,      grid.addFace(0,3,1,3)
  assert_equal grid,      grid.setNGeomNode(2)
  assert_equal grid,      grid.setNGeomEdge(1)
  assert_equal grid,      grid.addGeomEdge(1,0,2)
  assert_equal grid,      grid.addEdge(0,1,1,0.0,1.0)
  assert_not_nil          layer = Layer.new(grid)
  assert_equal layer,     layer.populateAdvancingFront([1])
  assert_equal layer,     layer.constrainNormal(-1)
  assert_equal layer,     layer.constrainNormal(2)
  assert_equal layer,     layer.constrainNormal(3)
  assert_equal(-1,        layer.constrained(0))
  assert_equal 2,         layer.constrained(1)
  assert_equal 3,         layer.constrained(2)
  assert_equal [0,2,3,1], grid.face(0)
  assert_equal [0,1,2,2], grid.face(1)
  assert_equal [0,3,1,3], grid.face(2)
  assert_equal [0,1,1],   grid.edge(0)
  assert_equal false,     layer.edgeInLayer(0)
  assert_equal layer,     layer.advanceConstantHeight(0.1)
  assert_equal 7,         grid.nnode
  assert_equal 4,         grid.ncell
  assert_equal 7,         grid.nface
  assert_equal 2,         grid.nedge
  assert_equal [4,1,1],   grid.edge(0)
  assert_equal [0,4,1],   grid.edge(1)
  assert_equal false,     layer.edgeInLayer(0)
  assert_equal true,      layer.edgeInLayer(1)
  assert_equal 0.0,       grid.nodeT(0,1)
  assert_equal 1.0,       grid.nodeT(1,1)
  assert_equal 0.1,       grid.nodeT(4,1)
  assert_equal [0,2,3,1], grid.face(0)
  assert_equal [4,1,5,2], grid.face(1)
  assert_equal [4,6,1,3], grid.face(2)
 end

 def testNormalTermination
  assert_not_nil          grid = Grid.new(7,4,1,0)
  assert_equal 0,         grid.addNode(0,0,0)
  assert_equal 1,         grid.addNode(1,0,0)
  assert_equal 2,         grid.addNode(0,1,0)
  assert_equal 3,         grid.addNode(0,0,1)
  grid.addCell(0,1,2,3)
  assert_equal 1,         grid.ncell
  assert_equal grid,      grid.addFace(0,1,2,1)
  assert_not_nil          layer = Layer.new(grid)
  assert_equal layer,     layer.populateAdvancingFront([1])
  assert_equal false,     layer.normalTerminated(0)
  assert_equal false,     layer.normalTerminated(1)
  assert_equal false,     layer.normalTerminated(2)
  assert_equal layer,     layer.terminateNormal(0)
  assert_equal layer,     layer.terminateNormal(1)
  assert_equal true,      layer.normalTerminated(0)
  assert_equal true,      layer.normalTerminated(1)
  assert_equal false,     layer.normalTerminated(2)
 end
 
 def volumeGrid
  grid = Grid.new(7,4,1,0)
  grid.addNode(0,0,0)
  grid.addNode(1,0,0)
  grid.addNode(0,1,0)
  grid.addNode(0,0,1)
  grid.addCell(0,1,2,3)
  grid.addFace(0,1,2,1)
 end

 def volumeLayer(grid)
  layer = Layer.new(grid)
  layer.populateAdvancingFront([1])
 end

 def testTerminateAll
  assert_not_nil grid  = volumeGrid
  assert_not_nil layer = volumeLayer(grid)
  assert_equal layer,     layer.terminateNormal(0)
  assert_equal layer,     layer.terminateNormal(1)
  assert_equal layer,     layer.terminateNormal(2)
  assert_equal layer,     layer.advanceConstantHeight(0.1)
  assert_equal 4,         grid.nnode
  assert_equal 1,         grid.ncell
 end

 def testTerminate01
  assert_not_nil grid  = volumeGrid
  assert_not_nil layer = volumeLayer(grid)
  assert_equal layer,     layer.terminateNormal(0)
  assert_equal layer,     layer.terminateNormal(1)
  assert_equal layer,     layer.advanceConstantHeight(0.1)
  assert_equal 5,         grid.nnode
  assert_equal 2,         grid.ncell
  assert_equal [2,0,1,4], grid.cell(1)
 end

 def testTerminate12
  assert_not_nil grid  = volumeGrid
  assert_not_nil layer = volumeLayer(grid)
  assert_equal layer,     layer.terminateNormal(1)
  assert_equal layer,     layer.terminateNormal(2)
  assert_equal layer,     layer.advanceConstantHeight(0.1)
  assert_equal 5,         grid.nnode
  assert_equal 2,         grid.ncell
  assert_equal [0,1,2,4], grid.cell(1)
 end

 def testTerminate20
  assert_not_nil grid  = volumeGrid
  assert_not_nil layer = volumeLayer(grid)
  assert_equal layer,     layer.terminateNormal(2)
  assert_equal layer,     layer.terminateNormal(0)
  assert_equal layer,     layer.advanceConstantHeight(0.1)
  assert_equal 5,         grid.nnode
  assert_equal 2,         grid.ncell
  assert_equal [0,1,2,4], grid.cell(1)
 end

 def testTerminate0
  assert_not_nil grid  = volumeGrid
  assert_not_nil layer = volumeLayer(grid)
  assert_equal layer,     layer.terminateNormal(0)
  assert_equal layer,     layer.advanceConstantHeight(0.1)
  assert_equal 6,         grid.nnode
  assert_equal 3,         grid.ncell
  assert_equal [0,1,5,4], grid.cell(1)
  assert_equal [2,0,1,5], grid.cell(2)
 end

 def testTerminate1
  assert_not_nil grid  = volumeGrid
  assert_not_nil layer = volumeLayer(grid)
  assert_equal layer,     layer.terminateNormal(1)
  assert_equal layer,     layer.advanceConstantHeight(0.1)
  assert_equal 6,         grid.nnode
  assert_equal 3,         grid.ncell
  assert_equal [0,1,5,4], grid.cell(1)
  assert_equal [2,0,1,5], grid.cell(2)
 end

 def testTerminate2
  assert_not_nil grid  = volumeGrid
  assert_not_nil layer = volumeLayer(grid)
  assert_equal layer,     layer.terminateNormal(2)
  assert_equal layer,     layer.advanceConstantHeight(0.1)
  assert_equal 6,         grid.nnode
  assert_equal 3,         grid.ncell
  assert_equal [0,5,2,4], grid.cell(1)
  assert_equal [0,1,2,5], grid.cell(2)
 end

 def testAdvanceLayerIntoVolumeWithVaribleHeight
  assert_not_nil          grid = Grid.new(7,4,1,0)
  assert_equal 0,         grid.addNode(0,0,0)
  assert_equal 1,         grid.addNode(1,0,0)
  assert_equal 2,         grid.addNode(0,1,0)
  assert_equal 3,         grid.addNode(0,0,1)
  grid.addCell(0,1,2,3)
  assert_equal 1,         grid.ncell
  assert_equal grid,      grid.addFace(0,1,2,1)
  assert_not_nil          layer = Layer.new(grid)
  assert_equal layer,     layer.populateAdvancingFront([1])
  assert_nil              layer.setNormalHeight(-1,0.0)
  assert_nil              layer.setNormalHeight(3,0.0)
  assert_equal layer,     layer.setNormalHeight(0,0.0)
  assert_equal layer,     layer.setNormalHeight(1,0.1)
  assert_equal layer,     layer.setNormalHeight(2,0.2)
  assert_equal true,      layer.normalTerminated(0)
  assert_equal false,     layer.normalTerminated(1)
  assert_equal false,     layer.normalTerminated(2)
  assert_equal layer,     layer.advance
  assert_equal 6,         grid.nnode
  assert_equal [0,0,0],   grid.nodeXYZ(0)
  assert_equal [1,0,0.1], grid.nodeXYZ(4)
  assert_equal [0,1,0.2], grid.nodeXYZ(5)
 end

 def testMixedElementModeToggleSwitch
  assert_not_nil              grid = Grid.new(10,10,10,10)
  assert_not_nil              layer = Layer.new(grid)
  assert_equal true,          layer.tetrahedraOnly
  assert_equal layer,         layer.toggleMixedElementMode
  assert_equal false,         layer.tetrahedraOnly
  assert_equal layer,         layer.toggleMixedElementMode
  assert_equal true,          layer.tetrahedraOnly
 end

 def testAllowedToTerminateMixedElementNormals
  assert_not_nil              grid = Grid.new(10,10,10,10)
  assert_equal 0,             grid.addNode(0,0,0)
  assert_equal 1,             grid.addNode(1,0,0)
  assert_equal 2,             grid.addNode(0,1,0)
  assert_equal grid,          grid.addFace(0,1,2,1)
  layer = Layer.new(grid).populateAdvancingFront([1]).toggleMixedElementMode
  assert_equal layer,         layer.terminateNormal(0)
  assert_equal layer,         layer.terminateNormal(1)
  assert_equal layer,         layer.terminateNormal(2)
  assert_equal true,          layer.normalTerminated(0)
  assert_equal true,          layer.normalTerminated(1)
  assert_equal true,          layer.normalTerminated(2)
 end

 
 def testAdvanceLayerIntoVolumeWithaPrism
  assert_not_nil              grid = Grid.new(10,10,10,10)
  assert_equal 0,             grid.addNode(0,0,0)
  assert_equal 1,             grid.addNode(1,0,0)
  assert_equal 2,             grid.addNode(0,1,0)
  assert_equal grid,          grid.addFace(0,1,2,1)
  assert_not_nil              layer = Layer.new(grid)
  assert_equal layer,         layer.populateAdvancingFront([1])
  assert_equal layer,         layer.toggleMixedElementMode
  assert_equal 3,             layer.nnormal
  assert_equal layer,         layer.advanceConstantHeight(0.1)
  assert_equal 6,             grid.nnode
  assert_equal [0,0,0.1],     grid.nodeXYZ(3)
  assert_equal [1,0,0.1],     grid.nodeXYZ(4)
  assert_equal [0,1,0.1],     grid.nodeXYZ(5)
  assert_equal [0,1,2,3,4,5], grid.prism(0)
 end

 def testAdvanceLayerOnSymPlaneWithaQuadFace
  assert_not_nil               grid = Grid.new(17,14,14,0)
  assert_equal 0,              grid.addNode(0,0,0)
  assert_equal 1,              grid.addNode(1,0,0)
  assert_equal 2,              grid.addNode(0,1,0)
  assert_equal 3,              grid.addNode(0,0,1)
  assert_equal grid,           grid.addFace(0,1,2,4000)
  assert_equal grid,           grid.addFace(0,3,1,6000)
  assert_not_nil               layer = Layer.new(grid)
  assert_equal layer,          layer.populateAdvancingFront([4000])
  assert_equal layer,          layer.constrainNormal(6000)
  assert_equal layer,          layer.toggleMixedElementMode
  assert_equal 0,              grid.nquad
  assert_equal layer,          layer.advanceConstantHeight(0.1)
  assert_equal [1,0,4,5,6000], grid.quad(0)
  assert_equal 1,              grid.nquad
 end

 def testAdvanceLayerOnSymPlaneWithaTreminatedQuadFace0
  assert_not_nil               grid = Grid.new(17,14,14,0)
  assert_equal 0,              grid.addNode(0,0,0)
  assert_equal 1,              grid.addNode(1,0,0)
  assert_equal 2,              grid.addNode(0,1,0)
  assert_equal 3,              grid.addNode(0,0,1)
  assert_equal grid,           grid.addFace(0,1,2,4000)
  assert_equal grid,           grid.addFace(0,3,1,6000)
  assert_not_nil               layer = Layer.new(grid)
  assert_equal layer,          layer.populateAdvancingFront([4000])
  assert_equal layer,          layer.constrainNormal(6000)
  assert_equal layer,          layer.toggleMixedElementMode
  assert_equal 2,              grid.nface
  assert_equal layer,          layer.terminateNormal(0)
  assert_equal layer,          layer.advanceConstantHeight(0.1)
  assert_equal [1,0,4,6000],   grid.face(2)
  assert_equal 3,              grid.nface
 end

 def testAdvanceLayerOnSymPlaneWithaTreminatedQuadFace1
  assert_not_nil               grid = Grid.new(17,14,14,0)
  assert_equal 0,              grid.addNode(0,0,0)
  assert_equal 1,              grid.addNode(1,0,0)
  assert_equal 2,              grid.addNode(0,1,0)
  assert_equal 3,              grid.addNode(0,0,1)
  assert_equal grid,           grid.addFace(0,1,2,4000)
  assert_equal grid,           grid.addFace(0,3,1,6000)
  assert_not_nil               layer = Layer.new(grid)
  assert_equal layer,          layer.populateAdvancingFront([4000])
  assert_equal layer,          layer.constrainNormal(6000)
  assert_equal layer,          layer.toggleMixedElementMode
  assert_equal 2,              grid.nface
  assert_equal layer,          layer.terminateNormal(1)
  assert_equal layer,          layer.advanceConstantHeight(0.1)
  assert_equal [1,0,4,6000],   grid.face(2)
  assert_equal 3,              grid.nface
 end

 def testAdvanceLayerIntoVolumeWithaTerminatedPrismOrTet0
  assert_not_nil              grid = Grid.new(10,10,10,10)
  assert_equal 0,             grid.addNode(0,0,0)
  assert_equal 1,             grid.addNode(1,0,0)
  assert_equal 2,             grid.addNode(0,1,0)
  assert_equal grid,          grid.addFace(0,1,2,1)
  assert_not_nil              layer = Layer.new(grid)
  assert_equal layer,         layer.populateAdvancingFront([1])
  assert_equal layer,         layer.toggleMixedElementMode
  assert_equal layer,         layer.terminateNormal(1)
  assert_equal layer,         layer.terminateNormal(2)
  assert_equal layer,         layer.advanceConstantHeight(0.1)
  assert_equal 4,             grid.nnode
  assert_equal [0,0,0.1],     grid.nodeXYZ(3)
  assert_equal 1,             grid.ncell
  assert_equal [0,1,2,3],     grid.cell(0)
 end

 def testAdvanceLayerIntoVolumeWithaTerminatedPrismOrTet1
  assert_not_nil              grid = Grid.new(10,10,10,10)
  assert_equal 0,             grid.addNode(0,0,0)
  assert_equal 1,             grid.addNode(1,0,0)
  assert_equal 2,             grid.addNode(0,1,0)
  assert_equal grid,          grid.addFace(0,1,2,1)
  assert_not_nil              layer = Layer.new(grid)
  assert_equal layer,         layer.populateAdvancingFront([1])
  assert_equal layer,         layer.toggleMixedElementMode
  assert_equal layer,         layer.terminateNormal(0)
  assert_equal layer,         layer.terminateNormal(2)
  assert_equal layer,         layer.advanceConstantHeight(0.1)
  assert_equal 4,             grid.nnode
  assert_equal [1,0,0.1],     grid.nodeXYZ(3)
  assert_equal 1,             grid.ncell
  assert_equal [0,1,2,3],     grid.cell(0)
 end

 def testAdvanceLayerIntoVolumeWithaTerminatedPrismOrTet2
  assert_not_nil              grid = Grid.new(10,10,10,10)
  assert_equal 0,             grid.addNode(0,0,0)
  assert_equal 1,             grid.addNode(1,0,0)
  assert_equal 2,             grid.addNode(0,1,0)
  assert_equal grid,          grid.addFace(0,1,2,1)
  assert_not_nil              layer = Layer.new(grid)
  assert_equal layer,         layer.populateAdvancingFront([1])
  assert_equal layer,         layer.toggleMixedElementMode
  assert_equal layer,         layer.terminateNormal(0)
  assert_equal layer,         layer.terminateNormal(1)
  assert_equal layer,         layer.advanceConstantHeight(0.1)
  assert_equal 4,             grid.nnode
  assert_equal [0,1,0.1],     grid.nodeXYZ(3)
  assert_equal 1,             grid.ncell
  assert_equal [2,0,1,3],     grid.cell(0)
 end

 def testAdvanceLayerIntoVolumeWithaTerminatedPrismOrPyramid0
  assert_not_nil              grid = Grid.new(10,10,10,10)
  assert_equal 0,             grid.addNode(0,0,0)
  assert_equal 1,             grid.addNode(1,0,0)
  assert_equal 2,             grid.addNode(0,1,0)
  assert_equal grid,          grid.addFace(0,1,2,1)
  assert_not_nil              layer = Layer.new(grid)
  assert_equal layer,         layer.populateAdvancingFront([1])
  assert_equal layer,         layer.toggleMixedElementMode
  assert_equal layer,         layer.terminateNormal(0)
  assert_equal layer,         layer.advanceConstantHeight(0.1)
  assert_equal 5,             grid.nnode
  assert_equal 0,             grid.ncell
  assert_equal 0,             grid.nprism
  assert_equal 1,             grid.npyramid
  assert_equal [1,2,0,3,4],   grid.pyramid(0)
 end

 def testAdvanceLayerIntoVolumeWithaTerminatedPrismOrPyramid1
  assert_not_nil              grid = Grid.new(10,10,10,10)
  assert_equal 0,             grid.addNode(0,0,0)
  assert_equal 1,             grid.addNode(1,0,0)
  assert_equal 2,             grid.addNode(0,1,0)
  assert_equal grid,          grid.addFace(0,1,2,1)
  assert_not_nil              layer = Layer.new(grid)
  assert_equal layer,         layer.populateAdvancingFront([1])
  assert_equal layer,         layer.toggleMixedElementMode
  assert_equal layer,         layer.terminateNormal(1)
  assert_equal layer,         layer.advanceConstantHeight(0.1)
  assert_equal 5,             grid.nnode
  assert_equal 0,             grid.ncell
  assert_equal 0,             grid.nprism
  assert_equal 1,             grid.npyramid
  assert_equal [2,0,1,4,3],   grid.pyramid(0)
 end

 def testAdvanceLayerIntoVolumeWithaTerminatedPrismOrPyramid2
  assert_not_nil              grid = Grid.new(10,10,10,10)
  assert_equal 0,             grid.addNode(0,0,0)
  assert_equal 1,             grid.addNode(1,0,0)
  assert_equal 2,             grid.addNode(0,1,0)
  assert_equal grid,          grid.addFace(0,1,2,1)
  assert_not_nil              layer = Layer.new(grid)
  assert_equal layer,         layer.populateAdvancingFront([1])
  assert_equal layer,         layer.toggleMixedElementMode
  assert_equal layer,         layer.terminateNormal(2)
  assert_equal layer,         layer.advanceConstantHeight(0.1)
  assert_equal 5,             grid.nnode
  assert_equal 0,             grid.ncell
  assert_equal 0,             grid.nprism
  assert_equal 1,             grid.npyramid
  assert_equal [0,1,2,3,4],   grid.pyramid(0)
 end

end
