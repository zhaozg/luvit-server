--[[lit-meta
  name = "zhaozg/weblit-lhtml"
  version = "0.0.1-1"
  dependencies = {
    "creationix/coro-fs@1.2.3",
    "zhaozg/weblit-dynamic@0.0.1-1",
  }
  description = "The lhtml middleware for Weblit serves lhtml files from disk."
  tags = {"weblit", "middleware", "lhtml"}
  license = "MIT"
  author = { name = "George Zhao" }
  homepage = "https://github.com/zhaozg/weblit/blob/master/libs/weblit-lhtml.lua"
]]
local makeChroot = require('./weblit-fs')
local lhtml_compile = require('./lhtml')
------------------------------------------------------------------------------
return function (base,options)
  options = options or {}
  local fs = makeChroot(base)
  local _ENV = {}
  setmetatable(_ENV, {__index = _G})

  return function (req, res, go)
    local path = (req.params and req.params.path) or req.parsed.pathname
    path = path:match("^[^?#]*")
    if path:byte(1) == 47 then
      path = path:sub(2)
    end
    local stat = fs.stat(path)
    if not stat then return go() end

    if stat.type == "file" then
      if req.url:byte(-1) == 47 then
        res.statusCode = 301
        res.headers.Location = req.url:match("^(.*[^/])/+$")
        return
      end

      local ret = {}
      function _ENV.print(...)
        table.insert(ret,...)
      end

      local dynamic = require('./weblit-dynamic')(function(fpath)
        if fpath:byte(1) == 47 then
          fpath = fpath:sub(2)
        end

        local body = assert(fs.readFile(fpath))
        body = assert(lhtml_compile(body))
        body = table.concat(body,'')
        return body
      end, {
        cached = options.cached,
        _ENV = _ENV
      })

      dynamic(req,res,go)
      res.body = table.concat(ret)
    else
      return go()
    end
  end
end
