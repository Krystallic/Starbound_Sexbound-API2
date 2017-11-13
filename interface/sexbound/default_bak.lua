require "/scripts/interp.lua"
require "/scripts/rect.lua"
require "/scripts/util.lua"
require "/scripts/vec2.lua"

require "/scripts/sexbound/util.lua"

require "/interface/sexbound/custombutton.lua"
require "/interface/sexbound/climax/climax.lua"
require "/interface/sexbound/positions/positions.lua"

-- Hook - init
function init()
  self.debug = config.getParameter("config.debug") or false
  
  self.globalAlpha = 0
  
  -- Initialize 'climax' UI element.
  local cGUIConfig = config.getParameter("gui.climax")
  local cConfig = config.getParameter("config.climaxWidget")
  self.climax = Climax.new(widget.bindCanvas("climax"), cGUIConfig, cConfig)
  
  -- Initialize 'positions' UI element.
  local pGUIConfig = config.getParameter("gui.positions")
  local pConfig = config.getParameter("config.positionWidget")
  self.positions = Positions.new(widget.bindCanvas("positions"), pGUIConfig, pConfig)
   
  -- Store the main Sexbound controller ID.
  self.controllerId = config.getParameter("config.controllerId")
  
  -- Initialize timers.
  initTimers()
  
  -- Initialize buttons.
  self.buttons = {}
  for _,v in ipairs( config.getParameter("config.buttons") ) do
    table.insert(self.buttons, CustomButton.new(v))
  end
  
  -- Initially focus the player's mouse on the 'positions' canvas widget.
  widget.focus("positions")
end

-- Hook - update
function update(dt)
  -- Dismiss this pane when player is no longer lounging.
  if not player.isLounging() then pane.dismiss() end

  -- Sync the UI with the Main Sexbound controller.
  if self.timer.sync == self.timeout.sync then
    syncUI()
  end
  
  -- Update climax UI element
  self.climax:update(dt)
  
  -- Update positions UI element
  self.positions:update(dt)
  
  -- Update the fadeIn and fadeOut effect.
  if rect.contains({0,0,258,258}, mousePosition) then
    self.timer.fadeOut = 0
    canvasFadeIn(dt)
  else
    self.timer.fadeIn = 0
    canvasFadeOut(dt)
  end

  local progressBar1Angle = -90 * self.climaxWidget.progressBar[1].amount
  local progressBar1Rotation = progressBar1Angle * math.pi / 180
  
  local progressBar2Angle = 90 * self.climaxWidget.progressBar[2].amount
  local progressBar2Rotation = progressBar2Angle * math.pi / 180
    
  -- Draw the climax widget background.
  --self.canvas.positions:drawImage(self.climaxWidget.backgroundImage, {129,129}, 1.0, self.climaxWidget.color, true)
  
  -- Draw climax progress bar 1
  --self.canvas.climax:drawImageDrawable(self.climaxWidget.progressBarImage .. "?addmask=" .. self.climaxWidget.progressBarMask, {129,-3}, 1.0, self.climaxWidget.progressBar[1].color, progressBar1Rotation)
  
  -- Draw climax progress bar 2
  --self.canvas.climax:drawImageDrawable(self.climaxWidget.progressBarImage .. "?addmask=" .. self.climaxWidget.progressBarMask, {129,-3}, 1.0, self.climaxWidget.progressBar[2].color, progressBar2Rotation)
  
  -- Draw the climax widget cover.
  --self.canvas.positions:drawImage(self.climaxWidget.coverImage, {129,129}, 1.0, self.climaxWidget.coverColor, true)
  
  -- Draw the positions widget background.
  --self.canvas.positions:drawImage(self.positionWidget.backgroundImage, {129,129}, 1.0, self.positionWidget.color, true)

  
  for _,v in ipairs(self.buttons) do
    if self.debug then
      v:drawPoly(self.canvas.positions)
      v:drawBoundingBox(self.canvas.positions)
    end

    if v:boundingBoxContains(mousePosition) then
      if self.debug then v:drawBoundingBox(self.canvas.positions, "blue") end
    
      if v:polyContains(mousePosition) then
        -- Draw hover image
        if v:hoverImage() then
          if self.debug then v:drawPoly(self.canvas.positions, "white") end
          
          self.canvas.positions:drawImage(v:hoverImage(), {129,129}, 1.0, {255,255,255,128}, true)
        end
      end
    else
      
    end
    
    -- Draw button image
    if v:image() then
      self.canvas.positions:drawImage(v:image(), v:imagePosition(), 1.0, self.positionWidget.colorButtons, true)
    end
  end  
end

-- Hook - dismissed
function dismissed()
  Sexbound_Util.sendMessage(player.id(), "sexbound-ui-dismiss")
end

function fadeIn(dt, callback)
  self.timer.fadeIn = math.min(self.timeout.fadeIn, self.timer.fadeIn + dt)
  
  local ratio = self.timer.fadeIn / self.timeout.fadeIn
  
  return math.floor( math.clamp(interp.linear(ratio, self.globalAlpha, 255), 0, 256 * percent) )
end

function fadeOut(dt, percent)
  self.timer.fadeOut = math.min(self.timeout.fadeOut, self.timer.fadeOut + dt)
  
  local ratio = self.timer.fadeOut / self.timeout.fadeOut
  
  return math.floor( math.clamp(interp.linear(ratio, self.globalAlpha, 0), 0, 256 * percent) )
end

function canvasFadeIn(dt)
  self.timer.fadeIn = math.min(self.timeout.fadeIn, self.timer.fadeIn + dt)
  
  local ratio = self.timer.fadeIn / self.timeout.fadeIn
  
  self.climaxWidget.color[4] = interp.linear(ratio, self.colorWidget.color[4], self.colorWidget.fadeInAlpha)
  
  self.climaxWidget.coverColor[4] = interp.linear(ratio, self.colorWidget.coverColor[4], self.colorWidget.coverColorFadeInAlpha)
  
  
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
  if rect.contains({29,29,229,229}, position) then
    for _,v in ipairs(self.buttons) do
      -- Check if player click within bounding box to save processing.
      if v:boundingBoxContains(position) and v:polyContains(position) then
        if isButtonDown then
          v:playSound()
          
          return v:callAction()
        end
      end
    end
  end
end

--- Initializes timers.
function initTimers()
  self.timer = {
    fadeIn  = 0,
    fadeOut = 0,
    sync = 0
  }
  
  self.timeout = {
    fadeIn = 0.5,
    fadeOut = 0.5,
    sync = 0.1
  }
end

function openScriptPane(args)
  player.interact("ScriptPane", args.config)
end

function switchPosition(args)
  Sexbound_Util.sendMessage(player.loungingIn(), "node-switch-position", args)
end

function switchRole(args)
  Sexbound_Util.sendMessage(player.loungingIn(), "node-switch-role", args)
end

--- Sync the UI with relative Sexbound controller.
function syncUI()
  Sexbound_Util.sendMessage(self.controllerId, "main-sync-ui", nil, true)

  Sexbound_Util.updateMessage("main-sync-ui", function(result)
    for i,actor in ipairs(result.actors) do
      local climaxPoints = actor.climaxPoints
      if climaxPoints ~= 0 then
        self.climaxWidget.progressBar[i].amount = actor.climaxPoints / actor.maxClimaxPoints
      else
        self.climaxWidget.progressBar[i].amount = 0
      end
    end
  end)
end