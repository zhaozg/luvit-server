--launch proxy service
return require('./init')(function()
io.stdout:setvbuf 'no'


local HTTPD = require'server/httpd'
local options = require'./options'

local httpd = HTTPD:new(options)

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

end)
