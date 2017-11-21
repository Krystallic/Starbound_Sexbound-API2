--- Sexbound_Common Module.
-- @module Sexbound_Common

Sexbound_Common = {}

-- Override the init hook
sexbound_old_init = init
Sexbound_Common.init = function()
  status.setStatusProperty("sexbound_sex", false)

  sexbound_old_init()
  
  Sexbound_Common.initMessageHandlers()
  
  Sexbound_Common.restorePreviousStorage()
  
  self.sexbound = {
    hasSetupActor = false,
    mindControl = {
      damageSourceKind = "sexbound_mind_control"
    }
  }
end

-- Override the update hook
sexbound_old_update = update
Sexbound_Common.update = function(dt)
  sexbound_old_update(dt)
end

--- Attempt to invoke entity to give birth.
Sexbound_Common.tryToGiveBirth = function(callback)
  local worldTime = world.day() + world.timeOfDay()
  
  for i,v in ipairs(storage.pregnant) do
    local birthTime = v.birthDate + v.birthTime
    
    if worldTime >= birthTime then
      if type(callback) == "function" then
        callback()
      end
      
      table.remove(storage.pregnant, i)
    end
  end
end

Sexbound_Common.initMessageHandlers = function()
  message.setHandler("sexbound-sync-storage", function(_,_,args)
    storage = util.mergeTable(storage, args or {})
    
    sb.logInfo("Received request to sync storage.")
    sb.logInfo(sb.printJson( storage ))
  end)
 
  message.setHandler("sexbound-ui-dismiss", function(_,_,args)
    -- Do something when UI says player has dismissed it.
  end)
end

--- Attempt to restore this entity's previous storage parameters.
Sexbound_Common.restorePreviousStorage = function()
  storage = util.mergeTable(storage, config.getParameter("sexbound.previousStorage") or {})
end

Sexbound_Common.splashDamage = function()
  status.applySelfDamageRequest({
    damageType       = "IgnoresDef",
    damage           = 0,
    damageSourceKind = self.sexbound.mindControl.damageSourceKind,
    sourceEntityId   = entity.id()
  })
end

