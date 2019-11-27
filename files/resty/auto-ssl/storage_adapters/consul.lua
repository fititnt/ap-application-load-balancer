-- License: Public Domain


-- lua files/resty/auto-ssl/storage_adapters/consul.lua
print ('teste 123')

-- How to document Lua code:
--   - https://stevedonovan.github.io/ldoc/manual/doc.md.html
--   - https://keplerproject.github.io/luadoc/manual.html

-- I think the path would be /usr/local/share/lua/5.1/resty/auto-ssl/storage_adapters/consul.lua
-- to work with resty/auto-ssl
-- And then use this as reference https://github.com/GUI/lua-resty-auto-ssl/blob/master/lib/resty/auto-ssl/storage_adapters/redis.lua

-- Lean lua in an Hour https://www.youtube.com/watch?v=S4eNl1rA1Ns
-- Definitely an openresty guide/ Hello world https://www.staticshin.com/programming/definitely-an-open-resty-guide/#hello_world
-- Lua in 15 minutes http://tylerneylon.com/a/learn-lua/


-- @module storage_adapter_consul
local _M = {}

-- resty-auto-ssl file.lua/redis.lua have these exported funcions in common ----
function _M.new(auto_ssl_instance)
  return setmetatable({ options = options }, { __index = _M })
end

function _M.get(self, key)
  --  return content                                                -- file.lua
  return res, err                                                   -- redis.lua
end

function _M.set(self, key, value, options)
  -- if err then                                                                -- file.lua
  --   ngx.log(ngx.ERR, "auto-ssl: failed to open file for writing: ", err)     -- file.lua
  --   return false, err                                                        -- file.lua
  -- ...
  -- return true
  return ok, err                                                    -- redis.lua
end

function _M.delete(self, key)
  -- local ok, err = os.remove(file_path(self, key))                -- file.lua
  -- return false, err                                              -- file.lua
  -- return ok, err                                                 -- file.lua
  return connection:del(prefixed_key(self, key))                    -- redis.lua
end

function _M.keys_with_suffix(self, suffix)
  -- return keys                                                    -- file.lua
  return keys, err                                                  -- redis.lua
end

-- resty-auto-ssl redis.lua only -----------------------------------------------

function _M.get_connection(self)
  return connection
end

-- Note: _M.setup() on redis.lua is empty, no arguments, no return value
function _M.setup()
end


-- resty-auto-ssl file.lua only ------------------------------------------------
function _M.setup_worker(self)
end



return _M
