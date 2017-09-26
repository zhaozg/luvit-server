
local HTTPD = require'./server/httpd'

local httpd = HTTPD:new()

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
