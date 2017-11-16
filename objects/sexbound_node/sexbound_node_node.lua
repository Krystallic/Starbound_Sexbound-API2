require "/scripts/sexbound/api/util.lua"

function init()
  -- Handle Setup Actor
  message.setHandler("node-setup-actor", function(_,_,args)
    Sexbound.API.Util.sendMessage(config.getParemeter("controllerId"), "main-setup-actor", args)
  end)
end

function uninit()
  object.smash(true)
end
