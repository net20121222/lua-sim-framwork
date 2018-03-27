-- @Author: mlian
-- @Date:   2016-08-03 16:11:44
-- @Last Modified by:   mlian
-- @Last Modified time: 2016-08-10 16:16:05


-- ./resty -e '
-- do
-- local cjson = require("cjson")
-- local body = {
-- 	id = "58be6529-a875-4548-aa6c-7319ffadde48",
-- 	task = "tasks.add",
-- 	args = {1,2},
-- 	kwargs = {}
-- }
-- local str_body = cjson.encode(body)
-- local base_body = ngx.encode_base64(str_body)
-- local delivery_info = {
-- 	exchange = "lua_test",
-- 	--priority = 0,
-- 	routing_key = "lua_test"
-- }
-- local properties = {
-- 	body_encoding = "base64",
-- 	reply_to = "58be6529-a875-4548-aa6c-7319ffadde48",
-- 	delivery_info = delivery_info,
-- 	delivery_mode = 2,
-- 	delivery_tag = "58be6529-a875-4548-aa6c-7319ffadde48"
-- }
-- local a = {
-- 	["body"] = base_body,
-- 	["headers"] = {},
-- 	["content-type"] = "application/json",
-- 	["content-encoding"] = "utf-8",
-- 	["properties"] = properties
-- }
-- print(cjson.encode(a))
-- end
-- '
-- eta = '2016-08-04T12:00:00'

local celery_config = {
	-- transport://userid:password@hostname:port/virtual_host
	BROKER_URL = "redis://5036a2a1929e47fc:Z7sLdlo0B9di@172.30.60.10:6379/1",
	CELERY_RESULT_BACKEND = "redis://5036a2a1929e47fc:Z7sLdlo0B9di@172.30.60.10:6379/2",
	DEFAULT_QUEUE = 'celery',
	DEFAULT_EXCHANGE = 'celery',
	DEFAULT_EXCHANGE_TYPE = 'direct',
	DEFAULT_ROUTING_KEY = 'celery',
	RESULT_EXCHANGE = 'celeryresults',
	DELIVERY_TYPE = 2
	-- one day
	-- TASK_RESULT_EXPIRES = 86400,
	-- TASK_RESULT_DURABLE = true,
	-- ROUTES = {}

}

return celery_config 