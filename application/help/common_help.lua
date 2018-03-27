-- @Date    : 2016-04-19 17:21:31
-- @Author  : MiaoLian (mlian@ulucu.com)
-- @Version : 1.0
-- @Description : 

local ngx_re_match = ngx.re.match

local lib_printable = require("application.lib.sim_printable_lib")

local _M = { _VERSION = '0.01' }
local mt = { __index = _M }

function _M.check_number(self,...)
	local num_arg = {...}
	if next(num_arg) == nil then
        return false
    end
	local num
	for _,value in pairs(num_arg) do
		if type(value) == "table" then
			for _,value_value in pairs(value) do
				num = tonumber(value_value)
				if nil == num then
					return false
				end
			end
		else
			num = tonumber(value)
			if nil == num then 
				return false
			end
		end
	end
	return true
end

function _M.check_ipinfo(self,ip)
	if not ip then
		return false,"nil info"
	end

	local match,match_err = ngx_re_match(ip, [[^((?:(?:25[0-5]|2[0-4]\d|((1\d{2})|([1-9]?\d)))\.){3}(?:25[0-5]|2[0-4]\d|((1\d{2})|([1-9]?\d))))$]],"jo")
	if not match or not match[0] then	
		if match_err then
			return false,match_err
		end
		return false,"wrong ip format"
	end
	return true,nil
end

function _M.print_r(self,para_tab)
	local type_tab = type(para_tab)
	if type_tab == "table" then
	    setmetatable(para_tab, lib_printable)
   		ngx.say(tostring(para_tab))
	elseif type_tab == "string" then
		ngx.say(para_tab)
	elseif type_tab == "nil" then
		ngx.say("nil")
	else
		ngx.say(tostring(para_tab))
	end
end

function _M.say_r(self,ar,sp)
    if sp == nil then
        sp="";
    end
    if type(ar)=="table" then
        local k,v;
        ngx.say("{\n");
        for k,v in pairs(ar) do
            if type(v)=="table" then
                ngx.print(sp,"　",k,"=");
                self:say_r(v,sp.."　");
            else
                ngx.say(sp,"　",k,"=\"",v,"\",\n");
            end
        end
        ngx.say(sp,"}\n");
    else
        ngx.say(sp,ar,"\n");
    end
end

-- 参数:待分割的字符串,分割字符
-- 返回:子串表.(含有空串)
function _M.split(self, str, split_char)
    local sub_str_tab = {};
    if split_char == "" then
    	return sub_str_tab
    end
    while (true) do
        local pos = string.find(str, split_char, 1, true);
        if (not pos) then
            sub_str_tab[#sub_str_tab + 1] = str;
            break;
        end
        local sub_str = string.sub(str, 1, pos - 1);
        sub_str_tab[#sub_str_tab + 1] = sub_str;
        str = string.sub(str, pos + 1, #str);
    end

    return sub_str_tab;
end

function _M.get_keys(self,tab_info)
	local tab_keys = {}
	local tab_info = tab_info or {}
	if type(tab_info) ~= "table" or not next(tab_info) then
		return tab_keys
	end
	for key,_ in pairs(tab_info) do
		if key then
			table.insert(tab_keys,key)
		end
	end
	return tab_keys 
end

function _M.get_uniq_values(self,tab_info)
	local tab_keys = {}
	local tab_info = tab_info or {}
	if type(tab_info) ~= "table" or not next(tab_info) then
		return tab_keys
	end
	for _,value in pairs(tab_info) do
		if value then
			tab_keys[value] = true
		end
	end
	return self:get_keys(tab_keys) 
end

function _M.is_array(self,t)
    if type(t) ~= "table" then return false end
    local i = 0
    for _,_ in pairs(t) do
        i = i + 1
        if t[i] == nil and t[tostring(i)] == nil then return false end
    end
    return true
end


function _M.merge_table(self,tab_a,tab_b)
	if type(tab_b) ~= "table" then return tab_a end
	for k,v in pairs(tab_b) do
		tab_a[k] = v
	end
	return tab_a
end

function _M.new(self)
	return setmetatable({}, mt)
end


return 	_M