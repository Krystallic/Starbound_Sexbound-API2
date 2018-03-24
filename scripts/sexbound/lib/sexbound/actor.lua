--- Sexbound.Actor Class Module.
-- @classmod Sexbound.Actor
-- @author Loxodon
-- @license GNU General Public License v3.0
Sexbound.Actor = {}
Sexbound.Actor_mt = {__index = Sexbound.Actor}

require "/scripts/sexbound/lib/sexbound/actor/pluginmgr.lua"

function Sexbound.Actor:new( parent, actor )
  local self = setmetatable({
    _logPrefix = "ACTR",
    _parent = parent
  }, Sexbound.Actor_mt)
  
  Sexbound.Messenger.get("main"):addBroadcastRecipient( self )
  
  self._log = Sexbound.Log:new(self._logPrefix, self._parent:getConfig())
  
  -- Initialize the actor's config.
  self._config  = util.mergeTable({}, self._parent:getConfig().actor)

  -- Setup the actor.
  self:setup(actor)

  self._pluginmgr = Sexbound.Actor.PluginMgr:new( self )
  
  return self
end

-- Events

function Sexbound.Actor:onMessage(message)

end

function Sexbound.Actor:onEnterClimaxState()
  util.each(self:getPlugins(), function(index, plugin)
    plugin:onEnterClimaxState()
  end)
end

function Sexbound.Actor:onEnterExitState()
  util.each(self:getPlugins(), function(index, plugin)
    plugin:onEnterExitState()
  end)
end

function Sexbound.Actor:onEnterIdleState()
  util.each(self:getPlugins(), function(index, plugin)
    plugin:onEnterIdleState()
  end)
end

function Sexbound.Actor:onEnterSexState()
  util.each(self:getPlugins(), function(index, plugin)
    plugin:onEnterSexState()
  end)
end

function Sexbound.Actor:onExitClimaxState()
  util.each(self:getPlugins(), function(index, plugin)
    plugin:onExitClimaxState()
  end)
end

function Sexbound.Actor:onExitExitState()
  util.each(self:getPlugins(), function(index, plugin)
    plugin:onExitExitState()
  end)
end

function Sexbound.Actor:onExitIdleState()
  util.each(self:getPlugins(), function(index, plugin)
    plugin:onExitIdleState()
  end)
end

function Sexbound.Actor:onExitSexState()
  util.each(self:getPlugins(), function(index, plugin)
    plugin:onExitSexState()
  end)
end

function Sexbound.Actor:onUpdateExitState(dt)
  util.each(self:getPlugins(), function(index, plugin)
    plugin:onUpdateExitState(dt)
  end)
end

function Sexbound.Actor:onUpdateClimaxState(dt)
  util.each(self:getPlugins(), function(index, plugin)
    plugin:onUpdateClimaxState(dt)
  end)
end

function Sexbound.Actor:onUpdateIdleState(dt)
  util.each(self:getPlugins(), function(index, plugin)
    plugin:onUpdateIdleState(dt)
  end)
end

function Sexbound.Actor:onUpdateSexState(dt)
  util.each(self:getPlugins(), function(index, plugin)
    plugin:onUpdateSexState(dt)
  end)
end

--- Returns this Actor's current number.
function Sexbound.Actor:getActorNumber()
  return self._actorNumber
end

function Sexbound.Actor:setActorNumber(value)
  self._actorNumber = value
end

function Sexbound.Actor:getConfig()
  return self._config
end

function Sexbound.Actor:getLogPrefix()
  return self._logPrefix
end

function Sexbound.Actor:getLog()
  return self._log
end

function Sexbound.Actor:getParent()
  return self._parent
end

function Sexbound.Actor:getName()
  return self._config.identity.name
end

function Sexbound.Actor:getPluginMgr()
  return self._pluginmgr
end

function Sexbound.Actor:getPlugins(name)
  if name then return self:getPluginMgr():getPlugins(name) end

  return self:getPluginMgr():getPlugins()
end

--- Returns this Actor's entity type.
function Sexbound.Actor:getEntityType()
  return self:getConfig().entityType
end

--- Returns a validated facial hair folder name.
function Sexbound.Actor:getFacialHairFolder()
  return self:getIdentity("facialHairFolder") or self:getIdentity("facialHairGroup") or ""
end

--- Returns a validated facial hair type.
function Sexbound.Actor:getFacialHairType()
  return self:getIdentity("facialHairType") or "1"
end

--- Returns a validated facial mask folder name.
function Sexbound.Actor:getFacialMaskFolder()
  return self:getIdentity("facialMaskFolder") or self:getIdentity("facialMaskGroup") or ""
end

--- Returns a validated facial mask type.
function Sexbound.Actor:getFacialMaskType()
  return self:getIdentity("facialMaskType") or "1"
end

--- Returns this Actor's gender.
function Sexbound.Actor:getGender()
  return self:getIdentity().gender
end

--- Returns a validated hair folder name.
function Sexbound.Actor:getHairFolder()
  return self:getIdentity().hairFolder or self:getIdentity("hairGroup") or "hair"
end

