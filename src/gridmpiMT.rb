#!/usr/bin/env ruby
#
# $Id$
#
# Mobility test for grid c lib

Dir.chdir ENV['srcdir'] if ENV['srcdir']
require 'RubyExtensionBuilder'
RubyExtensionBuilder.new('GridMPI').build

require 'test/unit'
require 'Adj/Adj'
require 'Line/Line'
require 'Queue/Queue'
require 'Sort/Sort'
require 'Grid/Grid'
require 'GridMath/GridMath'
require 'GridMetric/GridMetric'
require 'GridInsert/GridInsert'
require 'GridSwap/GridSwap'
require 'GridMPI/GridMPI'

class Grid
 include GridMetric
 include GridInsert
 include GridSwap
 include GridMPI
end

class TestGridMPI < Test::Unit::TestCase

 EMPTY = -1

 def rightTet
  grid = Grid.new(4,2,4,0)
  grid.addCell( 
	       grid.addNode(0,0,0), 
	       grid.addNode(1,0,0), 
	       grid.addNode(0,1,0), 
	       grid.addNode(0,0,1) )
  grid.addFaceUV(0,0,0,
		 3,0,1,
		 1,1,0,
		 10)
  grid.addFaceUV(0,0,0,
		 2,1,0,
		 3,0,1,
		 11)
  grid.identityNodeGlobal(100).identityCellGlobal(200)
  grid.setGlobalNNode(104).setGlobalNCell(201)
  grid
 end 

 def swapTet3
  grid = Grid.new(5,3,0,0)
  grid.addNode(0,0,-10)
  grid.addNode(0,0,10)
  grid.addNode( 1,-1,0)
  grid.addNode( 0, 1,0)
  grid.addNode(-1,-1,0)
  grid.addCell(0,2,3,1)
  grid.addCell(0,3,4,1)
  grid.addCell(0,4,2,1)
  assert grid.minVolume>0.0, "negative volume cell "+grid.minVolume.to_s
  grid.identityNodeGlobal(100).identityCellGlobal(200)
  grid.setGlobalNNode(105).setGlobalNCell(205)
  grid
 end 

 def testCopyLocalNodeNumberingToGlobalNumbering
  plus = 544
  grid = Grid.new(10,0,0,0)
  10.times { grid.addNode(1,2,3) }
  assert_equal grid,grid.identityNodeGlobal(plus)
  10.times { |node| assert_equal node+plus, grid.nodeGlobal(node) }
 end

 def testCopyLocalCellNumberingToGlobalNumbering
  plus = 654
  grid = Grid.new(4,10,0,0)
  4.times { grid.addNode(1,2,3) }
  10.times { grid.addCell(0,1,2,3) }
  assert_equal grid, grid.identityCellGlobal(plus)
  10.times { |cell| assert_equal cell+plus, grid.cellGlobal(cell) }
 end

 def testMarkAllNodesAsLocal
  partId = 5
  grid = Grid.new(10,0,0,0).setPartId(partId)
  10.times { grid.addNode(1,2,3) }
  assert_equal grid, grid.setAllLocal
  10.times do |node| 
   assert_equal partId, grid.nodePart(node), "node #{node} part failed" 
  end
 end

 def testSetGhostNode
  partId = 7
  grid = Grid.new(1,0,0,0).setPartId(partId)
  grid.addNode(1,2,3)
  grid.setAllLocal
  assert_equal grid, grid.setGhost(0)
  assert_equal EMPTY, grid.nodePart(0)
 end

 def testLoadQueueWithSplit
  q = Queue.new 9
  p1 = rightTet.setPartId(1).setAllLocal
  p1.setNodePart(3,2)

  assert_equal 4, p1.parallelEdgeSplit(q,0,3)
  assert_equal 2, p1.ncell
  assert_equal 4, p1.nface
  assert_equal 105, p1.globalnnode
  assert_equal 202, p1.globalncell
  assert_equal p1.partId, p1.nodePart(4)
  assert_equal 104, p1.nodeGlobal(4)
  assert_equal 200, p1.cellGlobal(0)
  assert_equal 201, p1.cellGlobal(1)
  assert_equal 2, q.transactions
  assert_equal 1, q.removedCells(1)
  assert_equal [100,101,102,103], q.removedCellNodes(0)
  assert_equal [1,1,1,2],         q.removedCellNodeParts(0)
  assert_equal 1, q.addedCells(1)
  assert_equal [104,101,102,103], q.addedCellNodes(0)
  assert_equal 200,               q.addedCellId(0)
  assert_equal [1,1,1,2],         q.addedCellNodeParts(0)
  h=0.5
  assert_equal [ 0,0,h, 1,0,0,1,0,1, 
                 1,0,0, 1,0,0,1,0,1, 
                 0,1,0, 1,0,0,1,0,1, 
                 0,0,1, 1,0,0,1,0,1], q.addedCellXYZs(0)
  assert_equal 2, q.removedFaces(1)
  assert_equal [100,103,101], q.removedFaceNodes(0)
  assert_equal [100,102,103], q.removedFaceNodes(1)
  assert_equal [1,2,1], q.removedFaceNodeParts(0)
  assert_equal [1,1,2], q.removedFaceNodeParts(1)
  assert_equal 2, q.addedFaces(1)
  assert_equal [103,101,104], q.addedFaceNodes(0)
  assert_equal [103,104,102], q.addedFaceNodes(1)
  assert_equal 10, q.addedFaceId(0)
  assert_equal 11, q.addedFaceId(1)
  assert_equal [2,1,1], q.addedFaceNodeParts(0)
  assert_equal [2,1,1], q.addedFaceNodeParts(1)
 end

 def testUnPackQueue
  q = Queue.new 9
  p1 = rightTet.setPartId(1).setAllLocal
  p2 = rightTet.setPartId(2).setAllLocal
  p2.setNodePart(0,1).setNodePart(1,1).setNodePart(2,1)
  p1.setNodePart(3,2)

  assert_equal EMPTY, p2.parallelEdgeSplit(q,0,1), "split a ghost edge"
  assert_equal 1, p1.ncell
  assert_equal 1, q.transactions

  assert_equal 4, p1.parallelEdgeSplit(q,0,3)

  assert_equal p2, p2.applyQueue(q)
  assert_equal 0, p2.nUnusedCellGlobal

  assert_equal [4,1,2,3], p2.cell(0)

  assert_equal 4, p2.nnode
  assert_equal EMPTY, p2.nodeGlobal(0)
  assert_equal 101, p2.nodeGlobal(1)
  assert_equal 102, p2.nodeGlobal(2)
  assert_equal 103, p2.nodeGlobal(3)
  assert_equal 104, p2.nodeGlobal(4)
  assert_equal [0,0,0.5], p2.nodeXYZ(4)
  assert p2.nodeGhost(4)

  assert_equal 2, p2.nface
  assert_equal [3,4,2,11], p2.face(0)
  assert_equal [3,1,4,10], p2.face(1)
 end

 def testLoadQueueWithSwap
  q = Queue.new 9
  p1 = swapTet3.setPartId(1).setAllLocal
  p1.setNodePart(1,2).setNodePart(2,2).setNodePart(3,2).setNodePart(4,2)

  assert_equal p1, p1.parallelEdgeSwap(q,0,1)
  assert_equal 1, p1.ncell
  assert_equal 200, p1.cellGlobal(0)
  assert_equal [202], p1.getUnusedCellGlobal

  assert_equal 2, q.transactions

  assert_equal 3, q.removedCells(1)
  assert_equal [100,102,103,101], q.removedCellNodes(2)
  assert_equal [100,103,104,101], q.removedCellNodes(1)
  assert_equal [100,104,102,101], q.removedCellNodes(0)

  assert_equal 2, q.addedCells(1)
  assert_equal [100,102,103,104], q.addedCellNodes(0)
  assert_equal 200,               q.addedCellId(0)
  assert_equal [1,2,2,2],         q.addedCellNodeParts(0)
  assert_equal [101,102,104,103], q.addedCellNodes(1)
  assert_equal 201,               q.addedCellId(1)
  assert_equal [2,2,2,2],         q.addedCellNodeParts(1)
 end

end
