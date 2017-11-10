require "/scripts/sexbound/nodecontroller.lua"

function init()
  NodeController.init()
end

function die()
  NodeController.destroy()
end

function uninit()
  NodeController.destroy()
end