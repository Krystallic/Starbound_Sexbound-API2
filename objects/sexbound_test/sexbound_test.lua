require "/scripts/sexbound/v2/api.lua"

function init()
  Sexbound.API.init()
  
  local sitPositions  = config.getParameter("sexboundConfig.sitPositions")
  
  local nodePositions = config.getParameter("sexboundConfig.nodePositions")
  
  Sexbound.API.Nodes.addNode(nodePositions[1], sitPositions[1])
  Sexbound.API.Nodes.addNode(nodePositions[2], sitPositions[2])
  
  local testNPC = {
    id = -99999,
    entityType = "npc",
    identity = {
      name = "Ahuitl",
      species = "avian",
      gender = "female",
      facialHairFolder = "fluff",
      facialHairGroup = "fluff",
      facialHairType = "3",
      facialMaskFolder = "beaks",
      facialMaskGroup = "beaks",
      facialMaskType = "9",
      hairFolder = "hair",
      hairGroup = "hair",
      hairType = "10",
      bodyDirectives = "?replace;735e3a=977841;dc1f00=d7e8e8;6f2919=596809;ffca8a=add068;be1b00=8fa7a3;951500=5d6d69;a38d59=c1a24e;e0975c=85ac1b;d9c189=eacf60;a85636=6e8210;f32200=f6fbfb",
      emoteDirectives = "?replace;735e3a=977841;dc1f00=d7e8e8;6f2919=596809;ffca8a=add068;be1b00=8fa7a3;951500=5d6d69;a38d59=c1a24e;e0975c=85ac1b;d9c189=eacf60;a85636=6e8210;f32200=f6fbfb",
      hairDirectives = "?replace;735e3a=977841;dc1f00=d7e8e8;6f2919=596809;ffca8a=add068;be1b00=8fa7a3;951500=5d6d69;a38d59=c1a24e;e0975c=85ac1b;d9c189=eacf60;a85636=6e8210;f32200=f6fbfb",
      facialHairDirectives = "?replace;735e3a=977841;dc1f00=d7e8e8;6f2919=596809;ffca8a=add068;be1b00=8fa7a3;951500=5d6d69;a38d59=c1a24e;e0975c=85ac1b;d9c189=eacf60;a85636=6e8210;f32200=f6fbfb",
      facialMaskDirectives = "?replace;735e3a=977841;dc1f00=d7e8e8;6f2919=596809;ffca8a=add068;be1b00=8fa7a3;951500=5d6d69;a38d59=c1a24e;e0975c=85ac1b;d9c189=eacf60;a85636=6e8210;f32200=f6fbfb"
    }
  }
  
  Sexbound.API.Actors.addActor(testNPC)
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
