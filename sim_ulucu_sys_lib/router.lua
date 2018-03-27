-- @Date    : 2016-01-27 10:40:59
-- @Author  : Miao Lian (miaolian19890421@163.com)
-- @Version : 1.0
-- @Description : 

local strlower = string.lower
local ngx_re_gmatch = ngx.re.gmatch

local _M = {_VERSION = "0.01"}

function _M.new(self,request_uri)
	local instance = {
		req_uri = request_uri
	}
	setmetatable(instance, {__index = self})
	return instance
end

function _M.route_match(self)
	local uri = self.req_uri
    local match = {}
    local tmp = 1
    if uri == '/' then
        return 'index', 'index'
    end
    for v in ngx_re_gmatch(uri , '/([A-Za-z0-9_]+)', "o") do
        match[tmp] = v[1]
        tmp = tmp +1
    end
    if #match == 1 then
        return match[1], 'index'
    else
        return table.concat(match, '.', 1, #match - 1), strlower(match[#match])
    end
end

return _M