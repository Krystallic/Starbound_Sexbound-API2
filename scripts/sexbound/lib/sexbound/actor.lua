--- Sexbound.Actor Class Module.
-- @classmod Sexbound.Actor
-- @author Loxodon
-- @license GNU General Public License v3.0
Sexbound.Actor = {}
Sexbound.Actor_mt = {__index = Sexbound.Actor}

require "/scripts/sexbound/lib/sexbound/actor/pluginmgr.lua"

--- Returns a reference to a new instance of this class.
-- @param parent
-- @param actorConfig
function Sexbound.Actor:new( parent, actorConfig )
  local self = setmetatable({
    _logPrefix = "ACTR",
    _parent = parent
  }, Sexbound.Actor_mt)
  
  Sexbound.Messenger.get("main"):addBroadcastRecipient( self )
  
  self._log = Sexbound.Log:new(self._logPrefix, self._parent:getConfig())
  
  -- Initialize the actor's config.
  self._config  = util.mergeTable({}, self._parent:getConfig().actor)

  -- Setup the actor.
  self:setup(actorConfig)

  -- Create new plugin manager
  self._pluginmgr = Sexbound.Actor.PluginMgr:new( self )
  
  return self
end

--- Processes received messages from the message queue.
-- @param message
function Sexbound.Actor:onMessage(message)
  -- nothing to process yet
end

--- Adds a new status to this actor's status list.
-- @param statusName
function Sexbound.Actor:addStatus(statusName)
  table.insert(self._config.statusList, statusName)
end

--- Returns wether or not this actor has a specified status in its status list.
-- @param statusName
function Sexbound.Actor:hasStatus(statusName)
  local statusList = self:getStatusList()

  for _,status in ipairs(statusList) do
    if (status == statusName) then
      return true
    end
  end
  
  return false
end

--- Returns a specified status name if it is found.
-- @param statusName
function Sexbound.Actor:findStatus(statusName)
  local statusList = self:getStatusList()

  for _,status in ipairs(statusList) do
    if (status == statusName) then
      return statusName
    end
  end
end

--- Removes a specified status from this actor's status list.
-- @param statusName
function Sexbound.Actor:removeStatus(statusName)
  local statusList = self:getStatusList()

  for _,status in ipairs(statusList) do
    if (status == statusName) then
      table.remove(self._config.statusList, index)
      return true
    end
  end
  
  return false
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
  if self:getConfig().storage then
    self:getConfig().storage[name] = value
  end
  
  self:syncStorage()
end

