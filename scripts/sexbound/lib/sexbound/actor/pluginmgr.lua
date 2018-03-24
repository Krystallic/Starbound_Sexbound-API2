--- Sexbound.Actor.PluginMgr Class Module.
-- @classmod Sexbound.Actor.PluginMgr
-- @author Loxodon
-- @license GNU General Public License v3.0
Sexbound.Actor.PluginMgr = {}
Sexbound.Actor.PluginMgr_mt = { __index = Sexbound.Actor.PluginMgr }

function Sexbound.Actor.PluginMgr:new( parent )
  local self = setmetatable({
    _logPrefix = "PMGR",
    _parent = parent
  }, Sexbound.Actor.PluginMgr_mt )
  
  self._config  = self:loadConfig()
  
  self._plugins = self:loadPlugins()
  
  return self
end

function Sexbound.Actor.PluginMgr:loadConfig()
  return self:getParent():getConfig().plugins
end

function Sexbound.Actor.PluginMgr:loadPlugins()
  local loadedPlugins = {}

  util.each(self._config, function(index, plugin)
    local skip = false
  
    if not plugin.enable then skip = true end
  
    local req = plugin.loadRequirements
  
    if req.gender and req.gender ~= self:getParent():getGender() then
      skip = true
    end
  
    if req.entityType and req.entityType ~= self:getParent():getEntityType() then
      skip = true
    end
  
    if not skip then
      require (plugin.script)
      
      if Sexbound.Actor[plugin.name] then
        plugin.loaded = true
      
        local pluginConfig = root.assetJson(plugin.config)
      
        loadedPlugins[string.lower(plugin.name)] = Sexbound.Actor[plugin.name]:new( self:getParent(), pluginConfig )
      end
    else
      plugin.loaded = false
    end
  end)
  
  return loadedPlugins
end

function Sexbound.Actor.PluginMgr:getConfig()
  return self._config
end

function Sexbound.Actor.PluginMgr:getPlugins(name)
  if name then return self._plugins[name] end
  
  return self._plugins
end

function Sexbound.Actor.PluginMgr:getLoaded(name)
  return self:getConfig()[name].loaded
end

function Sexbound.Actor.PluginMgr:getParent()
  return self._parent
end