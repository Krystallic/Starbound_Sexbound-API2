--- Sexbound_Common Module.
-- @module Sexbound_Common

Sexbound_Common = {}

-- Override the init hook
sexbound_old_init = init
Sexbound_Common.init = function()
  status.setStatusProperty("sexbound_sex", false)

  sexbound_old_init()
  
  Sexbound_Common.initMessageHandlers()
  
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

Sexbound_Common.initMessageHandlers = function()  
  message.setHandler("sexbound-ui-dismiss", function(_,_,args)
    -- Do something when UI says player has dismissed it.
  end)
end

Sexbound_Common.splashDamage = function()
  status.applySelfDamageRequest({
    damageType       = "IgnoresDef",
    damage           = 0,
    damageSourceKind = self.sexbound.mindControl.damageSourceKind,
    sourceEntityId   = entity.id()
  })
end

