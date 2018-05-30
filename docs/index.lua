p('req',req)
p('res',res)

req.logger.warning('this is warn')

res.body=[[
<!DOCTYPE html>
<html>
<head>
<title>SB Admin 2</title>
</head>
<body>
Go to <a href="index.html">index.html</a>
</body>
</html>
]]
