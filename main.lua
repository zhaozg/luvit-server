--launch proxy service
return require('./init')(function()
io.stdout:setvbuf 'no'

local options = require'./options'
local _, HTTPD
_, HTTPD =  pcall(require, './server/httpd')
if not _ then
  HTTPD = assert(require('server/httpd'))
end

local httpd = HTTPD:new(options)

httpd:on('ofilter',function(req,res)
  if res.statusCode==304 then
    return
  end
  if not res.body then
    res.statusCode = 404
  end
end)
httpd:start()

end)
