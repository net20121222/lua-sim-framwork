-- @Date    : 2016-02-17 10:57:12
-- @Author  : Miao Lian (miaolian19890421@163.com)
-- @Version : 1.0
-- @Description : 

local cjson_lib = require ("application.lib.sim_json_lib")
local cjson = cjson_lib:new()

local tb_act = {
		host = "hd.inthd.xyz",
		method_proxy = "/proxy_get"
	}

local function deal_info(result)
	local errinfo = ""
	if result.status ~= ngx.HTTP_OK then
		errinfo = string.format("fuzzy search failed status:%s", result.status)
		return false,errinfo
	end
	local info = cjson:json_decode(result.body) or {}
	if next(info) == nil then
		errinfo = string.format("get error info:[%s] json decode failed", result.body)
		return false,errinfo
	end
	if tonumber(info.code) ~= 0 then
		return false,info.message
	end 
	return true,info.data
end

function tb_act:fuzzy_search(id,domain)
	local tab_para_value = {
			t_id = id,
			b_domain = domain 		
		}

	local str_para_value = ngx.encode_args(tab_para_value)
    local result = ngx.location.capture(self.method_proxy,
    									{ args = {
											pass_proxy_host = self.host,
											pass_proxy_url  = string.format("/common/fuzzy_query?%s",str_para_value)
           									}
										}
    				)
    return deal_info(result)
end

return tb_act