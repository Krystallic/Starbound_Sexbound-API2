--- Sexbound.Core.SexTalk Class Module.
-- @classmod Sexbound.Core.SexTalk
Sexbound.Core.SexTalk = {}
Sexbound.Core.SexTalk.__index = Sexbound.Core.SexTalk

--- Instantiates a new instance of SexTalk.
-- @param parent
function Sexbound.Core.SexTalk.new(parent)
  local self = setmetatable({}, Sexbound.Core.SexTalk)

  self.parent = parent
  
  -- Initialize log
  self.log = Sexbound.Core.Log.new({
    moduleName = "SexTalk"
  })
  
  -- Initialize sextalk data
  self.sextalk = {
    config = util.mergeTable({}, Sexbound.API.getParameter("sextalk")),
    dialogConfig = root.assetJson(Sexbound.API.getParameter("sextalk.config")),
    history = {}
  }
  
  self.sextalk.cooldown = self:refreshCooldown()
  
  self.timer = {
    sextalk = 0
  }
  
  return self
end

--- Updates this instance.
-- @param dt
function Sexbound.Core.SexTalk:update(dt)
  self.timer.sextalk = self.timer.sextalk + dt
  
  if self.timer.sextalk >= self.sextalk.cooldown then
    self:sayRandom()
  
    -- Reset sextalk timer
    self.timer.sextalk = 0
  end
end

-- Return a reference to this module's config.
function Sexbound.Core.SexTalk:config()
  return self.sextalk.config
end

--- Returns a random dialog message from the dialog pool.
-- @return a string
function Sexbound.Core.SexTalk:outputRandomMessage()
  -- Get current dialog pool or refresh it
  self.sextalk.dialogPool = self.sextalk.dialogPool or self:refreshDialogPool()

  if not self.sextalk.dialogPool or isEmpty(self.sextalk.dialogPool) then return nil end

  local maxRetry = 10
  local maxHistoryLength = 3
  
  local retry = false
  
  local message = util.randomChoice(self.sextalk.dialogPool)
  
  -- Try to remove the fourth element
  if self.sextalk.history[maxHistoryLength + 1] then
    table.remove(self.sextalk.history, maxHistoryLength + 1)
  end
  
  if self.sextalk.history then
    for i=1,maxRetry do
      for _,v in ipairs(self.sextalk.history) do
        if message == v then
          retry = true
        end
      end
      
      if not message or retry then
        message = util.randomChoice(self.sextalk.dialogPool)
        
        retry = false
      end
    end
  end
  
  table.insert(self.sextalk.history, message)
  
  return message
end

-- Refreshes the cooldown time for this module.
function Sexbound.Core.SexTalk:refreshCooldown()
  self.sextalk.cooldown = util.randomInRange(self:config().cooldown)
  
  return self.sextalk.cooldown
end

--- Refreshes the dialog pool where messages are choosen.
function Sexbound.Core.SexTalk:refreshDialogPool()
  local animationState = animator.animationState("main")

  if Sexbound.API.Status.isClimaxing() then
    animationState = "climax"
  end
  
  local targetActor = self:targetRandomActor()

  if not self.sextalk.dialogConfig[animationState] or not self.sextalk.dialogConfig[animationState][self.sextalk.role] then return end
    
  local roleRoot = self.sextalk.dialogConfig[animationState][self.sextalk.role]
  
  self.sextalk.dialogPool = {}

  -- Predefined list of match elements to use when searching for dialog.
  local match = {
    {"default", self.parent:species()},
    {"default", self.parent:gender()},
    {"default", targetActor.identity.species},
    {"default", targetActor.identity.gender}
  }
  
  -- Predefined list of permutations 1 = "default" and 2 = a specific species / gender.
  local permutations = {
    {1,1,1,1},{1,1,1,2},{1,1,2,1},{1,1,2,2},
    {1,2,1,1},{1,2,1,2},{1,2,2,1},{1,2,2,2},
    {2,1,1,1},{2,1,1,2},{2,1,2,1},{2,1,2,2},
    {2,2,1,1},{2,2,1,2},{2,2,2,1},{2,2,2,2}
  }
  
  for _,v in ipairs(permutations) do
    dialog = roleRoot
    dialog = dialog[match[1][v[1]]] or {}
    dialog = dialog[match[2][v[2]]] or {}
    dialog = dialog[match[3][v[3]]] or {}
    dialog = dialog[match[4][v[4]]] or {}
    
    if dialog.default and not isEmpty(dialog.default) then
      self.sextalk.dialogPool = util.mergeLists(self.sextalk.dialogPool, dialog.default)
    end
  end

  return self.sextalk.dialogPool
end

--- Commands the object to say a random message.
function Sexbound.Core.SexTalk:sayRandom()
  self.sextalk.currentMessage = self:outputRandomMessage() or self.sextalk.currentMessage

  if type(self.sextalk.currentMessage) == "string" then
    object.say(self.sextalk.currentMessage)
    
    self.parent:getEmote():setIsTalking(true)
    
    -- Reset the sextalk timer
    self.timer.sextalk = 0
  else
    self.log:warn("Object was given non-string data to say.")
  end
end

--- Sets a random actor as the target for a future message.
function Sexbound.Core.SexTalk:targetRandomActor()
  local actorData = {}
  
  -- Default the role to 1
  self.sextalk.role = 1
  
  -- Populate actor data with all actors that are not the parent actor.
  for i,actor in ipairs(Sexbound.API.Actors.getActors()) do
    if self.parent:id() ~= actor:id() then
      table.insert(actorData, actor:getData())
    else
      -- Set the role to the parent actor's index in the actors list.
      self.sextalk.role = i
    end
  end
  
  if not isEmpty(actorData) then
    self.sextalk.targetActor = util.randomChoice(actorData)
  end
  
  return self.sextalk.targetActor or nil
end
