Positions = {}
Positions.__index = Positions

function Positions.new(...)
  local self = setmetatable({}, Positions)
  self:init(...)
  return self
end

--- Initializes this instance.
function Positions:init(canvas, GUIConfig, extraConfig)
  self.debug = extraConfig.debug or false

  self.positions = {
    canvas = canvas or nil,
    GUIConfig = GUIConfig or {},
    config = extraConfig.positionsWidget or {}
  }
  
  self.timer = {
    fadeIn = 0,
    fadeOut = 0
  }
  
  self.timeout = {
    fadeIn = 0.5,
    fadeOut = 0.5
  }
end

--- Updates this instance.
-- @param dt
-- @param[opt] callback
function Positions:update(dt, callback)
  -- Store the current mouse position within the canvas.
  self.positions.mousePosition = self.positions.canvas:mousePosition()
  
  if type(callback) == "function" then
    callback( self )
  end
end

function Positions:updateAlphaForAllImages(alpha)
  self.positions.config.color[4] = math.min(self:config().fadeInAlpha, alpha)
  self.positions.config.colorButtons[4] = alpha
end

--- Returns a reference to this instance's main canvas widget.
function Positions:canvas()
  return self.positions.canvas
end

--- Returns a reference to this instance's configuration.
function Positions:config()
  return self.positions.config
end

--- Returns a reference to this instance's GUI configuration.
function Positions:GUIConfig()
  return self.positions.GUIConfig
end

--- Returns the a reference to this instance's mouse position.
function Positions:mousePosition()
  return self.positions.mousePosition or nil
end

--- Renders this instance's main canvas widget.
function Positions:render()
  -- Clear the canvas
  self:canvas():clear()
  
  -- Draw the background image for 'positions'.
  self:canvas():drawImage(self:config().backgroundImage, {129,129}, 1.0, self:config().color, true)
end

-- Returns a reference to this instance's timer.
function Positions:timer()
  return self.timer
end