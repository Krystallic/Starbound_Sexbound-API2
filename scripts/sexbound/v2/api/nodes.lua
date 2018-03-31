--- Sexbound.API.Nodes Module.
-- @module Sexbound.API.Nodes
-- @author Loxodon
-- @license GNU General Public License v3.0

Sexbound.API.Nodes = {}

--- Add a new node object to the current world.
-- @param tilePosition A Vec2I position to place the 8 x 8 pixel node. It is placed relative to the imagePosition of this object.
-- @param sitPosition A Vec2I position to place the character who sits in this object.
-- @usage Sexbound.API.Nodes.addNode({0, 0}, {0, 20})
Sexbound.API.Nodes.addNode = function( tilePosition, sitPosition )
  if self._sexbound then
    self._sexbound:addNode( tilePosition, sitPosition )
  end
end

--- Stores this object adds a node.
-- @param sitPosition A Vec2I position to place the character who sits in this object.
-- @usage Sexbound.API.Nodes.addNode({0, 20})
Sexbound.API.Nodes.becomeNode = function( sitPosition )
  if self._sexbound then
    self._sexbound:becomeNode(sitPosition)
  end
end