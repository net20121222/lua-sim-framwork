-- @Author: mlian
-- @Date:   2016-06-30 10:58:03
-- @Last Modified by:   mlian
-- @Last Modified time: 2016-06-30 16:36:10

local test1_act = {}

local cjson_lib = require("application.lib.sim_json_lib")
local cjosn = cjson_lib:new()
local client = require ("application.lib.resty.kafka.client")
local producer = require ("application.lib.resty.kafka.producer")
local semaphore = require "ngx.semaphore"

function test1_act:test1()
	local broker_list = {
	    { host = "127.0.0.1", port = 9092 }
	}

	local key = "0"
	local message = cjosn:json_encode(self.request.uri_args)
	-- local bp = producer:new(broker_list, { producer_type = "async" })

	-- local ok, err = bp:send("test", key, message)
	-- if not ok then
	--     self.response:send_json_ok("send err:" .. err)
	-- end
	-- self.response:send_json_ok(ok)


    local p = producer:new(broker_list)

    local offset, err = p:send("test1", key, message)
    if not offset then
        self.response:send_json_ok({code = 0,data = {},msg = "send err:" .. err})
        return
    end
    self.response:send_json_ok("send success, offset: " .. tonumber(offset))
end


return test1_act