--- SexTalk Module.
-- @module SexTalk

Sexbound.SexTalk = {}
Sexbound.SexTalk.__index = Sexbound.SexTalk

function Sexbound.SexTalk.new(...)
  local self = setmetatable({}, Sexbound.SexTalk)
  self:init(...)
  return self
end

--- Initialize this instance.
function Sexbound.SexTalk:init(actor)
  self.parent = actor
  
  self.log = Sexbound.Log.new({
    moduleName = "SexTalk"
  })
  
  self.sextalk = {}
  self.sextalk.config = root.assetJson(Sexbound.Main.getParameter("sextalk.config"))
  self.sextalk.history = {}
  self.sextalk.currentMessage = "*Silent*"
end

function Sexbound.SexTalk:refreshDialogPool()
  local animationState = animator.animationState("sex")
  
  local targetActor = self:targetRandomActor()

  if not self.sextalk.config[animationState] or not self.sextalk.config[animationState][self.sextalk.role] then return end
    
  local roleRoot = self.sextalk.config[animationState][self.sextalk.role]
  
  self.sextalk.dialogPool = {}

  local match = {
    {"default", self.parent:species()},
    {"default", self.parent:gender()},
    {"default", targetActor.identity.species},
    {"default", targetActor.identity.gender}
  }
  
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

function Sexbound.SexTalk:targetRandomActor()
  local actorData = {}
  
  self.sextalk.role = 1
  
  -- Populate actor data with all actors that are not the parent actor.
  for i,actor in ipairs(Sexbound.Main.getActors()) do
    if self.parent:id() ~= actor:id() then
      table.insert(actorData, actor:getData())
    else
      -- Set the role to the parent actor's index in the actors list.
      self.sextalk.role = i
    end
  end
  
  self.sextalk.targetActor = util.randomChoice(actorData)
  
  return self.sextalk.targetActor
end

function Sexbound.SexTalk:randomMessage()
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

function Sexbound.SexTalk:sayRandom()
  self.sextalk.dialogPool = self.sextalk.dialogPool or self:refreshDialogPool()
  
  if self.sextalk.dialogPool and not isEmpty(self.sextalk.dialogPool) then
    self.sextalk.currentMessage = self:randomMessage()
  
    if type(self.sextalk.currentMessage) == "string" then
      object.say(self.sextalk.currentMessage)
    end
  end
end