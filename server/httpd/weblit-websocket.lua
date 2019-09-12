--[[lit-meta
  name = "creationix/weblit-websocket"
  version = "3.0.0"
  dependencies = {
    "creationix/websocket-codec@3.0.0",
    "creationix/coro-websocket@3.0.0",
  }
  description = "The websocket middleware for Weblit enables handling websocket clients."
  tags = {"weblit", "middleware", "websocket"}
  license = "MIT"
  author = { name = "Tim Caswell" }
  homepage = "https://github.com/creationix/weblit/blob/master/libs/weblit-websocket.lua"
]]

local codec = require('./websocket-codec')

local makeChroot = require('./weblit-fs')
local caches = {}

return function (base, options)
  options = options or {}
  local fs = makeChroot(base)

  return function (req, res, go)
    local path = (req.params and req.params.path) or req.parsed.pathname
    path = path:match("^[^?#]*")
    if path:byte(1) == 47 then
      path = path:sub(2)
    end
    local stat = fs.stat(path)
    if not stat then return go() end

    local headers = assert(codec.handleHandshake(req.headers, options.protocol))
    res.statusCode = headers.code
    headers.code = nil
    res.headers = headers
    res:flushHeaders()
    res.async = true
    res.encode = codec.encode

    local pending = ''
    req.decode = function(data)
      pending = pending .. data
      local msg, nxt = codec.decode(pending, 1)
      if msg then
        pending = pending:sub(nxt, -1)
        return msg.payload
      end
    end

    req:on('data',function(data)
      if data then
        req:emit('message', data)
      end
    end)

    if stat.type == "file" then
      local code
      if caches[path] then
        code = caches[path]
      else
        code = assert(fs.readFile(path))
        code = assert(loadstring(code))
        caches[path]  = code
      end

      local _ENV = setmetatable({}, {__index = _G})
      _ENV.require  = require
      setfenv(code, _ENV)
      code()
      code = _ENV.GET
      assert(type(code)=='function',
        'not support GET handle in module:'..path)

      if type(setfenv)=='function' then
        setfenv(code, _ENV)
        return code(req, res)
      else
        return code(_ENV)
      end
    else
      return go()
    end
  end
end

