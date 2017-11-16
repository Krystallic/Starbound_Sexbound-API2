--- Sexbound.API.Nodes Submodule.
-- @submodule Sexbound.API

Sexbound.API.Nodes = {}

--- Creates a new node.
-- @param tilePosition
function Sexbound.API.Nodes.createNode(tilePosition)
  table.insert(self.sexboundData.nodes, Sexbound.Core.Node.new( tilePosition, true ))
  
  self.sexboundData.nodeCount = self.sexboundData.nodeCount + 1
end

--- Uninitializes all nodes.
function Sexbound.API.Nodes.uninitNodes()
  while self.sexboundData.nodeCount > 0 do
    self.sexboundData.nodes[1]:uninit()
  
    table.remove(self.sexboundData.nodes, 1)
  
    self.sexboundData.nodeCount = self.sexboundData.nodeCount - 1
  end
end