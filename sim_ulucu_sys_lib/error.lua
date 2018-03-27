-- @Date    : 2016-01-27 10:43:48
-- @Author  : Miao Lian (miaolian19890421@163.com)
-- @Version : 1.0
-- @Description : 

local common_lib = require 'sim_ulucu_sys_lib.units.sim_common_lib'

local error = error
local pairs = pairs
local setmetatable = setmetatable

local _M = {_VERSION = "0.01"}

local function init_errors()
    local errors = common_lib.try_require('application.config.errors', {})
    errors[100] = { status = 500, message = "Ulucu Inner Lpcall Err." }
    errors[102] = { status = 404, message = "Application Err." }
    errors[103] = { status = 404, message = "Action Err." }
    errors[201] = { status = 500, message = "Routing Err." }
    errors[300] = { status = 500, message = "Unknow Err." }
    return errors
end

_M.list = init_errors()

function _M.new(self,custom_attrs,code)
    local err = _M.list[code]
    if err == nil then 
    	err = self.list[300]
    end

    local body = {
        code = code,
        msg = err.message,
        data = nil
    }

    if custom_attrs and type(custom_attrs) == "string" then
    	body.msg = body.msg..custom_attrs
    end

    local instance = {
        status = err.status,
        body = body
    }
    setmetatable(instance, {__index = self})
    return instance
end

return _M