--- Sexbound.Core.Emote Class Module.
-- @classmod Sexbound.Core.Emote
Sexbound.Core.Emote = {}
Sexbound.Core.Emote.__index = Sexbound.Core.Emote

--- Instantiates a new instance of Emote.
-- @param parent
function Sexbound.Core.Emote.new(parent)
  local self = setmetatable({}, Sexbound.Core.Emote)

  self.parent = parent
  
  self.emote = {
    config = util.mergeTable({}, Sexbound.API.getParameter("emote")),
    isTalking = false,
    isMoaning = false,
    moaningTimeout = 2,
    talkingTimeout = 3
  }
  
  self.emote.cooldown = self:refreshCooldown()
  
  self.timer = {
    emote = 0,
    talking = 0,
    moaning = 0
  }
  
  return self
end

--- Updates this instance.
-- @param dt
function Sexbound.Core.Emote:update(dt)
  if self.emote.isMoaning or self.emote.isTalking then
    -- The actor is moaning 
    if self.emote.isMoaning then
      self.timer.moaning = self.timer.moaning + dt
      
      if self.timer.moaning >= self.emote.moaningTimeout then
        self:showNone()
      
        -- Reset the moaning timer
        self.timer.moaning = 0
        self.emote.isMoaning = false
      end
    end
    
    -- The actor is talking
    if self.emote.isTalking then
      self.timer.talking = self.timer.talking + dt
      
      if self.timer.talking >= self.emote.talkingTimeout then
        self:showNone()
        
        -- Reset the talking timer
        self.timer.talking = 0
        self.emote.isTalking = false
      end
    end
  else
    self.timer.emote = self.timer.emote + dt
    
    if self.timer.emote >= self.emote.cooldown then
      self.timer.emote = 0
      
      self:showRandom()
    end
  end
end

--- Uninitializes this instance.
function Sexbound.Core.Emote:uninit()
  self:showNone()
end

--- Returns a reference to this module's config.
function Sexbound.Core.Emote:config()
  return self.emote.config
end

--- Changes the animation state for the parent actor.
-- @param stateName
function Sexbound.Core.Emote:changeAnimationState(stateName)
  if not pcall(function()
    animator.setAnimationState(self.parent:role() .. "Emote", stateName, true)
  end) then 
    animator.setAnimationState(self.parent:role() .. "Emote", "none", true)
  end
end

--- Refreshes the cooldown time for this module.
function Sexbound.Core.Emote:refreshCooldown()
  self.emote.cooldown = util.randomInRange(self:config().cooldown)
  
  return self.emote.cooldown
end

--- Reset the actor's emote.
function Sexbound.Core.Emote:reset()
  self:showNone()
end

--- Sets the 'isMoaning' status for this instance.
function Sexbound.Core.Emote:setIsMoaning(value)
  self.isMoaning = value
  
  self:showMoan()
end

--- Sets the 'isTalking' status for this instance.
function Sexbound.Core.Emote:setIsTalking(value)
  self.isTalking = value
end

--- Shows the 'blabber' animation.
function Sexbound.Core.Emote:showBlabber()
  self.emote.isTalking = true

  self:changeAnimationState("blabber")
end

--- Shows the 'happy' animation.
function Sexbound.Core.Emote:showHappy()
  self:changeAnimationState("happy")
end

--- Shows a random animation for moan that specified in the configuration file.
function Sexbound.Core.Emote:showMoan()
  self:changeAnimationState(util.randomChoice( self:config().moan ))
end

--- Shows nothing.
function Sexbound.Core.Emote:showNone()
  self:changeAnimationState("none")
end

--- Shows a random emote animation.
function Sexbound.Core.Emote:showRandom()
  local choice = util.randomChoice(self:config().auto)

  self:changeAnimationState(choice)
end

