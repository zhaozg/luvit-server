--[[lit-meta
  name = "creationix/weblit-static"
  version = "2.0.0"
  dependencies = {
    "creationix/mime@2.0.0"
  }
  description = "A weblit middleware for serving static files from disk or bundle."
  tags = {"weblit", "middleware", "static"}
  license = "MIT"
  author = { name = "Tim Caswell" }
  homepage = "https://github.com/creationix/weblit/blob/master/libs/weblit-auto-headers.lua"
]]

local getType = require("./mime").getType
local jsonStringify = require('json').stringify
local wfs = require('./weblit-fs')

local openssl = require('openssl')
local function sha1(data)
  return openssl.digest.digest('sha1',data)
end

return function (rootPath, options)

  local fs = wfs(rootPath)

  return function (req, res, go)
    if req.method ~= "GET" then return go() end
    local path = (req.params and req.params.path) or req.url
    path = path:match("^[^?#]*")
    if path:byte(1) == 47 then
      path = path:sub(2)
    end

    local stat = fs.stat(path)
    if not stat then return go() end

    local function renderFile()
      local body = assert(fs.readFile(path))
      res.statusCode = 200
      res.headers["Content-Type"] = getType(path)
      res.headers["ETag"] = '"' .. sha1(body) .. '"'
      res.body = body
      return true
    end

    local function renderDirectory()
      if req.url:byte(-1) ~= 47 then
        res.statusCode = 301
        res.headers.Location = req.url .. '/'
        return true
      end
      local files = {}
      local entries = {}
      for entry in fs.scandir(path) do
        entries[#entries+1] = entry
      end

      local function index(entries,index,redirect)
        for i=1,#entries do
          local entry = entries[i]
          if entry.type=='file' then
            if entry.name == index then
              if redirect then
                res.statusCode = 302
                res.headers.Location =
                  string.format('//%s%s%s',req.headers.host, req.url,index)
                return true
              end
            end
          end
        end
      end

      if options.index then
        for i=1,#options.index do
          if (index(entries, options.index[i], true)) then
            return
          end
        end
      end

      for i=1,#entries do
        local entry = entries[i]
        if entry.name == "index.html" and entry.type == "file" then
          path = (#path > 0 and path .. "/" or "") .. "index.html"
          return renderFile()
        end
        files[#files + 1] = entry
        if req.headers.host then
          entry.url = "http://" .. req.headers.host .. req.url .. entry.name
        else
          entry.url = "http://" .. req.socket:address().ip .. req.url .. entry.name
        end
      end
      local body = jsonStringify(files) .. "\n"
      res.statusCode = 200
      res.headers["Content-Type"] = "application/json"
      res.body = body
      return true
    end

    if stat.type == "directory" then
      return renderDirectory()
    elseif stat.type == "file" then
      if req.url:byte(-1) == 47 then
        res.statusCode = 301
        res.headers.Location = req.url:match("^(.*[^/])/+$")
        return true
      end
      return renderFile()
    end
  end
end
