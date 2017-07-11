local pathJoin = require('luvi').path.join
local bundle = require('luvi').bundle
local uv = require('uv')

return function (root)
  local match = root:match("^bundle:/?(.*)$")
  local fs = {}

  if not match then
    local stat, err = uv.fs_stat(root)
    if stat and stat.type=='directory' then
      bundle = require 'fs'

      function fs.scandir(path)
        path = pathJoin(root, './' .. path)
        local names = bundle.readdirSync(path)
        local i = 0
        return function ()
          i = i + 1
          local name = names[i]
          if not name then return end
          local stat = bundle.statSync(pathJoin(path, name))
          stat.name = name
          return stat
        end
      end

      function fs.readFile(path)
        path = pathJoin(root, './' .. path)
        return bundle.readFileSync(path)
      end

      function fs.stat(path)
        path = pathJoin(root, './' .. path)
        return bundle.statSync(path)
      end

    else
      stat,err = bundle.stat(root)
      assert(stat, err)
      assert(stat.type=='directory','need directory but '..stat.type)

      function fs.scandir(path)
        path = pathJoin(root, './' .. path)
        local names = bundle.readdirSync(path)
        local i = 0
        return function ()
          i = i + 1
          local name = names[i]
          if not name then return end
          local stat = bundle.statSync(pathJoin(path, name))
          stat.name = name
          return stat
        end
      end

      function fs.readFile(path)
        path = pathJoin(root, './' .. path)
        return bundle.readfileSync(path)
      end

      function fs.stat(path)
        path = pathJoin(root, './' .. path)
        return bundle.statSync(path)
      end

    end
  end

  return fs
end
