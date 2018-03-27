-- @Author: mlian
-- @Date:   2016-08-03 17:03:32
-- @Last Modified by:   mlian
-- @Last Modified time: 2016-08-11 10:01:39

local redis_pro_lib = require("application.lib.resty.celery.redis_pro")
local common_lib = require("application.help.common_help")
local uuid_lib = require("application.lib.resty.uuid")
local cjson_lib = require("application.lib.sim_json_lib")

local common_help = common_lib:new()
local cjson = cjson_lib:new()

local _M = { _VERSION = '0.01' }

local mt = { __index = _M }

local str_lower = string.lower


local function get_broker_type(broker_url)
	local type_broke,err = ngx.re.match(broker_url,"^([a-zA-Z]*)://(.*)","jo")

	if not type_broke then
		if err then
			return nil,"bad brokre:"..err
		end
		return nil,"bad brokre"
	end
	return type_broke,nil
end

-- 5036a2a1929e47fc:Z7sLdlo0B9di@172.30.60.10:6379/2
local function parse_redis_url(redis_broke)
	local m,err = ngx.re.match(redis_broke,[[(?:([\w:]+)@)([\w.-]+)(?::(\d+))/(\d+)]],"jo")
	if not m then
		if err then
			return nil,"bad redis_url:"..err
		end
		return nil,"bad redis_url"
	end
	return m,nil
end 

local function get_back_config(broker_url)
	local broker_info,broker_sta = get_broker_type(broker_url)
	if not broker_info then
		ngx.log(ngx.ERR,broker_sta)
		return nil,"unknow back broker"
	end
	local bro_type,bro_info = unpack(broker_info)
	local broker_type = str_lower(bro_type)
	-- 设置redis/amqp连接信息
	if broker_type == "redis" then
		local redis_config,redis_sta = parse_redis_url(bro_info)
		if not redis_config then
			ngx.log(ngx.ERR,redis_sta)
			return nil,"unknow back broker info"
		else
			local auth,domain,port,database = unpack(redis_config)
			local redis_cof = {
				host = domain,
				port = port,
				auth = auth,
				database = database
			}
			return redis_cof,nil
		end
	elseif broker_type == "amqp" then
		ngx.log(ngx.ERR,"back broker not support amqp")
	end
	return nil,"unknow back broker"
end

function _M.default_deatails(self)
	local tab_details = {}
	tab_details.exchange = self.EXCHANGE
	tab_details.routing_key = self.ROUTING_KEY
	tab_details.queue = self.QUEUE
	tab_details.delivery_mode = self.delivery_mode
	tab_details.reply_to = self.reply_to
	return tab_details
	-- result_expire
end

function _M.post_task(self,task,args,kwargs,task_args)
	if not self.broker then
		return nil,"broker not support"
	end
	local args_status = common_help:is_array(args)
	if not args_status then
		return nil,"args must be array"
	end

	local task_id = uuid_lib.generate()

	local tab_task = {
		id = task_id,
		task = task,
		args = args,
		kwargs = kwargs or {}
	}
	tab_task = common_help:merge_table(tab_task,task_args)

	-- local str_task = cjson:json_encode(tab_task)
	if self.broker_type == "redis" then
		local tab_details = self:default_deatails()
		return self:redis_broker(tab_task,tab_details)
	else
		return nil,"only support redis"
	end

end

function _M.get_response_back_key(self,task_id)
	return string.format("%s%s",self.celery_result_prefix,tostring(task_id))
end

function _M.get_response_back(self,task_id,time,remove_key)
	local response_key = self:get_response_back_key(task_id)
	local time_out = time or self.time_out
	local num_max = tonumber(time_out)/0.05
	while num_max > 0 do
		-- ngx.sleep(0.05)
		local sta,err = self.broker:is_result(response_key,self.back_result)
		if not sta then
			ngx.log(ngx.ERR,err)
			return nil,err
		end
		if tonumber(sta) ~= 1 then
			ngx.sleep(0.05)
			num_max = num_max -1 
		else
			if remove_key then self.broker:get_result(response_key) end
			return self.broker:get_result(response_key),nil
		end
	end
	return nil,"out time"
end

function _M.redis_broker(self,tab_task,tab_details)
	return self.broker:post_to_exchange(tab_task,tab_details)
end

function _M.set_routing_key(self,routing_key)
	if routing_key then
		self.ROUTING_KEY = routing_key
	end
end

function _M.set_exchange_name(self,exchange_name)
	if exchange_name then
		self.EXCHANGE = exchange_name
	end
end

function _M.set_queue(self,queue)
	if queue then	
		self.QUEUE = queue
		self.EXCHANGE = queue
		self.ROUTING_KEY = queue
	end
end

function _M.set_delivery_mode(self,delivery_mode)
	if delivery_mode then
		self.delivery_mode = tonumber(delivery_mode) or 2
	end
end

function _M.set_reply_to(self,queue_or_url)
	if queue_or_url then
		self.reply_to = queue_or_url
	end
end

function _M.new(self,config)
	local opt_config = config or {}
	-- 协议url
	self.BROKER_URL = opt_config.BROKER_URL or "redis://"
	self.CELERY_RESULT_BACKEND = opt_config.CELERY_RESULT_BACKEND or "redis://"
	-- 默认queue
	self.QUEUE = opt_config.DEFAULT_QUEUE or "celery"
	-- 默认exchange
	self.EXCHANGE = opt_config.DEFAULT_EXCHANGE or "celery"
	-- 默认exchange type
	self.EXCHANGE_TYPE = opt_config.DEFAULT_EXCHANGE_TYPE or "direct"
	-- 默认routeing key
	self.ROUTING_KEY = opt_config.DEFAULT_ROUTING_KEY or "celery"

	self.delivery_mode = opt_config.DELIVERY_TYPE or 2
	self.reply_to = opt_config.DEFAULT_QUEUE or "celery"
	-- self.RESULT_EXCHANGE = config.RESULT_EXCHANGE or 'celeryresults'
	-- self.TASK_RESULT_EXPIRES = config.TASK_RESULT_EXPIRES * 1000 or 86400000
	-- self.TASK_RESULT_DURABLE = config.TASK_RESULT_EXPIRES or true
	-- self.BROKER_OPTIONS = config.BROKER_OPTIONS or {}

	self.celery_result_prefix = "celery-task-meta-"
	-- 解析broker类型
	local broker_info,broker_sta = get_broker_type(self.BROKER_URL)
	if not broker_info then
		self.broker_type = ""
		-- self.broker = nil
		ngx.log(ngx.ERR,broker_sta)
	end
	local bro_type,bro_info = unpack(broker_info)
	self.broker_type = str_lower(bro_type)
	-- 设置redis/amqp连接信息
	if self.broker_type == "redis" then
		local redis_config,redis_sta = parse_redis_url(bro_info)
		if not redis_config then
			-- self.broker = nil
			ngx.log(ngx.ERR,redis_sta)
		else
			local auth,domain,port,database = unpack(redis_config)
			local redis_cof = {
				host = domain,
				port = port,
				auth = auth,
				database = database
			}
			self.broker = redis_pro_lib:new(redis_cof)
		end
	elseif self.broker_type == "amqp" then
		ngx.log(ngx.ERR,"not support amqp")
		-- self.broker = nil
	end
	local back_conf,back_sta = get_back_config(self.CELERY_RESULT_BACKEND)
	if not back_conf then
		ngx.log(ngx.ERR,back_sta)
	end
	self.back_result = back_conf
	self.time_out = 5
	return setmetatable({}, mt)
end

return _M