--[[lit-meta
  name = "zhaozg/weblit-lua"
  version = "0.0.1-1"
  dependencies = {
    "zhaozg/weblit-dynamic@0.0.1-1",
    "creationix/coro-fs@1.2.3"
  }
  description = "The middleware for Weblit run lua dynamic context generate."
  tags = {"weblit", "middleware", "lua", "dynamic"}
  license = "MIT"
  author = { name = "George Zhao" }
  homepage = "https://github.com/zhaozg/weblit/blob/master/libs/weblit-lua.lua"
]]

local makeChroot = require('./weblit-fs')

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

    if stat.type == "file" then
      if req.url:byte(-1) == 47 then
        res.statusCode = 301
        res.headers.Location = req.url:match("^(.*[^/])/+$")
        return
      end

      local dynamic = require('./weblit-dynamic')(function(fpath)
        if fpath:byte(1) == 47 then
          fpath = fpath:sub(2)
        end
        return assert(fs.readFile(fpath))
      end,
      {
        cached = options.cached,
        _ENV = _G
      })

      dynamic(req,res,go)
    else
      return go()
    end
  end
end
