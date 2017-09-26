--[[lit-meta
  name = "zhaozg/weblit-dynamic"
  version = "0.0.1-1"
  description = "The dynamic middleware for Weblit serves dynamic content generate."
  tags = {"weblit", "middleware", "lua", "dynamic"}
  license = "MIT"
  author = { name = "George Zhao" }
  homepage = "https://github.com/zhaozg/weblit/blob/master/libs/weblit-dynamic.lua"
]]

local caches = {}

return function (getcode,options)
  assert(getcode and type(getcode)=='function')
  local _ENV = assert(options._ENV)

  return function (req, res)
    local path = (req.params and req.params.path) or req.parsed.pathname
    local code
    if not options.cached then
        code = getcode(path)
        code = assert(loadstring(code))
    elseif caches[path] then
        code = caches[path]
    else
        code = getcode(path)
        code = assert(loadstring(code))
        caches[path]  = code
    end

    _ENV.req = req
    _ENV.res = res
    _ENV.require  = options.require or _ENV.require or require
    local function errh(err)
        local _, dbg = pcall(require,"StackTracePlus")
        if _ then
            dbg.traceback = dbg.stacktrace
        else
            dbg = require'debug'
        end
        return dbg.traceback(err, 2)
    end
    local _, ret = xpcall(function()
        if type(setfenv)=='function' then
            setfenv(code, _ENV)
            ret = code()
        else
            ret = code(_ENV)
        end
    end,errh)
    if _ then
        res.statusCode = res.statusCode or 200
        res.headers["Content-Type"] = res.headers["Content-Type"] or 'text/html'
    else
        res.statusCode = 500
        res.headers["Content-Type"] = 'text/plain'
        if req.log then
            req.log.error(ret)
        else
            req.logger.error('Error:'..path)
            req.logger.error(ret)
        end
        res.body = ret
    end
    res.headers["Content-Type"] = res.headers["Content-Type"] or 'text/html'
    res.headers["Cache-Control"] = "no-cache, no-store, must-revalidate"
    res.headers["Pragma"] = "no-cache"
    res.headers["Expires"] = "0"
    return ret
  end
end
