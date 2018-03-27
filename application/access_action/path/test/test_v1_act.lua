-- @Date    : 2016-03-04 11:10:18
-- @Author  : MiaoLian (mlian@ulucu.com)
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
			message = "failed"
		}

	--ngx.say(self.request.uri)
	self.response:setBody(res)
	self.response:send_HTTP_FORBIDDEN()
end

return test_act