--[[lit-meta
  name = "creationix/weblit-logger"
  version = "2.0.0"
  description = "The logger middleware for Weblit logs basic request and response information."
  tags = {"weblit", "middleware", "logger"}
  license = "MIT"
  author = { name = "Tim Caswell" }
  homepage = "https://github.com/creationix/weblit/blob/master/libs/weblit-logger.lua"
]]

return function(options)
  options = options or {}
  options.log = options.log or print

  return function(req, res, go)
    -- Skip this layer for clients who don't send User-Agent headers.
    local userAgent = req.headers["user-agent"] or ''
    -- Run all inner layers first.
    go()
    -- And then log after everything is done
    if options.raw then
      options.log(req, res)
    else
      options.log(string.format("%s %s %s %s", req.method,  req.url, res.statusCode, userAgent))
    end
  end
end
