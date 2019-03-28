
local HTTPD = require'./server/httpd'

local options = {}
options.resty = {
  ["/api/:module/:object:"] = {
    ["method"]="require",
    ["prefix"]="api",
    ["module"]="module",
    ["ext"]=".lua"
  }
}

options.haml = {cached = false}
options.cached = false
options.port = 80
local httpd = HTTPD:new(options)
--[[
  .websocket({
    path = "/",
    protocol = "test"
  }, function (req, read, write)
    print("New client")
    for message in read do
      message.mask = nil
      write(message)
    end
    write()
    print("Client left")
  end)--

--]]
httpd:on('check',function(req,res,go)
  --req.logger.debug('check')
  return go()
end)

httpd:on('done',function(req,res)
  --req.logger.debug('done')
end)

httpd:on('ofilter',function(req,res)
  --req.logger.debug('ofilter')
  if res.statusCode==304 then
    return
  end
  if not res.body then
    res.statusCode = 404
  end
end)

httpd:start()
