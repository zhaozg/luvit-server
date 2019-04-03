return {
  name = "zhaozg/httpd",
  version = "0.0.1",
  homepage = "https://github.com/zhaozg/luvit-server",
  description = "general http server for luvit.",
  tags = {"httpd", "server", "luvit"},
  author = { name = "George Zhao" },
  license = "MIT",
  files = {
    "**.lua",
  },
  dependencies = {
    "zhaozg/haml@0.3.9",
    "zhaozg/http-cookie@0.1.3",
    "zhaozg/server@0.0.11",
    "rphillips/logging@1.0.10"
  }
}