--- Resets a specified actor.
function Sexbound.Actor:reset(stateName)
  local defaultPath = "/artwork/humanoid/default.png:default"
  
  local position = self:getParent():getPositions():getCurrentPosition()
  local positionConfig = position:getConfig()
  
  local stateMachine = self:getParent():getStateMachine()
  
  stateName = stateName or stateMachine:stateDesc()
  
  if not stateName or stateName == "" then return end 
  
  local actorNumber = self:getActorNumber()
  local role = self:getRole()
  
  local animationState = position:getAnimationState(stateName)
  
  local frameName = animationState.frameName
  
  self:resetGlobalAnimatorTags()
  
  self:resetTransformations()
  
  local rotateHead = animationState.rotateHead[actorNumber]
  self:rotatePart("Head", rotateHead)
  
  local rotateBody = animationState.rotateBody[actorNumber]
  self:rotatePart("Body", rotateBody)

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
    body       = self:getIdentity("bodyDirectives") or "",
    head       = self:getIdentity("bodyDirectives") or "",
    emote      = self:getIdentity("emoteDirectives") or "",
    hair       = self:getIdentity("hairDirectives") or "",
    facialHair = self:getIdentity("facialHairDirectives") or "",
    facialMask = self:getIdentity("facialMaskDirectives") or ""
  }
  
  directives.body = directives.body .. directives.hair
  directives.head = directives.head .. directives.hair
  
  local flipHead = nil
  
  -- Try to get specific flip head value for the animator state
  if animationState.flipHead and animationState.flipHead[actorNumber] then
    flipHead = animationState.flipHead[actorNumber]
  end
  
  -- Else try to get global flip head value for the position
  if flipHead == nil and positionConfig.flipHead and positionConfig.flipHead[actorNumber] then
    flipHead = positionConfig.flipHead[actorNumber]
  end
  
  -- Apply flip to head directives
  if flipHead == true then
    util.each({"head", "emote", "hair", "facialHair", "facialMask"}, function(index, directive)
      directives[directive] = directives[directive] .. "?flipx"
    end)
  end
  
  local flipBody = nil
  
  -- Try to get specific flip body value for the animator state
  if animationState.flipBody and animationState.flipBody[actorNumber] then
    flipBody = animationState.flipBody[actorNumber]
  end
  
  -- Else try to get global flip body value for the position
  if flipBody == nil and positionConfig.flipBody and positionConfig.flipBody[actorNumber] then
    flipBody = positionConfig.flipBody[actorNumber]
  end
  
  -- Apply flip to body directives
  if flipBody == true then
    util.each({"body"}, function(index, directive)
      directives[directive] = directives[directive] .. "?flipx"
    end)
  end
  
  -- Validate and set the actor's gender.
  local gender  = self:validateGender(self:getGender())
  
  -- Validate and set the actor's species.
  local species = self:validateSpecies(self:getSpecies())
  
  local parts = {}
  
  parts.body = "/artwork/humanoid/" .. role .. "/" .. species  .. "/body_" .. gender .. ".png:" .. frameName
  
  local plugins = self:getConfig().plugins
  
  local pregnant = self:getPlugins("pregnant")
  
  if pregnant then
    local pregnantConfig = pregnant:getConfig()
    local canShow = pregnantConfig.enablePregnancyFetish
    
    if canShow and pregnant:isPregnant() then
      parts.body = "/artwork/humanoid/" .. role .. "/" .. species  .. "/body_" .. gender .. "_pregnant.png:" .. frameName
    end
  end
  
  parts.head     = "/artwork/humanoid/" .. role .. "/" .. species .. "/head_" .. gender .. ".png:normal" .. directives.head
  
  parts.armFront = "/artwork/humanoid/" .. role .. "/" .. species .. "/arm_front.png:" .. frameName
  
  parts.armBack  = "/artwork/humanoid/" .. role .. "/" .. species .. "/arm_back.png:"  .. frameName
  
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
    parts.hair = "/humanoid/" .. species .. "/" .. self:getIdentity("hairFolder") .. "/" .. self:getIdentity("hairType") .. ".png:normal" .. directives.head
  else
    parts.hair = defaultPath
  end
  
  animator.setGlobalTag(role .. "-gender", gender)
  animator.setGlobalTag(role .. "-species", species)
  
  animator.setGlobalTag("part-" .. role .. "-body", parts.body)
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
  
  --animator.setGlobalTag(role .. "-bodyDirectives", "")
  --animator.setGlobalTag(role .. "-emoteDirectives", "")
  --animator.setGlobalTag(role .. "-hairDirectives", "")
end

--- Rotates a specified animator part.
-- @param part
-- @param angle
function Sexbound.Actor:rotatePart(part, angle)
  local role = self:getRole()

  local group = role .. part

  if animator.hasTransformationGroup(group) then
    local radians = util.toRadians(angle)
  
    animator.rotateTransformationGroup(group, radians)
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

--- Use the Actor's entityId to Send message to update its storage.
function Sexbound.Actor:syncStorage()
  local entityId = self:getEntityId()
  local exists = world.entityExists(entityId)
  local storage = self:getStorage()
  
  if exists and type(storage) == "table" then
    Sexbound.Util.sendMessage(entityId, "sexbound-sync-storage", storage)
  end
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
  self:resetGlobalAnimatorTags()
  
  self:resetTransformations()
  
  util.each(self:getPlugins(), function(index, plugin)
    plugin:uninit()
  end)
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

-- Getters / Setters

--- Returns a reference to this actor's status list as a table.
function Sexbound.Actor:getStatusList()
  return self._config.statusList
end

--- Sets the role for this actor with the specifed number.
-- @param number
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

--- Returns the actor number for this Actor instance.
function Sexbound.Actor:getActorNumber()
  return self._actorNumber
end

--- Sets the actor number to the specified value.
-- @param value
function Sexbound.Actor:setActorNumber(value)
  self._actorNumber = value
end

--- Returns the running configuration for this Actor instance.
function Sexbound.Actor:getConfig()
  return self._config
end

--- Returns the log prefix for this Actor instance.
function Sexbound.Actor:getLogPrefix()
  return self._logPrefix
end

--- Returns a reference to the log for this Actor instance.
function Sexbound.Actor:getLog()
  return self._log
end

--- Returns the name of this Actor instance.
function Sexbound.Actor:getName()
  return self:getConfig().identity.name
end

--- Returns the parent class of this Actor instance.
function Sexbound.Actor:getParent()
  return self._parent
end

--- Returns the plugin manager of this Actor instance.
function Sexbound.Actor:getPluginMgr()
  return self._pluginmgr
end

