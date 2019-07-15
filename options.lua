include = function(s)
  return(s)
end

return {
  root = './docs',
  port = 80,
  haml = {
    cached = true
  },
  static = {
    cached = true,
    index = {"index.haml","index.html"}
  },
}
