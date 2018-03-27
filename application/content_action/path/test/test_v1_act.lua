-- @Date    : 2016-02-01 10:31:04
-- @Author  : Miao Lian (miaolian19890421@163.com)
-- @Version : 1.0
-- @Description : 

-- local a = require("application.lib.sim_test_lib")

local test_act = {}


function test_act:test()
	local uri  = self.request.uri
	local args = self.request:getParams()
	local res = {
			code = 1,
			data = "hello word!",
			message = "sucess"
		}

	--ngx.say(self.request.uri)
	-- self.response:send_json_ok(res)
	
	local string_a = self.view:render("index.html",{
  title   = "Testing lua-resty-template",
  message = "Hello, World!",
  names   = { "James", "Jack", "Anne" },
  jquery  = '<script src="js/jquery.min.js"></script>' 
})
	self.response:send_html_ok(string_a)
end

return test_act

