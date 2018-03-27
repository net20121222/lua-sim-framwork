-- @Author: mlian
-- @Date:   2016-08-08 16:01:34
-- @Last Modified by:   mlian
-- @Last Modified time: 2016-08-10 17:19:50

local celery_conf = require("application.config.celery_pro")
local celery_lib = require("application.lib.resty.celery.celery")
local cjson_lib = require("application.lib.sim_json_lib")

local cjson = cjson_lib:new(true)


local cetest_act = {}

function cetest_act:test()
	-- ngx.say("...")
	local celery = celery_lib:new(celery_conf)
	celery:set_queue("lua_test")
	local id,err = celery:post_task("tasks.add",{3,4})
	self.response:send_json_ok({code = 1,msg=id,data= {}})
	local body ,err_body = celery:get_response_back(id,2,fasle)
	ngx.say("id:"..tostring(id))
	ngx.say("err:"..tostring(err))
	ngx.say("body:"..tostring(body))
	ngx.say("err:"..tostring(err_body))
end

return cetest_act