--- Returns a validated hair type.
function Sexbound.Actor:getHairType()
  return self:getIdentity("hairType") or "1"
end

--- Returns this Actor's id.
function Sexbound.Actor:getEntityId()
  return self:getConfig().id
end

--- Returns this Actor's current role.
function Sexbound.Actor:getRole()
  return self._role
end

function Sexbound.Actor:addStatus(name)
  table.insert(self._config.statusList, name)
end

function Sexbound.Actor:hasStatus(name)
  for _,status in ipairs(self._config.statusList) do
    if (status == name) then
      return true
    end
  end
  
  return false
end

function Sexbound.Actor:findStatus(name)
  for _,status in ipairs(self._config.statusList) do
    if (status == name) then
      return name
    end
  end
end

function Sexbound.Actor:removeStatus(name)
  util.each(self._config.statusList, function(index, status)
    if (status == name) then
      table.remove(self._config.statusList, index)
    end
  end)
end

function Sexbound.Actor:getStatusList()
  return self._config.statusList
end

function Sexbound.Actor:setRole(number)
  self._role = "actor" .. number
end

--- Returns a reference to this Actor identifiers.
-- @param[opt] param
function Sexbound.Actor:getIdentity(param)
  if param then return self:getConfig().identity[param] end

  return self:getConfig().identity
end

--- Returns the species value.
function Sexbound.Actor:getSpecies()
  return self:getIdentity().species
end

--- Returns the actor's storage data or a specified parameter in the actor's storage.
-- @param name
function Sexbound.Actor:getStorage(name)
  if not self:getConfig().storage then return nil end

  if name then return self:getConfig().storage[name] end
  
  return self:getConfig().storage
end

--- Applies transformations to animator parts.
function Sexbound.Actor:applyTransformations()
  local actorNumber = self:getActorNumber()

  local position = self:getParent():getPositions():getCurrentPosition()
  local positionConfig = position:getConfig()

  for i,part in ipairs({"Body", "Climax", "Head"}) do
    if positionConfig["offset" .. part] ~= nil then
      self:translateParts(part, positionConfig["offset" .. part][actorNumber])
    end
      
    if positionConfig["rotate" .. part] ~= nil then
      self:rotatePart(part, positionConfig["rotate" .. part][actorNumber])
    end
      
    if positionConfig["flip" .. part] ~= nil and positionConfig["flip" .. part][actorNumber] == true then
      self:flipPart(part)
    end
  end
end

--- Flips a specified part in the animator.
-- @param part
function Sexbound.Actor:flipPart(part)
  local role = self:getRole()
  local group = role .. part
  
  if (animator.hasTransformationGroup(group)) then
    animator.scaleTransformationGroup(group, {-1, 1}, {0, 0})
  end
end

--- Merge specified options into this Actor instance's storage.
-- @param options
function Sexbound.Actor:insertStorage(options)
  self._config.storage = util.mergeTable(self._config.storage, options or {})
  
  self:syncStorage()
end

--- Overwrite specified storage option name with specified config.
-- @param name
-- @param value
function Sexbound.Actor:overwriteStorage(name, value)
  self._config.storage[name] = value
  
  self:syncStorage()
end

--- Resets a specified actor.
function Sexbound.Actor:reset()
  local defaultPath = "/artwork/humanoid/default.png:default"
  
  local position = self:getParent():getPositions():getCurrentPosition()
  local positionConfig = position:getConfig()
  
  self:resetGlobalAnimatorTags()
  
  self:resetTransformations()
  
  self:applyTransformations()
    
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
    body = self:getIdentity("bodyDirectives") or "",
    emote = self:getIdentity("emoteDirectives") or "",
    hair = self:getIdentity("hairDirectives") or "",
    facialHair = self:getIdentity("facialHairDirectives") or "",
    facialMask = self:getIdentity("facialMaskDirectives") or ""
  }

  -- Validate and set the actor's gender.
  local gender  = self:validateGender(self:getGender())
  
  -- Validate and set the actor's species.
  local species = self:validateSpecies(self:getSpecies())

  local animationState = positionConfig.animationState or "idle"

  local role = self:getRole()
  
  local parts = {}
  
  parts.climax = "/artwork/humanoid/climax/climax-" .. animationState .. ".png:climax"
  
  parts.body = "/artwork/humanoid/" .. role .. "/" .. species  .. "/body_" .. gender .. ".png:" .. animationState
  
  local plugins = self:getConfig().plugins
  
  local pregnant = self:getPlugins("pregnant")
  
  if pregnant then
    local pregnantConfig = pregnant:getConfig()
    local canShow = pregnantConfig.enablePregnancyFetish
    
    if canShow and pregnant:isPregnant() then
      parts.body = "/artwork/humanoid/" .. role .. "/" .. species  .. "/body_" .. gender .. "_pregnant.png:" .. animationState
    end
  end
  
  parts.head = "/artwork/humanoid/" .. role .. "/" .. species .. "/head_" .. gender .. ".png:normal" .. directives.body .. directives.hair
  
  parts.armFront = "/artwork/humanoid/" .. role .. "/" .. species .. "/arm_front.png:" .. animationState
  
  parts.armBack  = "/artwork/humanoid/" .. role .. "/" .. species .. "/arm_back.png:" .. animationState
  
  if self:getIdentity("facialHairType") ~= "" then
    parts.facialHair = "/humanoid/" .. species .. "/" .. self:getIdentity("facialHairFolder") .. "/" .. self:getIdentity("facialHairType") .. ".png:normal" .. directives.facialHair
  else
    parts.facialHair = defaultPath
  end
  
  if self:getIdentity("facialMaskType") ~= "" then
    parts.facialMask = "/humanoid/" .. species .. "/" .. self:getIdentity("facialMaskFolder") .. "/" .. self:getIdentity("facialMaskType") .. ".png:normal" .. directives.facialMask
  else
    parts.facialMask = defaultPath
  end
  
  if self:getIdentity("hairType") ~= nil then
    parts.hair = "/humanoid/" .. species .. "/" .. self:getIdentity("hairFolder") .. "/" .. self:getIdentity("hairType") .. ".png:normal" .. directives.body .. directives.hair
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

