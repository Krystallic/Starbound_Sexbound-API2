--- Emote Module.
-- @module Sexbound.Emote
Sexbound.Emote = {}
Sexbound.Emote.__index = Sexbound.Emote

function Sexbound.Emote.new(...)
  local self = setmetatable({}, Sexbound.Emote)
  self:init(...)
  return self
end

--- Initialize this instance.
-- @param emote
-- @param storeActor
function Sexbound.Emote:init(parent)
  self.parent = parent
  
  self.emote = {
    isTalking = false,
    talkingTimeout = 3
  }
  
  self.timer = {
    talking = 0
  }
end

--- Updates this instance.
-- @param dt
function Sexbound.Emote:update(dt)
  if self.emote.isTalking then
    self.timer.talking = self.timer.talking + dt
    
    if self.timer.talking >= self.emote.talkingTimeout then
      self.timer.talking = 0
      self.emote.isTalking = false
      self:showNone()
    end
  end
end

--- Changes the animation state for the parent actor.
-- @param stateName
function Sexbound.Emote:changeAnimationState(stateName)
  animator.setAnimationState(self.parent:role() .. "Emote", stateName, true)
end

-- Shows the 'blabber' animation.
function Sexbound.Emote:showBlabber()
  self.emote.isTalking = true

  self:changeAnimationState("blabber")
end

-- Shows nothing.
function Sexbound.Emote:showNone()
  self:changeAnimationState("none")
end