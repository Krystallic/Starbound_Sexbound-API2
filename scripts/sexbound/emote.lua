--- Emote Module.
-- @module Sexbound.Emote
Sexbound.Emote = {}
Sexbound.Emote.__index = Sexbound.Emote

require "/scripts/sexbound/moan.lua"

function Sexbound.Emote.new(...)
  local self = setmetatable({}, Sexbound.Emote)
  self:init(...)
  return self
end

--- Initialize this instance.
-- @param parent 
function Sexbound.Emote:init(parent)
  self.parent = parent
  
  self.moan = Sexbound.Moan.new()
  
  self.emote = {
    config = Sexbound.Main.getParameter("emote"),
    isTalking = false,
    talkingTimeout = 3
  }
  
  self.emote.cooldown = self:refreshCooldown()
  
  self.timer = {
    emote = 0,
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
  else
    self.timer.emote = self.timer.emote + dt
    
    if self.timer.emote >= self.emote.cooldown then
      self.timer.emote = 0
      
      self:showRandom()
    end
  end
end

--- Changes the animation state for the parent actor.
-- @param stateName
function Sexbound.Emote:changeAnimationState(stateName)
  if not pcall(function()
    animator.setAnimationState(self.parent:role() .. "Emote", stateName, true)
  end) then 
    animator.setAnimationState(self.parent:role() .. "Emote", "none", true)
  end
end

function Sexbound.Emote:refreshCooldown()
  self.emote.cooldown = util.randomInRange(self.emote.config.cooldown)
  return self.emote.cooldown
end

-- Shows the 'blabber' animation.
function Sexbound.Emote:showBlabber()
  self.emote.isTalking = true

  self:changeAnimationState("blabber")
end

function Sexbound.Emote:showHappy()
  self:changeAnimationState("happy")
end

-- Shows nothing.
function Sexbound.Emote:showNone()
  self:changeAnimationState("none")
end

function Sexbound.Emote:showRandom()
  local choice = util.randomChoice(self.emote.config.pool.default)

  if choice == "moan" then
    if Sexbound.Main.isHavingSex() and not Sexbound.Main.isReseting() then
      self.moan:playRandom(self.parent:gender())
    end
    
    choice = self.moan:getRandomEmote()
  end
  
  self:changeAnimationState(choice)
end

function Sexbound.Emote:reset()
  self:showNone()
end

function Sexbound.Emote:uninit()
  self:showNone()
end