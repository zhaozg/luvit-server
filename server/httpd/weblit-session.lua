--[[lit-meta
  name = "creationix/weblit-session"
  version = "0.1.1-1"
  description = "The session middleware WebLit session caches in ram."
  tags = {"weblit", "middleware", "etag"}
  license = "MIT"
  author = { name = "Tim Caswell" }
  homepage = "https://github.com/creationix/weblit/blob/master/libs/weblit-session.lua"
]]

local uv = require'uv'
local cookie = require'http-cookie'

local cache = {}
local expires = {}
local last_check = uv.now()

return function (req, res, go)
  local cookis = req.headers["Cookie"]
  if cookis and #cookis>0 then
    local cookies = cookie.parse(cookis)
    if cookies.SID then
      local session = cache[cookies.SID]
      if session then
        expires[cookies.SID] = uv.now() + 10*60*1000
        req.session = session
      end
    end
  end

  go()

  if res.statusCode >= 200 and res.statusCode < 400 then
    cookis = nil
    for i=1,#res.headers do
      if res.headers[i][1]=='Set-Cookie' then
        cookis = res.headers[i][2]
      end
    end
    if cookis then
      local cookies = cookie.parse(cookis)
      if cookies.SID then
        cache[cookies.SID] = req.session
        expires[cookies.SID] = uv.now() + 10*60*1000
      end
    end
  end


  if last_check + 5*1000 < uv.now() then
    local now = uv.now()
    for k,v in pairs(expires) do
      if v < now then
        expires[k] = nil
        cache[k] = nil
      end
    end
  end
end
