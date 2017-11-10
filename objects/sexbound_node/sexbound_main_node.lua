require "/scripts/sexbound.lua"
require "/scripts/sexbound/controller/node.lua"

function init()
  -- Check if mindControl is in storage before setting it.
  if storage.mindControl then
    object.smash(true)
  end
  
  storage.mindControl = config.getParameter("mindControl")
  
  Sexbound.Main.init()
  
  NodeController.init()
end

function update(dt)
  Sexbound.Main.update(dt)
  
  if storage.mindControl then
    local worldTime = world.day() + world.timeOfDay()
    
    if not Sexbound.Main.getStatus("havingSex") and worldTime >= storage.mindControl.timeout then
      object.smash(true)
    end
  end
end

function onInteraction(args)
  Sexbound_Util.sendMessage(args.sourceId, "sexbound-lounge", {loungeId = entity.id()})

  return Sexbound.Main.handleInteract(args) or nil
end

function die()
  Sexbound.Main.respawnNPC()
end
  
