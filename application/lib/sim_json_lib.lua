-- @Date    : 2015-12-09 10:22:54
-- @Author  : Miao Lian (miaolian19890421@163.com)
-- @Version : 1.0
-- @Description : 

local c_json = require "cjson"

local _M = { _VERSION = '0.01' }
local mt = { __index = _M }

function _M.json_decode( self,str )
    local json_value = nil
    pcall(function (str) json_value = c_json.decode(str) end, str)
    return json_value
end


function _M.json_encode(self, str)
    local json_value = nil
    if c_json.encode_empty_table_as_object then
        c_json.encode_empty_table_as_object(self.empty_table_as_object or false) 
    end
    c_json.encode_sparse_array(true)
    pcall(function (str) json_value = c_json.encode(str) end, str)
    return json_value
end


function _M.new(self,empty_table_as_object)
    local empty_table_as = empty_table_as_object or false
	return setmetatable({empty_table_as_object = empty_table_as}, mt)
end


return 	_M