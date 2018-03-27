-- @Date    : 2016-03-08 17:21:23
-- @Author  : MiaoLian (mlian@ulucu.com)
-- @Version : 1.0
-- @Description : 

local test = {}

function test.routerStartup(self)

end

function test.routerShutdown(self)
	local uri  = self.request.uri
	local args = self.request:getParams()
	local res = {
			code = 1,
			data = "plug test",
			message = "failed"
		}

	--ngx.say(self.request.uri)
	self.response:setBody(res)
	self.response:send_HTTP_FORBIDDEN()
end

function test.new(self,request, response)
	local instance = {
		request = request,
		response = response
	}
	setmetatable(instance, {__index = self})
	return instance
end

return test