--- Returns a reference to this Actor instance's plugins as a table.
-- @param pluginName
function Sexbound.Actor:getPlugins(pluginName)
  if pluginName then return self:getPluginMgr():getPlugins(pluginName) end

  return self:getPluginMgr():getPlugins()
end

--- Returns the entity type of this Actor instance.
function Sexbound.Actor:getEntityType()
  return self:getConfig().entityType
end

--- Returns the validated facial hair folder name for this Actor instance.
function Sexbound.Actor:getFacialHairFolder()
  return self:getIdentity("facialHairFolder") or self:getIdentity("facialHairGroup") or ""
end

--- Returns the validated facial hair type for this Actor instance.
function Sexbound.Actor:getFacialHairType()
  return self:getIdentity("facialHairType") or "1"
end

--- Returns the validated facial mask folder name for this Actor instance.
function Sexbound.Actor:getFacialMaskFolder()
  return self:getIdentity("facialMaskFolder") or self:getIdentity("facialMaskGroup") or ""
end

--- Returns the validated facial mask type for this Actor instance.
function Sexbound.Actor:getFacialMaskType()
  return self:getIdentity("facialMaskType") or "1"
end

--- Returns the gender of this actor instance.
function Sexbound.Actor:getGender()
  return self:getIdentity().gender
end

--- Returns the validated hair folder of this actor instance.
function Sexbound.Actor:getHairFolder()
  return self:getIdentity().hairFolder or self:getIdentity("hairGroup") or "hair"
end

--- Returns the validated hair type of this actor instance.
function Sexbound.Actor:getHairType()
  return self:getIdentity("hairType") or "1"
end

--- Returns the id of this actor instance.
function Sexbound.Actor:getEntityId()
  return self:getConfig().id
end

--- Returns the role of this actor instance.
function Sexbound.Actor:getRole()
  return self._role
end

--- Executes the specifed callback function for each actor plugin.
-- @param callback
function Sexbound.Actor:forEachPlugin(callback)
  util.each(self:getPlugins(), function(index, plugin)
    callback(plugin)
  end)
end

--- Calls onEnterClimaxState for every loaded plugin.
function Sexbound.Actor:onEnterClimaxState()
  self:forEachPlugin(function(plugin)
    plugin:onEnterClimaxState()
  end)
end

--- Calls onEnterExitState for every loaded plugin.
function Sexbound.Actor:onEnterExitState()
  self:forEachPlugin(function(plugin)
    plugin:onEnterExitState()
  end)
end

--- Calls onEnterIdleState for every loaded plugin.
function Sexbound.Actor:onEnterIdleState()
  self:forEachPlugin(function(plugin)
    plugin:onEnterIdleState()
  end)
end

--- Calls onEnterSexState for every loaded plugin.
function Sexbound.Actor:onEnterSexState()
  self:forEachPlugin(function(plugin)
    plugin:onEnterSexState()
  end)
end

--- Calls onExitClimaxState for every loaded plugin.
function Sexbound.Actor:onExitClimaxState()
  self:forEachPlugin(function(plugin)
    plugin:onExitClimaxState()
  end)
end

--- Calls onExitExitState for every loaded plugin.
function Sexbound.Actor:onExitExitState()
  self:forEachPlugin(function(plugin)
    plugin:onExitExitState()
  end)
end

--- Calls onExitIdleState for every loaded plugin.
function Sexbound.Actor:onExitIdleState()
  self:forEachPlugin(function(plugin)
    plugin:onExitIdleState()
  end)
end

--- Calls onExitSexState for every loaded plugin.
function Sexbound.Actor:onExitSexState()
  self:forEachPlugin(function(plugin)
    plugin:onExitSexState()
  end)
end

--- Calls onUpdateExitState for every loaded plugin.
-- @param dt
function Sexbound.Actor:onUpdateExitState(dt)
  self:forEachPlugin(function(plugin)
    plugin:onUpdateExitState(dt)
  end)
end

--- Calls onUpdateClimaxState for every loaded plugin.
-- @param dt
function Sexbound.Actor:onUpdateClimaxState(dt)
  self:forEachPlugin(function(plugin)
    plugin:onUpdateClimaxState(dt)
  end)
end

--- Calls onUpdateIdleState for every loaded plugin.
-- @param dt
function Sexbound.Actor:onUpdateIdleState(dt)
  self:forEachPlugin(function(plugin)
    plugin:onUpdateIdleState(dt)
  end)
end

--- Calls onUpdateSexState for every loaded plugin.
-- @param dt
function Sexbound.Actor:onUpdateSexState(dt)
  self:forEachPlugin(function(plugin)
    plugin:onUpdateSexState(dt)
  end)
end