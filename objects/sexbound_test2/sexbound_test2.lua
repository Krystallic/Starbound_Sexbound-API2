require "/scripts/sexbound/lib/sexbound.lua"

function init()
  Sexbound.API.init()
  
  Sexbound.API.Nodes.addNode({1,0})
  Sexbound.API.Nodes.addNode({2,0})
end

function update(dt)
  Sexbound.API.update(dt)
end

function onInteraction(args)
  return Sexbound.API.handleInteract(args) or nil
end

function uninit()
  Sexbound.API.uninit()
end
