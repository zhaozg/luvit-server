local url = require("url")
local http = require("http")
local https = require("https")
local pathJoin = require('luvi').path.join

local parseQuery = require('querystring').parse
local multipart  = require('./multipart').parse

local unpack = unpack or table.unpack

local Emitter = require('core').Emitter

------------------------------------------------------------------------------
local quotepattern = '(['..("%^$().[]*+-?"):gsub("(.)", "%%%1")..'])'
local function escape(str)
    return str:gsub(quotepattern, "%%%1")
end

local function compileGlob(glob)
  local parts = {"^"}
  for a, b in glob:gmatch("([^*]*)(%**)") do
    if #a > 0 then
      parts[#parts + 1] = escape(a)
    end
    if #b > 0 then
      parts[#parts + 1] = "(.*)"
    end
  end
  parts[#parts + 1] = "$"
  local pattern = table.concat(parts)
  return function (string)
    return string and string:match(pattern)
  end
end

local function compileRoute(route)
  local parts = {"^"}
  local names = {}
  for a, b, c, d in route:gmatch("([^:]*):([_%a][_%w]*)(:?)([^:]*)") do
    if #a > 0 then
      parts[#parts + 1] = escape(a)
    end
    if #c > 0 then
      parts[#parts + 1] = "(.*)"
    else
      parts[#parts + 1] = "([^/]*)"
    end
    names[#names + 1] = b
    if #d > 0 then
      parts[#parts + 1] = escape(d)
    end
  end
  if #parts == 1 then
    return function (string)
      if string == route then return {} end
    end
  end
  parts[#parts + 1] = "$"
  local pattern = table.concat(parts)
  return function (string)
    local matches = {string:match(pattern)}
    if #matches > 0 then
      local results = {}
      for i = 1, #matches do
        results[i] = matches[i]
        results[names[i]] = matches[i]
      end
      return results
    end
  end
end

------------------------------------------------------------------------------
local HTTPD = Emitter:extend()

function HTTPD:initialize(options)
  options = options or {}
  local root = options.root or 'docs'

  self.options = options

  local handlers = {}
  self.handlers = handlers

  local function onRequest(req, res)
    res.statusCode = 200

    local function run(i)
      local success, err = pcall(function ()
        i = i or 1
        local go = i < #handlers
          and function ()
            return run(i + 1)
          end
          or function ()
            res.statusCode = 404
          end
        return handlers[i](req, res, go)
      end)
      if not success then
        res.statusCode = 500
        res.body = err
      end
    end

    local body = {}
    req:on('data',function(chunk)
      body[#body+1] = chunk
    end)

    res:on('finish',function()
      self:emit('done',req,res)
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

      run(1)

      if not res.async then
        res:emit('write')
      end
    end)
  end

  server = options.secure and
    https.createServer(options.secure, onRequest) or
    http.createServer(onRequest)

  self
  -- Set an outer middleware for logging requests and responses
  :use(require('./weblit-logger')(options.log))

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

  self.handlers[#self.handlers + 1] = handler
  return self
end

function HTTPD:route(options, handler)
  local method = options.method
  local path = options.path and compileRoute(options.path)
  local host = options.host and compileGlob(options.host)
  local filter = options.filter
  self:use(function (req, res, go)
    if not req.parsed then req.parsed=url.parse(req.url) end
    if method and req.method ~= method then return go() end
    if host and not host(req.headers.host) then return go() end
    if filter and not filter(req) then return go() end
    --parse query
    local pathname, query = req.url:match("^([^?]*)%??(.*)")
    req.query = (query and #query) and parseQuery(query) or {}
    if req.method=='POST' then
      --p(req) --TODO
    end
    --parse post body
    if req.body then
      local contenttype
      for _,v in pairs(req.headers) do
        if v[1] == 'Content-Type' then
          contenttype = v[2]
          break
        end
      end
      if contenttype and contenttype:find('multipart/form-data',1,true)==1 then
        req.post = multipart(req.body,contenttype)
      else
        req.post = parseQuery(req.body)
      end
    end
    --parse params match with :name
    local params
    if path then
      params = path(pathname)
      if not params then return go() end
    end
    req.params = params or {}
    return handler(req, res, go)
  end)
  return self
end

function HTTPD:start(port, host, callback)
  port = port or self.options.port or (self.options.secure and 4433 or 8080)
  host = host or self.options.host or '0.0.0.0'
  assert(#self.handlers>0,'not set any service handler')
  self.server:listen(port, host, callback)
  return self
end

------------------------------------------------------------------------------
return HTTPD
