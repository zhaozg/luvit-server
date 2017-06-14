local http = require('http')
local json = require('json')
local uv = require('uv')

local R = {}
local caches = {}

function R.get(url,callback,query)
    local append = string.find(url,'?')
    if type(query)=='string' then
        url = url..(append and '&' or '?')..query
    elseif type(query)=='table' then
        local arg = {}
        for k,v in pairs(query) do
            arg[#arg+1] = string.format('%s=%s',k,v)
        end
        url = url..(append and '&' or '?')..table.concat(arg)
    end
    local req
    local dat = {}
    req = http.request(url, function(res)
      res:on('data', function (chunk)
        dat[#dat+1] = chunk
      end)
      res:on("end", function ()
        local _
        _, dat = pcall(json.decode, table.concat(dat))
        callback(dat, res.statusCode)
      end)
    end)
    req:done()
end

function R.getSync(url,query)
    local dat, code
    R.get(url, function(arg1,arg2)
        dat,code = arg1,arg2
        uv.stop()
    end, query)
    uv.run()
    return dat,code
end

function R.getObject(url, query)
    if query then
        return R.getSync(url, query)
    end
    if caches[url] then return caches[url] end
    local obj, code = R.getSync(url)
    if obj and tostring(code)=='200' then
        caches[url] = obj
    end
    return obj,code
end

return R
