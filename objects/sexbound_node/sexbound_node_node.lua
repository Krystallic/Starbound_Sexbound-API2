require "/scripts/sexbound/api/util.lua"

function init()
  -- Handle Setup Actor
  message.setHandler("main-setup-actor", function(_,_,args)
    Sexbound.API.Util.sendMessage(config.getParemeter("controllerId"), "main-setup-actor", args)
  end)
  
  -- Handle Remove Actor
  message.setHandler("main-remove-actor", function(_,_,args)
    Sexbound.API.Util.sendMessage(config.getParemeter("controllerId"), "main-remove-actor", args)
  end)
end

function uninit()
  object.smash(true)
end
