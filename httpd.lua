
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

local httpd = HTTPD:new(options)

httpd:on('check',function(req,res,go)
  req.logger.debug('check')
  return go()
end)

httpd:on('done',function(req,res)
  req.logger.debug('done')
end)

httpd:on('ofilter',function(req,res)
  req.logger.debug('ofilter')
  if not res.body then
    res.body = string.format('<html><body><h1>%d</h1></body></html>',res.statusCode)
  end
end)

httpd:start()
