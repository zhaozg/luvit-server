--[[lit-meta
  name = "zhaozg/weblit-resty"
  version = "0.0.1-1"
  dependencies = {
    "zhaozg/weblit-dynamic@0.0.1-1",
    "creationix/coro-fs@1.2.3"
  }
  description = "The middleware for Weblit run lua dynamic context generate."
  tags = {"weblit", "middleware", "lua", "resty", "dynamic"}
  license = "MIT"
  author = { name = "George Zhao" }
  homepage = "https://github.com/zhaozg/weblit/blob/master/libs/weblit-resty.lua"
]]

local makeChroot = require('./weblit-fs')
local caches = {}

return function (base, options)
  local fs = makeChroot(base)
  local prefix = options.prefix or 'api'
  local module = options.module or 'module'
  local ext = options.ext or '.lua'

  local function getcode(fpath)
    if fpath:byte(1) == 47 then
      fpath = fpath:sub(2)
    end
    return assert(fs.readFile(fpath))
  end

  return function (req, res, go)
    local path = string.format('%s/%s%s',prefix,req.params[module],ext)
    req.params.path = path
    local code
    if caches[path] then
      code = caches[path]
    else
      local stat = fs.stat(path)
      if not stat then return go() end
      if stat.type == "file" then
        code = getcode(path)
        code = assert(loadstring(code))
        caches[path]  = code
      end
    end

    local methods = assert(code())
    assert(type(methods[req.method])=='function',
      'not support '..req.method..' in module:'..module)
    return methods[req.method](req,res)
  end
end
