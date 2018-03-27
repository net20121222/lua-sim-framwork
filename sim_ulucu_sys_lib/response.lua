-- @Date    : 2016-01-27 14:42:16
-- @Author  : Miao Lian (miaolian19890421@163.com)
-- @Version : 1.0
-- @Description : 

local setmetatable = setmetatable
local tostring = tostring
local tonumber = tonumber
local type = type
local pairs = pairs
local ngx_log = ngx.log
local ngx_say = ngx.say

local _M = {_VERSION = "0.01"}

local _M = {
	status_codes = {
		HTTP_OK = 200,
		HTTP_CREATED = 201,
		HTTP_NO_CONTENT = 204,
		HTTP_BAD_REQUEST = 400,
		HTTP_UNAUTHORIZED = 401,
		HTTP_FORBIDDEN = 403,
		HTTP_NOT_FOUND = 404,
		HTTP_METHOD_NOT_ALLOWED = 405,
		HTTP_CONFLICT = 409,
		HTTP_UNSUPPORTED_MEDIA_TYPE = 415,
		HTTP_INTERNAL_SERVER_ERROR = 500
	}
}

local response_default_content = {
	[_M.status_codes.HTTP_UNAUTHORIZED] = function(content)
		return content or "Unauthorized"
	end,
	[_M.status_codes.HTTP_NO_CONTENT] = function(content)
		return nil
	end,
	[_M.status_codes.HTTP_NOT_FOUND] = function(content)
		return content or "Not found"
	end,
	[_M.status_codes.HTTP_INTERNAL_SERVER_ERROR] = function(content)
		return content or "An unexpected error occurred"
	end,
	[_M.status_codes.HTTP_METHOD_NOT_ALLOWED] = function(content)
		return "Method not allowed"
	end
}

local function send_response(self,status_code)
	local cjson = require "sim_ulucu_sys_lib.units.sim_json_lib"
	return function(self)
		local response_body = nil
		if type(self.body) == "table" then
			response_body = cjson.json_encode(self.body)
		elseif type(self.body) == "string" then
			response_body = self.body
		else
			ngx_log(ngx.ERR, tostring(self.body))
		end
		if status_code >= _M.status_codes.HTTP_INTERNAL_SERVER_ERROR then
			if response_body then
				ngx_log(ngx.ERR, tostring(response_body))
			end
		end

		ngx.status = status_code
		ngx.header["Server"] = "ulucu/0.1"

		if type(self.headers) == "table" and next(self.headers) then
			for k, v in pairs(self.headers) do
				if v then
					ngx.header[k] = v
				end
			end
		end

		if type(response_default_content[status_code]) == "function" then
			response_body = response_default_content[status_code](response_body)
		end
		response_body = response_body or [[{"data":[],"code":0,"message":""}]]
		ngx.say(response_body)

		if self.attr and self.attr.eof == 'eof' then
			ngx.eof()
		else
			local exit_sta,ext_err = pcall(function() return ngx.exit(self.quit) end)
			if not exit_sta then
				ngx_log(ngx.ERR, ext_err)
			end
		end
	end
end

local closure_cache = {}

function _M.new(self)
    local instance = {
        headers = {},
        body = "",
        attr = {
        		eof = "noeof"
    		},
    	quit = ngx.HTTP_OK
    }
	for status_code_name, status_code in pairs(self.status_codes) do
		_M["send_"..status_code_name] = send_response(self,status_code)
	end
    setmetatable(instance, { __index = self })
    return instance
end

function _M.response(self,status_code)
	local num_status_code = tonumber(status_code)
	local res = closure_cache[num_status_code]
	if not res then
		res = send_response(self,num_status_code)
		closure_cache[num_status_code] = res
	end
	return res(self)
end

function _M.json(self,status_code)
    self:setHeader("application/json; charset=utf-8")
    return self
end

function _M.html(self,str_html)
	self:setHeader("Content-Type","text/html; charset=utf-8")
	return self
end

function _M.send_html_ok(self,body)
	self:setBody(body)
	self:html():send_HTTP_OK()
end

function _M.send_json_ok(self,body)
	self:setBody(body)
	self:json():send_HTTP_OK()
end

function _M.quit(self,status)
    self.quit = status
end

function _M.clearBody(self)
    self.body = ""
end

function _M.getBody(self)
    return self.body
end

function _M.setBody(self,body)
    if body ~= nil then self.body = body end
end

function _M.clearHeader(self,key)
	if self.headers[key] then
		self.headers[key] = nil
	end
	-- if ngx.header[key] then
	-- 	ngx.header[key] = nil
	-- end
end

function _M.clearHeaders(self)
	self.headers = {}
    -- for k,_ in pairs(ngx.header) do
    --     ngx.header[k] = nil
    -- end
end

function _M.getHeader(self,key)
    return self.headers[key]
end

function _M.getHeaders(self)
    return self.headers
end

function _M.setHeaders(self,headers)
    if headers ~=nil then
        for header,value in pairs(headers) do
            self.headers[header] = value
        end
    end
end

function _M.setHeader(self,key, value)
	if key and value then
		self.headers[key] = value
	end
end

function _M.setEof(self)
	self.eof = "eof"
end

return _M