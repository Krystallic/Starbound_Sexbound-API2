--- Sexbound.Core.Actor Class Module.
-- @classmod Sexbound.Core.Actor
Sexbound.Core.Actor = {}
Sexbound.Core.Actor.__index = Sexbound.Core.Actor

require "/scripts/sexbound/core/climax.lua"
require "/scripts/sexbound/core/emote.lua"
require "/scripts/sexbound/core/moan.lua"
require "/scripts/sexbound/core/pregnant.lua"
require "/scripts/sexbound/core/sextalk.lua"

--- Instantiates a new instance of Actor.
-- @param actor
-- @param storeActor
function Sexbound.Core.Actor.new(actor, storeActor)
  local self = setmetatable({}, Sexbound.Core.Actor)
  
  -- Create new log utility.
  self.log = Sexbound.Core.Log.new({
    moduleName = "Actor | ID: " .. actor.id
  })
  
  -- Initialize the actor data object.
  self.actor = {
    config = util.mergeTable({}, Sexbound.API.getParameter("actor"))
  }
  
  -- Setup the actor.
  self:setup(actor, storeActor)
  
  return self
end

--- Updates this instance.
-- @param dt
function Sexbound.Core.Actor:update(dt)
  self.timer.emote = self.timer.emote + dt
  self.timer.moan  = self.timer.moan  + dt
  self.timer.talk  = self.timer.talk  + dt
  
  self.climax:update(dt)
  
  self.moan:update(dt)
  
  if self:entityType() == "npc" then
    self.sextalk:update(dt)
  end
  
  self.emote:update(dt)
  
  self.pregnant:update(dt)
end

--- Uninitializes this instance.
function Sexbound.Core.Actor:uninit()
  self:resetGlobalAnimatorTags(self.actor.actorNumber)
  
  self:resetTransformations(self.actor.actorNumber)
  
  self.emote:uninit()
end

--- Returns this Actor's current number.
function Sexbound.Core.Actor:actorNumber()
  return self.actor.actorNumber
end

--- Returns this Actor's entity type.
function Sexbound.Core.Actor:entityType()
  return self.actor.entityType
end

--- Returns this Actor's id.
function Sexbound.Core.Actor:id()
  return self.actor.id
end

--- Returns a reference to this Actor identifiers.
-- @param[opt] param
function Sexbound.Core.Actor:identity(param)
  if param then return self.actor.identity[param] end

  return self.actor.identity
end

--- Returns a validated facial hair folder name.
function Sexbound.Core.Actor:facialHairFolder()
  return self:identity("facialHairFolder") or self:identity("facialHairGroup") or ""
end

--- Returns a validated facial hair type.
function Sexbound.Core.Actor:facialHairType()
  return self:identity("facialHairType") or "1"
end

--- Returns a validated facial mask folder name.
function Sexbound.Core.Actor:facialMaskFolder()
  return self:identity("facialMaskFolder") or self:identity("facialMaskGroup") or ""
end

--- Returns a validated facial mask type.
function Sexbound.Core.Actor:facialMaskType()
  return self:identity("facialMaskType") or "1"
end

--- Returns this Actor's gender.
function Sexbound.Core.Actor:gender()
  return self.actor.identity.gender
end

--- Returns a validated hair folder name.
function Sexbound.Core.Actor:hairFolder()
  return self.actor.identity.hairFolder or self:identity("hairGroup") or "hair"
end

--- Returns a validated hair type.
function Sexbound.Core.Actor:hairType()
  return self:identity("hairType") or "1"
end

--- Returns the species value.
function Sexbound.Core.Actor:species()
  return self.actor.identity.species
end

--- Returns this Actor's current role.
function Sexbound.Core.Actor:role()
  return self.actor.role
end

--- Returns a reference to all of Actor's data.
function Sexbound.Core.Actor:getData()
  return self.actor
end

--- Retursn a reference to this actor's Climax instance.
function Sexbound.Core.Actor:getClimax()
  return self.climax
end

--- Returns a reference to this actor's Emote instance.
function Sexbound.Core.Actor:getEmote()
  return self.emote
end

--- Returns a reference to this actor's Moan instance.
function Sexbound.Core.Actor:getMoan()
  return self.moan
end

--- Returns a reference to this actor's Pregnant instance.
function Sexbound.Core.Actor:getPregnant()
  return self.pregnant
end

--- Applies transformations to animator parts.
-- @param actorNumber
-- @param position
function Sexbound.Core.Actor:applyTransformations(actorNumber, position)
  for i,partName in ipairs({"Body", "Climax", "Head"}) do
    if position["offset" .. partName] ~= nil then
      self:translateParts(actorNumber, partName, position["offset" .. partName][actorNumber])
    end
      
    if position["rotate" .. partName] ~= nil then
      self:rotatePart(actorNumber, partName, position["rotate" .. partName][actorNumber])
    end
      
    if position["flip" .. partName] ~= nil and position["flip" .. partName][actorNumber] == true then
      self:flipPart(actorNumber, partName)
    end
  end
end

