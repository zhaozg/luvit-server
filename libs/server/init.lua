return {
  name = "zhaozg/server",
  version = "0.0.3",
  homepage = "https://github.com/zhaozg/luvit-server",
  description = "general http server for luvit.",
  tags = {"httpd", "server", "luvit"},
  author = { name = "George Zhao" },
  license = "MIT",
  files = {
    "**.lua",
  },
  dependencies = {
    "zhaozg/haml@0.3.3",
    "zhaozg/http-cookie@0.1.3"
  }
}
