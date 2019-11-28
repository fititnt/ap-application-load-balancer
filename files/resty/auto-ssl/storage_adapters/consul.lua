-- License: Public Domain

---
-- Requisites:
--   opm get hamishforbes/lua-resty-consul
--
-- How to test:
-- Copy this file to /usr/local/share/lua/5.1/resty/auto-ssl/storage_adapters/consul.lua. With ansible would be:
--    ansible -m copy -a "src=./consul.lua dest=/usr/local/share/lua/5.1/resty/auto-ssl/storage_adapters/consul.lua" aguia-pescadora-delta.etica.ai,aguia-pescadora-echo.etica.ai,aguia-pescadora-foxtrot.etica.ai
-- Them set the following on your OpenResty, at http context
--    auto_ssl:set("storage_adapter", "resty.auto-ssl.storage_adapters.consul")
--
-- How to document Lua code:
--   - https://stevedonovan.github.io/ldoc/manual/doc.md.html
--   - https://keplerproject.github.io/luadoc/manual.html
--   - http://lua-users.org/wiki/LuaStyleGuide
--   - http://sputnik.freewisdom.org/en/Coding_Standard
--
-- Using ldoc (https://github.com/stevedonovan/LDoc); the lua-doc from keplerproject says it is obsolete (https://github.com/keplerproject/luadoc)
--    sudo apt install lua-ldoc
-- Then validate documentation with
--    ldoc consul.lua

-- I think the path would be /usr/local/share/lua/5.1/resty/auto-ssl/storage_adapters/consul.lua
-- to work with resty/auto-ssl
-- And then use this as reference https://github.com/GUI/lua-resty-auto-ssl/blob/master/lib/resty/auto-ssl/storage_adapters/redis.lua

-- Lean lua in an Hour https://www.youtube.com/watch?v=S4eNl1rA1Ns
-- Definitely an openresty guide/ Hello world https://www.staticshin.com/programming/definitely-an-open-resty-guide/#hello_world
-- Lua in 15 minutes http://tylerneylon.com/a/learn-lua/

-- Redis equivalent: local redis = require "resty.redis"
local consul = require('resty.consul')
-- local consul = require('resty.auto-ssl.storage_adapters.consul')

-- @module storage_adapter_consul
local _M = {}

--- Local helper function to, if options have prefix, return a prefixed key name
-- @param  self
-- @param  key The umprefixed key name
-- @return The key prefixed
local function prefixed_key(self, key)
  if self.options["prefix"] then
    return self.options["prefix"] .. ":" .. key
  else
    return key
  end
end

-- @TODO: Discover what to type is the return of _M.new (fititnt, 2019-11-27 22:51 BRT)

--- Returns a stored Key Value from the Consul
-- @param   auto_ssl_instance
-- @return  ????
function _M.new(auto_ssl_instance)
  local options = auto_ssl_instance:get("consul") or {}

  if not options["host"] then
    options["host"] = "127.0.0.1"
  end

  if not options["port"] then
    options["port"] = 8500
  end

  if not options["connect_timeout"] then
    options["connect_timeout"] = '60s'
  end

  if not options["read_timeout"] then
    options["read_timeout"] = '60s'
  end

  if not options["ssl"] then
    options["ssl"] = false
  end

  if not options["ssl_verify"] then
    options["ssl_verify"] = true
  end

  return setmetatable({ options = options }, { __index = _M })
end

--- Get the Consul connection, creates one if already does not exist
-- @param   self
-- @return  connection
function _M.get_connection(self)
  local connection = ngx.ctx.auto_ssl_consul_connection
  if connection then
    return connection
  end

  connection = consul:new(self.options)
 

  -- NOTE: From https://github.com/hamishforbes/lua-resty-consul documentation:
  --      "port Defaults to 8500. Set to 0 if using a unix socket as host."
  --      redis.lua validate the connection at start, but resty.consul seems
  --      to validate only on the first request. I will leave this note
  --      here for now (fititnt, 2019-11-27 23:41 BRT)

  -- local ok, err
  -- local connect_options = self.options["connect_options"] or {}
  -- if self.options["socket"] then
  --   ok, err = connection:connect(self.options["socket"], connect_options)
  -- else
  --   ok, err = connection:connect(self.options["host"], self.options["port"], connect_options)
  -- end
  -- if not ok then
  --   return false, err
  -- end

  -- if self.options["auth"] then
  --   ok, err = connection:auth(self.options["auth"])
  --   if not ok then
  --     return false, err
  --   end
  -- end

  -- if self.options["db"] then
  --   ok, err = connection:select(self.options["db"])
  --   if not ok then
  --     return false, err
  --   end
  -- end

  -- if not res then
  --     ngx.log(ngx.ERR, err)
  --     return
  -- end

  ngx.ctx.auto_ssl_consul_connection = connection
  return connection
end

-- Note: _M.setup() on redis.lua is empty, no arguments, no return value
function _M.setup()
end

--- Returns a stored Key Value from the Consul
-- @param  self
-- @param  key   The umprefixed key name
-- @return The value of saved key (if exists)
function _M.get(self, key)
  local connection, connection_err = self:get_connection()
  if connection_err then
    return nil, connection_err
  end

  -- Redis use get, Consul use get_key
  local res, err = connection:get_key(prefixed_key(self, key))
  if res == ngx.null then
    res = nil
  end

  return res, err
end

--- Store a key-value on the Consul
--
-- @todo  There is a difference betwen connection:put (Redis) and from consul
--        from the first parameter. This should be checked
--
-- @todo  options param still not used
--
-- @param  self
-- @param  key      The umprefixed key name
-- @param  value    The values
-- @param  options  The values
-- @return ok       Boolean if result was ok or not
-- @return res  lua-resty-http response object. On error returns nil
-- @return err  On error returns an error message
function _M.set(self, key, value, options)
  local connection, connection_err = self:get_connection()
  if connection_err then
    return false, connection_err
  end

  key = prefixed_key(self, key)

  -- Redis use set, Consul use put_key:
  -- local ok, err = connection:put_key(key, value)
  local res, err = connection:put_key(key, value)

  -- Know issue: not implemented way to expire key at this moment.
  -- The following was from redis.lua
  -- if ok then
  --   if options and options["exptime"] then
  --     local _, expire_err = connection:expire(key, options["exptime"])
  --     if expire_err then
  --       ngx.log(ngx.ERR, "auto-ssl: failed to set expire: ", expire_err)
  --     end
  --   end
  -- end

  -- return ok, err
  return res, err
end

--- Delete a value from Consul based on the unprefixed key
-- @param  self
-- @param  key  The umprefixed key name
-- @return res  lua-resty-http response object. On error returns nil
-- @return err  On error returns an error message
function _M.delete(self, key)
  local connection, connection_err = self:get_connection()
  if connection_err then
    return false, connection_err
  end

  -- Redis use del, Consul uses delete_key
  return connection:delete_key(prefixed_key(self, key))
end

-- TODO: finish _M.keys_with_suffix (fititnt, 2019-27-23:01 BRT)
function _M.keys_with_suffix(self, suffix)
  local connection, connection_err = self:get_connection()
  if connection_err then
    return false, connection_err
  end

  -- Redis use keys, ...
  local keys, err = connection:keys(prefixed_key(self, "*" .. suffix))

  if keys and self.options["prefix"] then
    local unprefixed_keys = {}
    -- First character past the prefix and a colon
    local offset = string.len(self.options["prefix"]) + 2

    for _, key in ipairs(keys) do
      local unprefixed = string.sub(key, offset)
      table.insert(unprefixed_keys, unprefixed)
    end

    keys = unprefixed_keys
  end

  return keys, err
end

return _M
