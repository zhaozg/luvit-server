local Timer = require'timer'

function GET(req, res)
  Timer.setInterval(1000, function ()
    res:send('.', function() end)
  end)
  -- simple repeater
  req:on('message', function (message)
    res:send(message, function ()
    end)
  end)
end
