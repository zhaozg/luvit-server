--[[lit-meta
  name = "zhaozg/httpd"
  version = "1.0.0"
  description = "Weblit is a webapp framework designed around routes and middleware layers."
  tags = {"weblit", "router", "framework"}
]]

-- Ignore SIGPIPE if it exists on platform
local uv = require('uv')
if uv.constants.SIGPIPE then
  uv.new_signal():start("sigpipe")
end

local server = require('./weblit-server')
return server

