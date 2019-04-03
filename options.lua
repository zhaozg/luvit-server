include = function(s)
  return(s)
end

return {
  root = [[./docs]],
  port = 80,
  haml = {
    cached = false
  },
  static = {
    cached = false,
    index = {"index.haml","index.html"}
  },
}
