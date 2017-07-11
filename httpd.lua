
local HTTPD = require'./server/httpd'

local httpd = HTTPD:new()

httpd:on('check',function(req,res,go)
  return go()
end)

httpd:on('done',function(req,res)
  print(req.socket.options and "https" or "http", req.method, res.statusCode, req.url)
end)

httpd:on('ofilter',function(req,res)
  if not res.body then
    res.body = string.format('<html><body><h1>%d</h1></body></html>',res.statusCode)
  end
end)

httpd:start()
