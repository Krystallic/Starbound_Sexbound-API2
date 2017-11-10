function init()
  -- Hide the entity from view
  effect.setParentDirectives("?multiply=ffffff00")

  -- Set 'sexbound_sex' status property to true.
  status.setStatusProperty("sexbound_sex", true)
end

function uninit()
  -- Set 'sexbound_sex' status property to false.
  status.setStatusProperty("sexbound_sex", false)
end