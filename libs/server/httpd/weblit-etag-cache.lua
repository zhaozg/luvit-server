--[[lit-meta
  name = "creationix/weblit-etag-cache"
  version = "2.0.0"
  description = "The etag-cache middleware caches WebLit responses in ram and uses etags to support conditional requests."
  tags = {"weblit", "middleware", "etag"}
  license = "MIT"
  author = { name = "Tim Caswell" }
  homepage = "https://github.com/creationix/weblit/blob/master/libs/weblit-etag-cache.lua"
]]

local function clone(headers)
  local copy = setmetatable({}, getmetatable(headers))
  for i = 1, #headers do
    copy[i] = headers[i]
  end
  return copy
end

local cache = {}
return function (req, res, go)
  local requested = req.headers["If-None-Match"]
  local host = req.headers.Host
  local key = host and host .. "|" .. req.url or req.url
  local cached = cache[key]
  if not requested and cached then
    req.headers["If-None-Match"] = cached.etag
  end
  go()
  local etag = res.headers.ETag
  if not etag then return end
  if res.statusCode >= 200 and res.statusCode < 300 then
    local body = res.body
    if not body or type(body) == "string" then
      cache[key] = {
        etag = etag,
        code = res.statusCode,
        headers = clone(res.headers),
        body = body
      }
    end
  elseif res.statusCode == 304 then
    if not requested and cached and etag == cached.etag then
      res.statusCode = cached.code
      res.headers = clone(cached.headers)
      res.body = cached.body
    end
  end
end
