function init()
  status.setStatusProperty("sexbound_mind_control", true)
end

function update(dt)
  if not status.statusProperty("sexbound_mind_control") then
    effect.expire()
  end
end