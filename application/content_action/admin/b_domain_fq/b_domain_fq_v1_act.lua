-- @Date    : 2016-02-17 09:41:54
-- @Author  : Miao Lian (miaolian19890421@163.com)
-- @Version : 1.0
-- @Description : 

local business_model = require("model.db_ulu_business.tb_business_model")

local ngx_thread_spawn = ngx.thread.spawn
local ngx_thread_wait = ngx.thread.wait
local ngx_log = ngx.log
local ERR_LEVEL = ngx.ERR

local enterprise_domain_fuzzy_query = {}

local function check_necessaryinfo(param_value)
	local param_value = param_value or {}
	if not next(param_value) then
		return false,"necessary infomation b_domain is missing"
	end
	if not param_value.b_domain then
		return false,"necessary infomation b_domain is missing"
	end
	return true,nil
end

local function swap_work(id,domain,rep)
	local data_sta,data_err = business_model:fuzzy_search(id,domain)
	if not data_sta then
		ngx_log(ERR_LEVEL,data_err)
		return 
	end
	for _,value in pairs(data_err) do
		table.insert(rep,value)
	end 
	return 
end

function enterprise_domain_fuzzy_query:response_info(tab_resp)
	self.response:setBody(tab_resp)
	self.response:send_HTTP_OK()
end

function enterprise_domain_fuzzy_query:b_domain_fq()
	-- 默认结果集
	local tab_resp = {
				code = 0,
				data = {},
				message = "success"				
			}
	-- 获取参数
	local param_value = self.request:getParams()
	-- 检查参数
	local chk_sta,chk_err = check_necessaryinfo(param_value)
	if not chk_sta then	
		tab_resp.code = 12001
		tab_resp.message = chk_err 
		self:response_info(tab_resp)
	end

	local thread,rep = {},{}
	for i=1,10 do
		local spawn_co = ngx.thread.spawn(swap_work,i,param_value.b_domain,rep)			
		table.insert(thread, spawn_co)
	end
	
    for i=1, #thread do
	    local co = thread[i]
	    local status = coroutine.status(co)
	    if status ~= "dead" then
	    	local wait_status,wait_err = ngx_thread_wait(co)
	    	if not wait_status then
	    		ngx.say(wait_status)
	    		ngx_log(ERR_LEVEL,string.format("wait thread[%d] failed:%s",i,wait_err))
	      	end
    	else
    		ngx_log(ERR_LEVEL, string.format("wait dis thread[%d] failed:coroutine dead",i))
    	end
	end
	tab_resp.data = rep
	self.response:setBody(tab_resp)
	self.response:send_HTTP_OK()
end

return enterprise_domain_fuzzy_query