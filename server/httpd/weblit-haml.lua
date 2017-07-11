local makeChroot = require('./weblit-fs')
local haml = require('haml')
local lhtml_compile = require('./lhtml')

return function (base, options)
  options = options or {}
  options.format = options.format or "html5"
  options.cached = options.cached==nil and true or options.cached
  options.lhaml = options.lhaml==nil and true or options.lhaml
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
        setfenv(haml.render,_ENV)
        body = assert(haml.render(body,options,_ENV))
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
