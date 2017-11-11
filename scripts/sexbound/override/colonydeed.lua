require "/scripts/util.lua"

-- Override the init function. First defined by 'colonydeed.lua'
sexbound_init = init
function init()
  sexbound_init() -- Call the old init function. 
  
  if storage.occupier then
    for i,tenant in ipairs(storage.occupier.tenants) do
      storage.occupier.tenants[i].transformIntoObject = false
    end
  end
  
  message.setHandler("transform-into-object", function(_, _, args)
    if storage and storage.occupier then
      for i,tenant in ipairs(storage.occupier.tenants) do
        if tenant.uniqueId == args.uniqueId then
          storage.occupier.tenants[i].transformIntoObject = true
          
          world.sendEntityMessage(args.uniqueId, "sexbound-unload", nil)
        end
      end
    end

    return true
  end)
  
  message.setHandler("transform-into-npc", function(_, _, args)
    if storage and storage.occupier then
      for i,tenant in ipairs(storage.occupier.tenants) do
        if tenant.uniqueId == args.uniqueId then
          storage.occupier.tenants[i].transformIntoObject = false
        end
      end
    end
    
    return true
  end)
end

-- Override the anyTenantsDead function. First defined by 'colonydeed.lua'
sexbound_anyTenantsDead = anyTenantsDead
function anyTenantsDead()
  for _,tenant in ipairs(storage.occupier.tenants) do
    if not isTransformedIntoObject(tenant) then
      return sexbound_anyTenantsDead()
    end
  end
  return false
end

-- Override the respawnTenants function. First defined by 'colonydeed.lua'
sexbound_respawnTenants = respawnTenants
function respawnTenants()
  if not storage.occupier then
    return
  end
  
  local tenants = { normal = {}, object = {} }
  
  for _,tenant in ipairs(storage.occupier.tenants) do
    if isTransformedIntoObject(tenant) then
      table.insert(tenants.object, tenant)
    end
    
    if not isTransformedIntoObject(tenant) then
      table.insert(tenants.normal, tenant)
    end
  end
  
  storage.occupier.tenants = tenants.normal
  
  sexbound_respawnTenants()
  
  storage.occupier.tenants = util.mergeTable(storage.occupier.tenants, tenants.object)
end

-- Return whether or not the tenant is turned into an object.
function isTransformedIntoObject(tenant)
  return tenant.transformIntoObject or false
end