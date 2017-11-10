Sexbound.Actor = {}
Sexbound.Actor.__index = Sexbound.Actor

function Sexbound.Actor.new(...)
  local self = setmetatable({}, Sexbound.Actor)
  self:init(...)
  return self
end

--- Initialize this instance.
-- @param actor
-- @param storeActor
function Sexbound.Actor:init(actor, storeActor)
  -- Create new log utility.
  self.log = Sexbound.Log.new({
    moduleName = "Actor | ID: " .. actor.id
  })

  self:setup(actor, storeActor)
end

--- Uninitializes this instance.
-- @param actorNumber
function Sexbound.Actor:uninit(actorNumber)
  self:resetGlobalAnimatorTags(actorNumber)
  
  self:resetTransformations(actorNumber)
end

--- Returns the actor's id.
function Sexbound.Actor:id()
  return self.actor.id
end

--- Returns the actor's identity data or a specified parameter in the actor's identity.
-- @param name
function Sexbound.Actor:identity(name)
  if name then return self.actor.identity[name] end

  return self.actor.identity
end

--- Returns the actor's storage data or a specified parameter in the actor's storage.
-- @param name
function Sexbound.Actor:storage(name)
  if name then return self.actor.storage[name] end
  
  return self.actor.storage
end

--- Returns the actor's type.
function Sexbound.Actor:entityType()
  return self.actor.entityType
end

--- Returns all stored data.
function Sexbound.Actor:getData()
  return self.actor
end

function Sexbound.Actor:applyTransformations(actorNumber, position)
  self.log:info(position)
  
  for i,partName in ipairs({"Body", "Climax", "Head"}) do
    if position["offset" .. partName] ~= nil then
      self:translateParts(actorNumber, partName, position["offset" .. partName][actorNumber])
    end
      
    if position["rotate" .. partName] ~= nil then
      self:rotateParts(actorNumber, partName, position["rotate" .. partName][actorNumber])
    end
      
    if position["flip" .. partName] ~= nil and position["flip" .. partName][actorNumber] == true then
      self:flipParts(actorNumber, partName)
    end
  end
end

function Sexbound.Actor:translateParts(actorNumber, partName, offset)
  local partsList = {}
  table.insert(partsList, 1, partName)
  
  if (partName == "Body") then partsList = {"ArmBack", "ArmFront", "Body"} end
  
  if (partName == "Head") then partsList = {"FacialHair", "FacialMask", "Emote", "Hair", "Head"} end
  
  for _,partName in ipairs(partsList) do
    if (animator.hasTransformationGroup("actor" .. actorNumber .. partName)) then
      self:translatePart(actorNumber, partName, offset)
    end
  end
end

function Sexbound.Actor:translatePart(actorNumber, partName, offset)
  animator.resetTransformationGroup("actor" .. actorNumber .. partName)
  
  animator.translateTransformationGroup("actor" .. actorNumber .. partName, offset)
end

function Sexbound.Actor:flipParts(actorNumber, partName)
  local partsList = {}
  table.insert(partsList, 1, partName)
  
  if (partName == "Body") then partsList = {"ArmBack", "ArmFront", "Body"} end
  
  if (partName == "Head") then partsList = {"FacialHair", "FacialMask", "Emote", "Hair", "Head"} end
  
  util.each(partsList, function(k, v)
    if (animator.hasTransformationGroup("actor" .. actorNumber .. v)) then
      self:flipPart(actorNumber, v)
    end
  end)
end

function Sexbound.Actor:rotateParts(actorNumber, partName, rotation)
  local partsList = {}
  table.insert(partsList, 1, partName)
  
  if (partName == "Body") then partsList = {"ArmBack", "ArmFront", "Body"} end
  
  if (partName == "Head") then partsList = {"FacialHair", "FacialMask", "Emote", "Hair", "Head"} end
  
  util.each(partsList, function(k, v)
    if (animator.hasTransformationGroup("actor" .. actorNumber .. v)) then
      self:rotatePart(actorNumber, v, rotation)
    end
  end)
end

function Sexbound.Actor:rotatePart(actorNumber, partName, rotation)
  if (animator.hasTransformationGroup("actor" .. actorNumber .. partName)) then
    animator.rotateTransformationGroup("actor" .. actorNumber .. partName, rotation)
  end
end

function Sexbound.Actor:flipPart(actorNumber, partName)
  if (animator.hasTransformationGroup("actor" .. actorNumber .. partName)) then
    animator.scaleTransformationGroup("actor" .. actorNumber .. partName, {-1, 1}, {0, 0})
  end
end

