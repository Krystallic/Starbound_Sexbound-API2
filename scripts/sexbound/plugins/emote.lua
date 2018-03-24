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
    _isTalking = false,
    _isMoaning = false,
    _moaningTimeout = 2,
    _talkingTimeout = 3,
    _timer = {emote = 0, talking = 0, moaning = 0}
  }, Sexbound.Actor.Emote_mt)

  self:init(parent, self._logPrefix, function()
    self._cooldown = self:refreshCooldown()
  end)
  
  return self
end

function Sexbound.Actor.Emote:onMessage(message)
  if message:getType() == "Sexbound:Moan:Moan" then
    self:setIsMoaning(true)
  end
  
  if message:getType() == "Sexbound:SexTalk:Talk" then
    self:setIsTalking(true)
  end
end

function Sexbound.Actor.Emote:onUpdateSexState(dt)
  if self._isMoaning or self._isTalking then
    -- The actor is moaning 
    if self._isMoaning then
      self._timer.moaning = self._timer.moaning + dt
      
      if self._timer.moaning >= self._moaningTimeout then
        self:showNone()
      
        -- Reset the moaning timer
        self._timer.moaning = 0
        self._isMoaning = false
      end
    end
    
    -- The actor is talking
    if self._isTalking then
      self._timer.talking = self._timer.talking + dt
      
      if self._timer.talking >= self._talkingTimeout then
        self:showNone()
        
        -- Reset the talking timer
        self._timer.talking = 0
        self._isTalking = false
      end
    end
  else
    self._timer.emote = self._timer.emote + dt
    
    if self._timer.emote >= self._cooldown then
      self._timer.emote = 0
      
      self:showRandom()
    end
  end
end

function Sexbound.Actor.Emote:onExitSexState()
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

--- Sets the 'isMoaning' status for this instance.
function Sexbound.Actor.Emote:setIsMoaning(value)
  self._isMoaning = value
  
  self:showMoan()
end

--- Sets the 'isTalking' status for this instance.
function Sexbound.Actor.Emote:setIsTalking(value)
  self._isTalking = value
end

--- Shows the 'blabber' animation.
function Sexbound.Actor.Emote:showBlabber()
  self._isTalking = true

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
  self:showNone()
end