-- @Date    : 2016-06-12 14:17:08
-- @Author  : MiaoLian (mlian@ulucu.com)
-- @Version : 1.0
-- @Description : 
local template = require "sim_ulucu_sys_lib.resty.template"


local error = error
local pairs = pairs
local setmetatable = setmetatable
local ngx_var = ngx.var

local View = {}

function View:new(view_config)
    ngx_var.template_root = view_config.template_root
    ngx_var.template_location = view_config.template_location
    local instance = {
        view_config = view_config,
        -- __call = self:init
    }
    setmetatable(instance, {__index = self})
    return instance
end

-- function View:init(controller_name, action)
--     self.view_handle = template.new(controller_name .. '/' .. action .. self.view_config.suffix)
--     self.controller_name = controller_name
--     self.action = action
-- end

-- function View:assign(key, value)
--     if type(key) == 'string' then
--         self.view_handle[key] = value
--     elseif type(key) == 'table' and value == nil then
--         for k,v in pairs(key) do
--             self.view_handle[k] = v
--         end
--     end
-- end

-- function View:caching(cache)
--     local cache = cache or true
--     template.caching(cache)
-- end

-- function View:display()
--     return tostring(self.view_handle)
-- end

-- function View:getScriptPath()
--     return ngx.var.template_root
-- end

local function view_handle_params(view_handle, params)
    return view_handle(params)
end

function View:render(view_tpl, params)
    local view_handle = template.compile(view_tpl)
    local ok, body_or_error = pcall(view_handle_params, view_handle, params)
    if ok then
        return body_or_error
    else
        error(body_or_error)
    end
end

-- function View:setScriptPath(scriptpath)
--     if scriptpath ~= nil then ngx.var.template_root = scriptpath end
-- end

return View