require "/scripts/sexbound/util.lua"

function init()
  -- Handle Setup Actor
  message.setHandler("sexbound-setup-actor", function(_,_,args)
    Sexbound.Util.sendMessage(config.getParameter("controllerId"), "sexbound-setup-actor", args)
  end)
  
  -- Handle Remove Actor
  message.setHandler("sexbound-remove-actor", function(_,_,args)
    Sexbound.Util.sendMessage(config.getParameter("controllerId"), "sexbound-remove-actor", args)
  end)
end

function uninit()
  object.smash(true)
end
