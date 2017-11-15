require "/interface/sexbound/custombutton.lua"

Climax = {}
Climax.__index = Climax

function Climax.new(...)
  local self = setmetatable({}, Climax)
  self:init(...)
  return self
end

--- Initializes this instance.
function Climax:init(canvas, GUIConfig, extraConfig)
  self.debug = extraConfig.debug or false

  self.climax = {
    canvas = canvas or nil,
    GUIConfig = GUIConfig or {},
    config = extraConfig.climaxWidget or {}
  }
  
  self.sharedAlpha = 0
  
  self.climax.progressBars = {}
  
  for _,progressBar in ipairs(self.climax.config.progressBar) do
    table.insert(self.climax.progressBars, progressBar)
  end
  
  self.timer = {
    fadeIn = 0,
    fadeOut = 0
  }
  
  self.timeout = {
    fadeIn = 0.5,
    fadeOut = 0.5
  }
end

--- Return a reference to this instance's main canvas widget.
function Climax:canvas()
  return self.climax.canvas
end

--- Returns a reference to this instance's configuration.
function Climax:config()
  return self.climax.config
end

--- Returns a reference to this instance's GUI configuration.
function Climax:GUIConfig()
  return self.climax.GUIConfig
end

--- Updates this instance.
-- @param dt
-- @param[opt] callback
function Climax:update(dt, callback)
  -- Store the current mouse position within the canvas.
  self.climax.mousePosition = self.climax.canvas:mousePosition()
  
  if type(callback) == "function" then
    callback( self )
  end
end

--- Returns the a reference to this instance's mouse position.
function Climax:mousePosition()
  return self.climax.mousePosition
end

--- Returns a reference to this instance's progressBars.
function Climax:progressBars()
  return self.climax.progressBars
end

--- Renders this instance's main canvas widget.
function Climax:render()
  -- Clear the canvas
  self:canvas():clear()
  
  self.climax.progressBars[1].angle = -90 * self.climax.progressBars[1].amount
  self.climax.progressBars[1].rotation = self.climax.progressBars[1].angle * math.pi / 180
  
  self.climax.progressBars[2].angle = 90 * self.climax.progressBars[2].amount
  self.climax.progressBars[2].rotation = self.climax.progressBars[2].angle * math.pi / 180
  
  self:canvas():drawImage(self:config().backgroundImage, {129,-3}, 1.0, self:config().color, true)
  
  for _,progressBar in ipairs(self.climax.progressBars) do
    self:canvas():drawImageDrawable(self:config().progressBarImage .. "?addmask=" .. self:config().progressBarMask, {129,-3}, 1.0, progressBar.color, progressBar.rotation)
  end
  
  self:canvas():drawImage(self:config().coverImage, {129, -3}, 1.0, self:config().coverColor, true)
end

function Climax:updateAlphaForAllImages(alpha)
  self.climax.config.color[4] = math.min(self:config().progressBarColorFadeInAlpha, alpha)
  
  self.climax.config.coverColor[4] = alpha

  for i,progressBar in ipairs(self.climax.progressBars) do
    progressBar.color[4] = alpha
  end
end

function Climax:updateProgressBars(actors)
  for i,actor in ipairs(actors) do
    if actor.climax.currentPoints ~= 0 then
      self.climax.progressBars[i].amount = actor.climax.currentPoints / actor.climax.maxPoints
    else
      self.climax.progressBars[i].amount = 0
    end
  end
end

-- Returns a reference to this instance's timer.
function Climax:timer()
  return self.timer
end