--- Flips a specified part in the animator.
-- @param actorNumber
-- @param partName
function Sexbound.Core.Actor:flipPart(actorNumber, partName)
  if (animator.hasTransformationGroup("actor" .. actorNumber .. partName)) then
    animator.scaleTransformationGroup("actor" .. actorNumber .. partName, {-1, 1}, {0, 0})
  end
end

--- Resets an specified actor.
-- @param actorNumber
-- @param position
function Sexbound.Core.Actor:reset(actorNumber, position)
  local defaultPath = "/artwork/humanoid/default.png:default"
  
  -- Set the actor's role.
  self.actor.role = "actor" .. actorNumber
  
  self.actor.actorNumber = actorNumber
  
  self.emote:reset()
  
  self:resetGlobalAnimatorTags(actorNumber)
  
  self:resetTransformations(actorNumber)
  
  self:applyTransformations(actorNumber, position)
    
  if self.sextalk then
    -- Refresh sextalk dialog pool.
    self.sextalk:refreshDialogPool()
  
    if Sexbound.API.Actors.getCount() > 1 then
      -- Say random dialog message.
      self.sextalk:sayRandom()
    end
  end
  
  -- Set the directives.
  local directives = {
    body = self:identity("bodyDirectives") or "",
    emote = self:identity("emoteDirectives") or "",
    hair = self:identity("hairDirectives") or "",
    facialHair = self:identity("facialHairDirectives") or "",
    facialMask = self:identity("facialMaskDirectives") or ""
  }

  -- Validate and set the actor's gender.
  local gender  = self:validateGender(self.actor.identity.gender)
  
  -- Validate and set the actor's species.
  local species = self:validateSpecies(self.actor.identity.species)

  local animationState = position.animationState or "idle"

  -- Set reference to actor's stored pregnancy.
  local pregnantConfig = self:storage("pregnant") or nil
  
  local role = self.actor.role
  
  local parts = {}
  
  parts.climax = "/artwork/humanoid/climax/climax-" .. animationState .. ".png:climax"
  
  local showPregnant = false
  
  -- Check pregnancy fetish is enabled/
  if Sexbound.API.getParameter("pregnant.enablePregnancyFetish") then
    showPregnant = true
  end
  
  if showPregnant and self:getPregnant():isPregnant() then
    parts.body = "/artwork/humanoid/" .. role .. "/" .. species  .. "/body_" .. gender .. "_pregnant.png:" .. animationState
  else
    parts.body = "/artwork/humanoid/" .. role .. "/" .. species  .. "/body_" .. gender .. ".png:" .. animationState
  end
  
  parts.head = "/artwork/humanoid/" .. role .. "/" .. species .. "/head_" .. gender .. ".png:normal" .. directives.body .. directives.hair
  
  parts.armFront = "/artwork/humanoid/" .. role .. "/" .. species .. "/arm_front.png:" .. animationState
  
  parts.armBack  = "/artwork/humanoid/" .. role .. "/" .. species .. "/arm_back.png:" .. animationState
  
  if self:identity("facialHairType") ~= "" then
    parts.facialHair = "/humanoid/" .. species .. "/" .. self:identity("facialHairFolder") .. "/" .. self:identity("facialHairType") .. ".png:normal" .. directives.facialHair
  else
    parts.facialHair = defaultPath
  end
  
  if self:identity("facialMaskType") ~= "" then
    parts.facialMask = "/humanoid/" .. species .. "/" .. self:identity("facialMaskFolder") .. "/" .. self:identity("facialMaskType") .. ".png:normal" .. directives.facialMask
  else
    parts.facialMask = defaultPath
  end
  
  if self:identity("hairType") ~= nil then
    parts.hair = "/humanoid/" .. species .. "/" .. self:identity("hairFolder") .. "/" .. self:identity("hairType") .. ".png:normal" .. directives.body .. directives.hair
  else
    parts.hair = defaultPath
  end
  
  animator.setGlobalTag(role .. "-gender", gender)
  animator.setGlobalTag(role .. "-species", species)
  
  animator.setGlobalTag("part-" .. role .. "-body", parts.body)
  animator.setGlobalTag("part-" .. role .. "-climax", parts.climax)
  animator.setGlobalTag("part-" .. role .. "-head", parts.head)
  animator.setGlobalTag("part-" .. role .. "-arm-front", parts.armFront)
  animator.setGlobalTag("part-" .. role .. "-arm-back", parts.armBack)
  animator.setGlobalTag("part-" .. role .. "-facial-hair", parts.facialHair)
  animator.setGlobalTag("part-" .. role .. "-facial-mask", parts.facialMask)
  animator.setGlobalTag("part-" .. role .. "-hair", parts.hair)
  
  animator.setGlobalTag(role .. "-bodyDirectives", directives.body)
  animator.setGlobalTag(role .. "-emoteDirectives", directives.emote)
  animator.setGlobalTag(role .. "-hairDirectives", directives.hair)
end

