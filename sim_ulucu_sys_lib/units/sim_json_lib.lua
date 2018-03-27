-- @Date    : 2016-01-27 16:12:22
-- @Author  : Miao Lian (miaolian19890421@163.com)
-- @Version : 1.0
-- @Description : 

local c_json = require "cjson"

local _M = {}

function _M.json_decode(str)
    local json_value = nil
    local ok,err = pcall(function (str) json_value = c_json.decode(str) end, str)
    return json_value
end


function _M.json_encode(str,empty_table_as_object)
    local json_value = nil
    if c_json.encode_empty_table_as_object then
        c_json.encode_empty_table_as_object(empty_table_as_object or false) 
    end
    c_json.encode_sparse_array(true)
    local ok,err = pcall(function (str) json_value = c_json.encode(str) end, str)
    return json_value
end

return 	_M