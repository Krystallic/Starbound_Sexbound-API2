require "/scripts/sexbound.lua"

function init()
  Sexbound.Main.init()
  
  Sexbound.Main.createNode({1,0})
  Sexbound.Main.createNode({2,0})
end

function update(dt)
  Sexbound.Main.update(dt)
end

function onInteraction(args)
  return Sexbound.Main.handleInteract(args) or nil
end

function uninit()
  Sexbound.Main.handleUninit()
end
