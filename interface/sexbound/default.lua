require "/scripts/interp.lua"
require "/scripts/rect.lua"
require "/scripts/util.lua"
require "/scripts/vec2.lua"

require "/scripts/sexbound/util.lua"
require "/interface/sexbound/custombutton.lua"

-- Hook - init
function init()
  self.debug = config.getParameter("config.debug") or false
  
  self.canvas = widget.bindCanvas("positions")
  
  self.positionWidget = config.getParameter("config.positionWidget")
  
  self.timer = {
    fadeIn  = 0,
    fadeOut = 0
  }
  
  self.timeout = {
    fadeIn = 0.5,
    fadeOut = 0.5
  }
  
  -- Load buttons
  self.buttons = {}
  for _,v in ipairs( config.getParameter("config.buttons") ) do
    table.insert(self.buttons, CustomButton.new(v))
  end
  
  widget.focus("positions")
end

-- Hook - update
function update(dt)
  if not player.isLounging() then pane.dismiss() end

  self.canvas:clear()
  
  if rect.contains({0,0,200,200}, self.canvas:mousePosition()) then
    self.timer.fadeOut = 0
    canvasFadeIn(dt)
  else
    self.timer.fadeIn = 0
    canvasFadeOut(dt)
  end

  --self.positionWidget.angle = util.wrap(self.positionWidget.angle + (self.positionWidget.rotationSpeed * dt), 0, 360)
  
  --self.canvas:drawImageDrawable(self.positionWidget.image, {100,100}, 1.0, self.positionWidget.color, math.floor(self.positionWidget.angle))

  self.canvas:drawImage(self.positionWidget.backgroundImage, {100,100}, 1.0, self.positionWidget.color, true)
  
  for _,v in ipairs(self.buttons) do
    if self.debug then
      v:boundingBoxContains(self.canvas:mousePosition())
    
      v:drawDebug(self.canvas)
    end
    
    if v:image() then
      self.canvas:drawImage(v:image(), v:imagePosition(), 1.0, self.positionWidget.colorButtons, true)
    end
  end  
end

-- Hook - dismissed
function dismissed()
  Sexbound_Util.sendMessage(player.id(), "sexbound-ui-dismiss")
end

function canvasFadeIn(dt)
  self.timer.fadeIn = math.min(self.timeout.fadeIn, self.timer.fadeIn + dt)
  
  local ratio = self.timer.fadeIn / self.timeout.fadeIn
  
  self.positionWidget.color[4] = interp.linear(ratio, self.positionWidget.color[4], self.positionWidget.fadeInAlpha)
  
  self.positionWidget.colorButtons[4] = interp.linear(ratio, self.positionWidget.colorButtons[4], self.positionWidget.fadeInAlphaButtons)
end

function canvasFadeOut(dt)
  self.timer.fadeOut = math.min(self.timeout.fadeOut, self.timer.fadeOut + dt)
  
  local ratio = self.timer.fadeOut / self.timeout.fadeOut
  
  self.positionWidget.color[4] = interp.linear(ratio, self.positionWidget.color[4], 0)
  
  self.positionWidget.colorButtons[4] = interp.linear(ratio, self.positionWidget.colorButtons[4], 0)
end

function canvasClickEvent(position, button, isButtonDown)
  if rect.contains({0,0,200,200}, position) then
    for _,v in ipairs(self.buttons) do
      -- Check if player click within bounding box to save processing.
      if v:boundingBoxContains(position) and v:polyContains(position) then
        if isButtonDown then
          v:playSound()
          
          return v:action()
        end
      end
    end
  end
end

function switchPosition(args)
  Sexbound_Util.sendMessage(player.loungingIn(), "main-switch-position", args)
end

function switchRole(args)
  Sexbound_Util.sendMessage(player.loungingIn(), "main-switch-role", args)
end