--- Sexbound.Actor.Emote Class Module.
-- @classmod Sexbound.Actor.Emote
-- @author Loxodon
-- @license GNU General Public License v3.0

require "/scripts/sexbound/lib/sexbound/actor/plugin.lua"

Sexbound.Actor.Emote = Sexbound.Actor.Plugin:new()
Sexbound.Actor.Emote_mt = { __index = Sexbound.Actor.Emote }

--- Instantiates a new instance of Emote.
-- @param parent
-- @param config
function Sexbound.Actor.Emote:new( parent, config )
  local self = setmetatable({
    _logPrefix = "EMOT",
    _config    = config,
    _timeout   = {emote = 2, talking = 3, moaning = 2},
    _timer     = {emote = 0, talking = 0, moaning = 0}
  }, Sexbound.Actor.Emote_mt)

  self:init(parent, self._logPrefix, function()
    self._cooldown = self:refreshCooldown()
  end)
  
  return self
end

function Sexbound.Actor.Emote:onMessage(message)
  if message:getType() == "Sexbound:Moan:Moan" then
    self:moan()
  end
  
  if message:getType() == "Sexbound:PrepareRemoveActor" then
    self:showNone()
  end
  
  if message:getType() == "Sexbound:SexTalk:Talk" then
    self:talk()
  end
end

function Sexbound.Actor.Emote:moan()
  local actor = self:getParent()

  actor:addStatus("moaning")
  actor:removeStatus("talking")
  
  self:showMoan()
end

function Sexbound.Actor.Emote:talk()
  local actor = self:getParent()

  actor:addStatus("talking")
  actor:removeStatus("moaning")

  self:showBlabber()
end

function Sexbound.Actor.Emote:update(dt)
  local actor = self:getParent()
  
  if actor:hasStatus("moaning") or actor:hasStatus("talking") then
    util.each({"moaning", "talking"}, function(index, status)
      if actor:hasStatus(status) then
        self._timer[status] = self._timer[status] + dt
        
        if self._timer[status] >= self._timeout[status] then
          self:showNone()
          
          self._timer[status] = 0
          actor:removeStatus(status)
        end
      end
    end)
    
    return
  end
  
  self._timer.emote = self._timer.emote + dt
  
  if self._timer.emote >= self._cooldown then
    self._timer.emote = 0
    
    self:showRandom()
  end
end

function Sexbound.Actor.Emote:onEnterIdleState()
  self:showNone()
end

function Sexbound.Actor.Emote:onUpdateIdleState(dt)
  -- self:update(dt)
end

function Sexbound.Actor.Emote:onExitIdleState()
  self:showNone()
end

function Sexbound.Actor.Emote:onEnterSexState()
  self:showNone()
end

function Sexbound.Actor.Emote:onUpdateSexState(dt)
  self:update(dt)
end

function Sexbound.Actor.Emote:onExitSexState()
  self:showNone()
end

function Sexbound.Actor.Emote:onEnterClimaxState()
  self:showHappy()
end

function Sexbound.Actor.Emote:onUpdateClimaxState(dt)
  self:update(dt)
end

function Sexbound.Actor.Emote:onExitClimaxState()
  self:showNone()
end

--- Changes the animation state for the parent actor.
-- @param stateName
function Sexbound.Actor.Emote:changeAnimationState(stateName)
  if not pcall(function()
    animator.setAnimationState(self:getParent():getRole() .. "Emote", stateName, true)
  end) then 
    animator.setAnimationState(self:getParent():getRole() .. "Emote", "none", true)
  end
end

--- Refreshes the cooldown time for this module.
function Sexbound.Actor.Emote:refreshCooldown()
  self._cooldown = util.randomInRange(self:getConfig().cooldown)
  
  return self._cooldown
end

--- Reset the actor's emote.
function Sexbound.Actor.Emote:reset()
  self:showNone()
end

--- Shows the 'blabber' animation.
function Sexbound.Actor.Emote:showBlabber()
  self:changeAnimationState("blabber")
end

--- Shows the 'happy' animation.
function Sexbound.Actor.Emote:showHappy()
  self:changeAnimationState("happy")
end

--- Shows a random animation for moan that specified in the configuration file.
function Sexbound.Actor.Emote:showMoan()
  self:changeAnimationState(util.randomChoice( self:getConfig().moan ))
end

--- Shows nothing.
function Sexbound.Actor.Emote:showNone()
  self:changeAnimationState("none")
end

--- Shows a random emote animation.
function Sexbound.Actor.Emote:showRandom()
  local choice = util.randomChoice(self:getConfig().auto)

  self:changeAnimationState(choice)
end

--- Uninitializes this instance.
function Sexbound.Actor.Emote:uninit()
  self:getLog():info("Uniniting.")

  self:showNone()
end