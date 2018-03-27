-- @Author: mlian
-- @Date:   2016-08-05 17:54:45
-- @Last Modified by:   mlian
-- @Last Modified time: 2016-08-10 16:07:12

local redis_lib = require("application.lib.sim_redis_lib")
local cjson_lib = require("application.lib.sim_json_lib")

local cjson = cjson_lib:new(true)

local _M = { _VERSION = '0.01' }

local mt = { __index = _M }

local function to_str(tab_info)
	return cjson:json_encode(tab_info) or ""
end

function _M.get_headers(self)
	return {}
end

function _M.get_message(self,task)
	local result = {}
	local str_body = to_str(task)
	result["body"] = ngx.encode_base64(str_body)
	result["headers"] = self.get_headers()
	result["content-type"] = self.content_type
	result["content-encoding"] = self.content_encoding
	return result
end

-- The delivery_mode changes how the messages to this queue are delivered. A value of 1 means that the message will not be written to disk, and a value of 2 (default) means that the message can be written to disk
function _M.get_delivery_mode(self,params)
	if params.delivery_mode then
		return params.delivery_mode
	end
	-- 默认
	return 2
end

function _M.post_to_exchange(self,task,tab_details)
	local message = self:get_message(task)

	local delivery_info = {
		priority = 0,
		routing_key = tab_details.routing_key,
		exchange = tab_details.exchange
	}

	local properties = {
		body_encoding = "base64",
		-- queue_or_url
		reply_to = tab_details.reply_to,
		delivery_mode = self:get_delivery_mode(tab_details),
		delivery_tag = task.id,
		delivery_info = delivery_info
	}

	message.properties = properties

	local ok,err = self.redis:lpush(tab_details.queue,to_str(message))
	if not ok then
		if err then
			return nil,err
		end
		return nil,"redis err"
	end

	return task.id,nil
end

function _M.is_result(self,task_key,config)
	if not self.redis_back then
		self.redis_back = redis_lib:new(config)
	end
	local ok,err = self.redis_back:exists(tostring(task_key))
	if not ok then
		if err then return nil,err end
		return nil,"redis exits err:"..tostring(task_key) 
	end
	return ok,nil
end

function _M.get_result(self,task_key)
	local ok,err = self.redis_back:get(tostring(task_key))
	if not ok then
		if err then return nil,err end
		return nil,"redis exits err:"..tostring(task_key) 
	end
	return ok,nil
end

function _M.remove_result(self,task_key)
	local ok,err = self.redis_back:del(tostring(task_key))
	if not ok then
		if err then return nil,err end
		return nil,"redis exits err:"..tostring(task_key) 
	end
	return ok,nil
end

function _M.new(self,config)
	self.redis = redis_lib:new(config)
	self.redis_back = nil
	self.content_type = "application/json"
	self.content_encoding = "UTF-8"
	self.immediate = false
	return setmetatable({}, mt)
end

return _M