--- Resets the Actor's global animator tags.
-- @param[opt] actorNumber
function Sexbound.Core.Actor:resetGlobalAnimatorTags(actorNumber)
  actorNumber = actorNumber or self:actorNumber()
  
  local default = "/artwork/default.png:default"
  local role = "actor" .. actorNumber
  
  animator.setGlobalTag("part-" .. role .. "-arm-back", default)
  animator.setGlobalTag("part-" .. role .. "-arm-front", default)
  animator.setGlobalTag("part-" .. role .. "-body", default)
  animator.setGlobalTag("part-" .. role .. "-head", default)
  animator.setGlobalTag("part-" .. role .. "-hair", default)
  animator.setGlobalTag("part-" .. role .. "-facial-hair", default)
  animator.setGlobalTag("part-" .. role .. "-facial-mask", default)
  
  animator.setGlobalTag(role .. "-bodyDirectives", "")
  animator.setGlobalTag(role .. "-emoteDirectives", "")
  animator.setGlobalTag(role .. "-hairDirectives", "")
end

--- Resets all transformations for this Actor.
-- @param[opt] actorNumber
function Sexbound.Core.Actor:resetTransformations(actorNumber)
  actorNumber = actorNumber or self:actorNumber()

  for _,v in ipairs({"Body", "Head"}) do
    if animator.hasTransformationGroup("actor" .. actorNumber .. v) then
      animator.resetTransformationGroup("actor" .. actorNumber .. v)
    end
  end
end

--- Rotates a specified animator part.
-- @param actorNumber
-- @param partName
-- @param rotation
function Sexbound.Core.Actor:rotatePart(actorNumber, partName, rotation)
  if (animator.hasTransformationGroup("actor" .. actorNumber .. partName)) then
    animator.rotateTransformationGroup("actor" .. actorNumber .. partName, rotation)
  end
end

--- Setup new actor.
-- @param actor
-- @param storeActor 
function Sexbound.Core.Actor:setup(actor, storeActor)
  -- Store actor data.
  self.actor = util.mergeTable(self.actor, actor)
  
  -- Init timers for this actor.
  self.timer = { emote = 0, moan = 0, talk = 0 }
  
  -- Initialize hair identities.
  self.actor.identity.hairFolder = self:hairFolder()
  self.actor.identity.hairType = self:hairType()
  
  -- Initialize facial hair identities.
  self.actor.identity.facialHairFolder = self:facialHairFolder()
  self.actor.identity.facialHairType = self:facialHairType()
  
  -- Initialize facial mask identities.
  self.actor.identity.facialMaskFolder = self:facialMaskFolder()
  self.actor.identity.facialMaskType = self:facialMaskType()

  -- Permenantly store actor in this entity.
  if storeActor then storage.actor = self.actor end

  -- Use sex talk for NPCs
  if Sexbound.API.getParameter("sextalk.enabled") and self:entityType() == "npc" then
    self.sextalk = Sexbound.Core.SexTalk.new( self )
  end
  
  -- Initialize new module : Climax
  self.climax = Sexbound.Core.Climax.new(self)
  
  -- Initialize new module : Emote
  self.emote = Sexbound.Core.Emote.new(self)
  
  -- Initialize new module : Moan
  self.moan = Sexbound.Core.Moan.new(self)
  
  -- Initialize new module : Pregnant
  self.pregnant = Sexbound.Core.Pregnant.new(self)
end

--- Returns the actor's storage data or a specified parameter in the actor's storage.
-- @param name
function Sexbound.Core.Actor:storage(name)
  if name then return self.actor.storage[name] end
  
  return self.actor.storage
end

--- Merge specified config into this Actor instance's storage.
-- @param config
function Sexbound.Core.Actor:insertStorage(config)
  self.actor.storage = util.mergeTable(self.actor.storage, config or {})
  
  self:syncStorage()
end

--- Overwrite specified storage option name with specified config.
-- @param name
-- @param config
function Sexbound.Core.Actor:overwriteStorage(name, config)
  self.actor.storage[name] = config
  
  self:syncStorage()
end

--- Send message to update the Actor's storage.
function Sexbound.Core.Actor:syncStorage()
  Sexbound.API.Util.sendMessage(self:id(), "sexbound-sync-storage", self:storage())
end

--- Translates a specified animator part.
-- @param actorNumber
-- @param partName
-- @param rotation
function Sexbound.Core.Actor:translatePart(actorNumber, partName, offset)
  animator.resetTransformationGroup("actor" .. actorNumber .. partName)
  
  animator.translateTransformationGroup("actor" .. actorNumber .. partName, offset)
end

--- Processes gender value.
-- @param gender male, female, or something else (future)
function Sexbound.Core.Actor:validateGender(gender)
  local validatedGender = util.find(Sexbound.API.getParameter("supportedPlayerGenders"), function(v)
    if (gender == v) then return v end
  end)
  
  if not validatedGender then
    return Sexbound.API.getParameter("defaultPlayerGender") -- default is 'male'
  else return validatedGender end
end

--- Processes species value.
-- @param species name of species
function Sexbound.Core.Actor:validateSpecies(species)
  local validatedSpecies = util.find(Sexbound.API.getParameter("supportedPlayerSpecies"), function(v)
   if (species == v) then return v end
  end)
  
  if not validatedSpecies then
    return Sexbound.API.getParameter("defaultPlayerSpecies") -- default is 'human'
  else return validatedSpecies end
end
