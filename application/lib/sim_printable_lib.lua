-- @Date    : 2016-04-19 17:07:34
-- @Author  : MiaoLian (mlian@ulucu.com)
-- @Version : 1.0
-- @Description : 

local mt = {}

local function is_array(t)
    if type(t) ~= "table" then return false end
    local i = 0
    for _,_ in pairs(t) do
        i = i + 1
        if t[i] == nil and t[tostring(i)] == nil then return false end
    end
    return true
end

function mt:__tostring()
    local t = {}
    for k, v in pairs(self) do
        if type(v) == "table" then
            if is_array(v) then
                v = table.concat(v, ",")
            else
                setmetatable(v, mt)
            end
        end
        table.insert(t, (type(k) == "string" and k.." = " or "")..tostring(v))
    end
    return table.concat(t, " ")
end

function mt.__concat(a, b)
    if getmetatable(a) == mt then
        return tostring(a)..b
    else
        return a..tostring(b)
    end
end

return mt