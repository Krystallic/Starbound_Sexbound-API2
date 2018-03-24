--- Sexbound.API.Nodes Module.
-- @module Sexbound.API.Nodes
-- @author Loxodon
-- @license GNU General Public License v3.0

Sexbound.API.Nodes = {}

Sexbound.API.Nodes.addNode = function( tilePosition )
  if self._sexbound then
    self._sexbound:addNode( tilePosition )
  end
end

Sexbound.API.Nodes.becomeNode = function()
  if self._sexbound then
    self._sexbound:becomeNode()
  end
end