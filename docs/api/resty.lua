local json = require'json'
local M = {}

function M.GET(req,res)
  local params = req.params or {method='GET'}
  res.body = json.encode(params)
  res.statusCode = 200
end

function M.POST(req,res)
  local params = req.params or {method='POST'}
  res.body = json.encode(params)
  res.statusCode = 200
end

return M