--- Resets an specified actor.
-- @param actorNumber
-- @param animationName
function Sexbound.Actor:reset(actorNumber, position)
  local defaultPath = "/artwork/humanoid/default.png:default"
  
  self:resetGlobalAnimatorTags(actorNumber)
  
  self:resetTransformations(actorNumber)
  
  self:applyTransformations(actorNumber, position)
  
  -- Set the directives.
  local directives = {
    body = self:identity("bodyDirectives") or "",
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
  
  -- Set the actor's role.
  local role = "actor" .. actorNumber

  -- Set moan based on actor 2 gender
  --if actor.data.count == 2 and actorNumber == 2 then 
    --sex.setMoanGender(gender)
  --end
  
  local parts = {}
  
  parts.climax = "/artwork/humanoid/climax/climax-" .. animationState .. ".png:climax"
  
  --if emote.data.list[actorNumber] then
    --parts.emote = "/humanoid/" .. species .. "/emote.png:" .. emote.data.list[actorNumber]
  --else
    --parts.emote = defaultPath
  --end
  
  local showPregnant = false
  
  -- Show pregnant player?
  if self:entityType() == "player" and Sexbound.Main.getParameter("pregnant.showPregnantPlayer") then
    showPregnant = true
  end
  
  -- Show pregnant npc?
  if self:entityType() == "npc" and Sexbound.Main.getParameter("pregnant.showPregnantOther") then
    showPregnant = true
  end
  
  if showPregnant and pregnantConfig and pregnantConfig.isPregnant then
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
  
  self.log:info(parts)
  
  animator.setGlobalTag("part-" .. role .. "-body",        parts.body)
  animator.setGlobalTag("part-" .. role .. "-climax",      parts.climax)
  --animator.setGlobalTag("part-" .. role .. "-emote",       parts.emote)
  animator.setGlobalTag("part-" .. role .. "-head",        parts.head)
  animator.setGlobalTag("part-" .. role .. "-arm-front",   parts.armFront)
  animator.setGlobalTag("part-" .. role .. "-arm-back",    parts.armBack)
  animator.setGlobalTag("part-" .. role .. "-facial-hair", parts.facialHair)
  animator.setGlobalTag("part-" .. role .. "-facial-mask", parts.facialMask)
  animator.setGlobalTag("part-" .. role .. "-hair",        parts.hair)
  
  animator.setGlobalTag(role .. "-bodyDirectives",   directives.body)
  animator.setGlobalTag(role .. "-hairDirectives",   directives.hair)
end

function Sexbound.Actor:resetGlobalAnimatorTags(actorNumber)
  local default = "/artwork/default.png:default"
  local role = "actor" .. actorNumber
  
  animator.setGlobalTag("part-" .. role .. "-arm-back", default)
  animator.setGlobalTag("part-" .. role .. "-arm-front", default)
  animator.setGlobalTag("part-" .. role .. "-body", default)
  animator.setGlobalTag("part-" .. role .. "-emote", default)
  animator.setGlobalTag("part-" .. role .. "-head", default)
  animator.setGlobalTag("part-" .. role .. "-hair", default)
  animator.setGlobalTag("part-" .. role .. "-facial-hair", default)
  animator.setGlobalTag("part-" .. role .. "-facial-mask", default)
end

function Sexbound.Actor:resetTransformations(actorNumber)
  for _,v in ipairs({"ArmBack", "ArmFront", "Body", "Climax", "Emote", "FacialHair", "FacialMask", "Hair", "Head"}) do
    if animator.hasTransformationGroup("actor" .. actorNumber .. v) then
      animator.resetTransformationGroup("actor" .. actorNumber .. v)
    end
  end
end

--- Setup new actor.
-- @param actor
-- @param storeActor 
function Sexbound.Actor:setup(actor, storeActor)
  -- Store actor data.
  self.actor = actor

  -- Ensure required identity parameters have a value.
  self.actor.identity.hairFolder       = self:identity("hairFolder")       or self:identity("hairGroup")
  self.actor.identity.facialHairFolder = self:identity("facialHairFolder") or self:identity("facialHairGroup")
  self.actor.identity.facialMaskFolder = self:identity("facialMaskFolder") or self:identity("facialMaskGroup")
  self.actor.identity.hairType         = self:identity("hairType")         or "1"
  self.actor.identity.facialHairType   = self:identity("facialHairType")   or "1"
  self.actor.identity.facialMaskType   = self:identity("facialMaskType")   or "1"
  
  -- Permenantly store actor in this entity.
  if storeActor then storage.actor = self.actor end
end

--- Processes gender value.
-- @param gender male, female, or something else (future)
function Sexbound.Actor:validateGender(gender)
  local validatedGender = util.find(Sexbound.Main.getParameter("supportedPlayerGenders"), function(v)
    if (gender == v) then return v end
  end)
  
  if not validatedGender then
    return Sexbound.Main.getParameter("defaultPlayerGender") -- default is 'male'
  else return validatedGender end
end

--- Processes species value.
-- @param species name of species
function Sexbound.Actor:validateSpecies(species)
  local validatedSpecies = util.find(Sexbound.Main.getParameter("supportedPlayerSpecies"), function(v)
   if (species == v) then return v end
  end)
  
  if not validatedSpecies then
    return Sexbound.Main.getParameter("defaultPlayerSpecies") -- default is 'human'
  else return validatedSpecies end
end