--- Resets all transformations for this Actor.
function Sexbound.Actor:resetTransformations()
  local role = self:getRole()

  for _,part in ipairs({"Body", "Head"}) do
    local group = role .. part
    
    if animator.hasTransformationGroup(group) then
      animator.resetTransformationGroup(group)
    end
  end
end

--- Resets the Actor's global animator tags.
function Sexbound.Actor:resetGlobalAnimatorTags()
  local default = "/artwork/default.png:default"
  local role = self:getRole()
  
  animator.setGlobalTag("part-" .. role .. "-arm-back", default)
  animator.setGlobalTag("part-" .. role .. "-arm-front", default)
  animator.setGlobalTag("part-" .. role .. "-body", default)
  animator.setGlobalTag("part-" .. role .. "-climax", default)
  animator.setGlobalTag("part-" .. role .. "-emote", default)
  animator.setGlobalTag("part-" .. role .. "-head", default)
  animator.setGlobalTag("part-" .. role .. "-hair", default)
  animator.setGlobalTag("part-" .. role .. "-facial-hair", default)
  animator.setGlobalTag("part-" .. role .. "-facial-mask", default)
  
  animator.setGlobalTag(role .. "-bodyDirectives", "")
  animator.setGlobalTag(role .. "-emoteDirectives", "")
  animator.setGlobalTag(role .. "-hairDirectives", "")
end

--- Rotates a specified animator part.
-- @param part
-- @param rotation
function Sexbound.Actor:rotatePart(part, rotation)
  local role = self:getRole()

  local group = role .. part
  
  if (animator.hasTransformationGroup(group)) then
    animator.rotateTransformationGroup(group, rotation)
  end
end

--- Setup new actor.
-- @param actor
function Sexbound.Actor:setup(actor)
  -- Store actor data.
  self._config = util.mergeTable(self._config, actor)
  
  -- Initialize hair identities.
  self._config.identity.hairFolder = self:getHairFolder()
  self._config.identity.hairType   = self:getHairType()
  
  -- Initialize facial hair identities.
  self._config.identity.facialHairFolder = self:getFacialHairFolder()
  self._config.identity.facialHairType   = self:getFacialHairType()
  
  -- Initialize facial mask identities.
  self._config.identity.facialMaskFolder = self:getFacialMaskFolder()
  self._config.identity.facialMaskType   = self:getFacialMaskType()
  
  self._config.statusList = {"default"}
  
  self:setActorNumber(self:getParent():getActorCount())
end

--- Send message to update the Actor's storage.
function Sexbound.Actor:syncStorage()
  Sexbound.Util.sendMessage(self:getEntityId(), "sexbound-sync-storage", self:getStorage())
end

--- Translates a specified animator part.
-- @param part
-- @param offset
function Sexbound.Actor:translatePart(part, offset)
  local role = self:getRole()
  local group = role .. part
  
  if (animator.hasTransformationGroup(group)) then
    animator.resetTransformationGroup(group)
  
    animator.translateTransformationGroup(group, offset)
  end
end

--- Uninitializes this instance.
function Sexbound.Actor:uninit()
  for _,plugin in ipairs(self:getPlugins()) do
    if type(plugin.uninit) == "function" then
      plugin:uninit()
    end
  end
end

--- Processes gender value.
-- @param gender male, female, or something else (future)
function Sexbound.Actor:validateGender(gender)
  local validatedGender = util.find(self:getParent():getConfig().sex.supportedPlayerGenders, function(v)
    if (gender == v) then return v end
  end)
  
  if not validatedGender then
    return self:getParent():getConfig().sex.defaultPlayerGender -- default is 'male'
  else return validatedGender end
end

--- Processes species value.
-- @param species name of species
function Sexbound.Actor:validateSpecies(species)
  local validatedSpecies = util.find(self:getParent():getConfig().sex.supportedPlayerSpecies, function (v)
   if (species == v) then return v end
  end)
  
  if not validatedSpecies then
    return self:getParent():getConfig().sex.defaultPlayerSpecies -- default is 'human'
  else return validatedSpecies end
end