--- Sexbound.API.Nodes Submodule.
-- @submodule Sexbound.API
Sexbound.API.Nodes = {}

--- Creates a new Node.
-- @param tilePosition
function Sexbound.API.Nodes.addNode(tilePosition)
  table.insert(self.sexboundData.nodes, Sexbound.Core.Node.new( tilePosition, true ))
  
  self.sexboundData.nodeCount = self.sexboundData.nodeCount + 1
end

--- Returns a reference to all Nodes.
function Sexbound.API.Nodes.getNodes()
  return self.sexboundData.nodes
end

--- Returns the count of nodes.
function Sexbound.API.Nodes.getCount()
  return self.sexboundData.nodeCount
end

--- Uninitializes all Nodes.
function Sexbound.API.Nodes.uninit()
  while self.sexboundData.nodeCount > 0 do
    self.sexboundData.nodes[1]:uninit()
  
    table.remove(self.sexboundData.nodes, 1)
  
    self.sexboundData.nodeCount = self.sexboundData.nodeCount - 1
  end
end