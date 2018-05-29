local luvi  = require('luvi')

--from luvit
local http  = require("http")
local https = require("https")
local parseQuery  = require('querystring').parse
local Emitter     = require('core').Emitter

--from deps
local logger    = require('logging')
--from luvit-server
local route     = require('./weblit-router')

local pathJoin  = luvi.path.join
local unpack    = unpack or table.unpack
------------------------------------------------------------------------------
local HTTPD = Emitter:extend()

function HTTPD:initialize(options)
  options = options or {}
  local root = options.root or 'docs'

  --prepare log process
  local log = options.log or {}
  log.log_level = log.log_level or logger.LEVELS.everything
  if type(log.log_level)=='string' then
    log.log_level  = logger.LEVELS[log.log_level]
  end

  logger.init(logger.StdoutFileLogger:new(log))

  self.options = options

    -- Set an outer middleware for logging requests and responses
  local weblit_logger = require('./weblit-logger')(logger)

  local router = route.newRouter()
  self.router = router

  local function onRequest(req, res)
    res.statusCode = 200
    req.logger = logger

    local body = {}
    req:on('data',function(chunk)
      body[#body+1] = chunk
    end)

    res:on('finish',function()
      self:emit('done',req,res)
      weblit_logger(req, res)
    end)

    res:on('write',function()
      self:emit('ofilter',req,res)
      local body = type(res.body)=='table' and table.concat(res.body) or res.body or ''
      if not res.headers["Content-Type"] then
        res:setHeader("Content-Type", "text/html")
      end
      res:setHeader("Content-Length", #body)
      res:finish(body)
    end)

    req:on('end',function()
      body = #body>0 and table.concat(body) or nil
      req.body = body
      self:emit('ifilter',req,res)

      local success, errmsg = pcall(router.run, req, res)
      if not success then
        res.statusCode = 500
        res.body = errmsg
      end

      if not res.async then
        res:emit('write')
      end
    end)
  end

  server = options.secure and
    https.createServer(options.secure, onRequest) or
    http.createServer(onRequest)

  self

  -- This adds missing headers, and tries to do automatic cleanup.
  :use(require('./weblit-auto-headers'))

  -- A caching proxy layer for backends supporting Etags
  :use(require('./weblit-etag-cache'))

  -- session base cookie
  :use(require('./weblit-session'))

  -- acl check
  :use('check')

  --
  if options.resty then
    for k,v in pairs(options.resty) do
        self:route({path = k}, require('./weblit-resty')(root,v) )
    end
  end

  self
  -- filter for lhtml file
  :route({
    filter = function(req)
      return req.parsed.pathname:match('%.lhtml$')
    end
  }, require('./weblit-lhtml')(root, options.lhtml or {}))

  -- filter for haml file
  :route({
    filter = function(req)
      return req.parsed.pathname:match('%.haml$')
    end
  }, require('./weblit-haml')(root, options.haml or {}))

  -- filter for dynamic page generate from lua file
  :route({
    filter = function(req)
      return req.parsed.pathname:match('%.lua$')
    end
  }, require('./weblit-lua')(root, options.lua or {}))

  -- static resource handle, should be last
  :use(require('./weblit-static')(root, options.static or {}))

  self.server = server
end

function HTTPD:use(handler)
  if type(handler)=='string' then
    local fire = handler
    handler = function (req,res,go)
      if not self:emit(fire,req,res,go) then
        go()
      end
    end
  end
  self.router.use(handler)
  return self
end

function HTTPD:route(options, handler)
  self.router.route(options, handler)
  return self
end

function HTTPD:start(port, host, callback)
  port = port or self.options.port or (self.options.secure and 4433 or 8080)
  host = host or self.options.host or '0.0.0.0'
  self.server:listen(port, host, callback)
  return self
end

------------------------------------------------------------------------------
return HTTPD

