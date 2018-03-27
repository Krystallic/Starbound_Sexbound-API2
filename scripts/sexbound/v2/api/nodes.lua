--- Sexbound.API.Nodes Module.
-- @module Sexbound.API.Nodes
-- @author Loxodon
-- @license GNU General Public License v3.0

Sexbound.API.Nodes = {}

Sexbound.API.Nodes.addNode = function( tilePosition, sitPosition )
  if self._sexbound then
    self._sexbound:addNode( tilePosition, sitPosition )
  end
end

Sexbound.API.Nodes.becomeNode = function( sitPosition )
  if self._sexbound then
    self._sexbound:becomeNode(sitPosition)
  end
end