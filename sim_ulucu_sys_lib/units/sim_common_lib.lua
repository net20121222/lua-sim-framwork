-- @Date    : 2016-01-28 10:19:09
-- @Author  : Miao Lian (miaolian19890421@163.com)
-- @Version : 1.0
-- @Description : 

local assert = assert
local iopen = io.open
local pairs = pairs
local pcall = pcall
local require = require
local sfind = string.find
local sgsub = string.gsub
local smatch = string.match
local ssub = string.sub
local type = type
local append = table.insert
local concat = table.concat

local Utils = {}

local function require_module(module_name)
    return require(module_name)
end

-- try to require
function Utils.try_require(module_name, default)
    local ok, module_or_err = pcall(require_module, module_name)

    if ok == true then return module_or_err end

    if ok == false and smatch(module_or_err, "'" .. module_name .. "' not found") then
        return default
    else
        error(module_or_err)
    end
end

return Utils