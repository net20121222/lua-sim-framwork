-- @Date    : 2016-01-27 10:40:13
-- @Author  : Miao Lian (miaolian19890421@163.com)
-- @Version : 1.0
-- @Description : 

local error = error
local pairs = pairs
local setmetatable = setmetatable
local ngx_var = ngx.var
local ngx_req = ngx.req
local match = string.match

local _M = {_VERSION = "0.01"}

local function get_boundary()
    local header = ngx_var.content_type
    if not header then
        return nil
    end

    if type(header) == "table" then
        header = header[1]
    end

    local m = match(header, ";%s*boundary=\"([^\"]+)\"")
    if m then
        return m
    end

    return match(header, ";%s*boundary=([^\",;]+)")
end

function _M.new(self)
    local post_args = {}
    local boundary = get_boundary()

    if not boundary then
        ngx.req.read_body()
        post_args = ngx_req.get_post_args() or {}
    end

    local params = ngx_req.get_uri_args() or {}
    if next(post_args) then
        for k,v in pairs(post_args) do
            params[k] = v
        end
    end

    local instance = {
        uri = ngx_var.uri,
        req_uri = ngx_var.request_uri,
        req_args = ngx_var.args,
        params = params or {},
        uri_args = ngx_req.get_uri_args() or {},
        method = ngx_req.get_method(),
        headers = ngx_req.get_headers(),
        body_raw = ngx_req.get_body_data(),
        controller_name = "",
        action_name = "",
        post_args = post_args
    }
    setmetatable(instance, {__index = self})
    return instance
end

function _M.getHeader(self,key)
    if self.headers[key] ~= nil then
        return self.headers[key]
    else
        return false
    end
end

function _M.getMethod(self)
    return self.method
end

function _M.getParams(self)
    return self.params
end

function _M.getParam(self,key)
    return self.params[key]
end

return _M