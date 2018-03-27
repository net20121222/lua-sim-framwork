-- @Date    : 2016-01-27 10:39:43
-- @Author  : Miao Lian (miaolian19890421@163.com)
-- @Version : 1.0
-- @Description : 

local Error_lib = require("sim_ulucu_sys_lib.error")
local Request_lib = require("sim_ulucu_sys_lib.request")
local Response_lib = require("sim_ulucu_sys_lib.response")
local Router_lib = require("sim_ulucu_sys_lib.router")
local View_lib = require("sim_ulucu_sys_lib.view.rtpl")

local response = Response_lib:new()

local pairs = pairs
local pcall = pcall
local require = require
local setmetatable = setmetatable

local _M = {_VERSION = "0.01"}

local function require_controller(controller_name)
    return require(controller_name)
end

local function require_view(view_conf)
    return View_lib:new(view_conf)
end

local function require_request()
    return Request_lib:new()
end

local function require_response()
    return Response_lib:new()
end

local function require_router(request_uri)
    return Router_lib:new(request_uri)
end

local function new_bootstrap_instance(str_bootstrap, response,request)
    return require(str_bootstrap):new(response,request)
end

function _M.call_action(self,matched_controller_module)
	local action_name = self.request.action_name
	if type(matched_controller_module) ~= "table" then
		local err = {
				code = 102,
				msg = action_name.." action name is not found."
			}
        self:raise_sys_error(err)
	end
	if not matched_controller_module[action_name] or type(matched_controller_module[action_name]) ~= "function" then
        local err = {
                code = 102,
                msg = action_name.." action name is not found."
            }
        local err = Error_lib:new(err.msg,err.code)
        response:setBody(err.body)
        response:send_HTTP_NOT_FOUND()
	end
    --ngx.say(self.request.uri)
    setmetatable(matched_controller_module, {__index = self})
    -- matched_controller_module[action_name](matched_controller_module)
    local result,err = pcall(matched_controller_module[action_name],matched_controller_module)
    if not result then
        local err = {
            code = 103,
            msg = action_name..err
        }
        self:raise_sys_error(err)
    end
end

function _M.get_pro_config(self,pro_config)
	local tab_pro_config = pro_config or {}
	if not tab_pro_config.action_path_name or not tab_pro_config.action_suffix then
		self:raise_sys_error(
				[[Sys Err: Please set app name and app root in config/project.lua like:
                    App_proj.action_path_name = 'action'
                    App_proj.action_suffix = "_act"]]
			)
	end
    if tab_pro_config.enable_view then
        if not ngx.var.template_root or not ngx.var.template_location then
            self:raise_sys_error(
                [[Sys Err: variable "template_root" not found for writing;
                    maybe it is a built-in variable that is not changeable or you forgot to use set $template_root" '';set $template_location" '']]
            )
        end
        if not tab_pro_config.view.template_root or not tab_pro_config.view.template_location then
            self:raise_sys_error(
                [[Sys Err: Please set templete_root in config/project.lua like:
                    templete_root = 'application/views/'
                    templete_location = '/templates'
                ]]
            ) 
        end
    end
	self.config = tab_pro_config
end

function _M.raise_sys_error(self,err)
    if type(err) == 'table' then
        local err = Error_lib:new(err.msg,err.code)
        response:setBody(err.body)
        response:send_HTTP_INTERNAL_SERVER_ERROR()
    else
        local err = Error_lib:new(tostring(err))
        response:setBody(err.body)
        response:send_HTTP_INTERNAL_SERVER_ERROR()
    end
end

function _M.new(self,pro_config)
	self:get_pro_config(pro_config)
    -- ngx.flush()
    -- ngx.say(pro_config.action_path_name)
    self.response = self:lpcall(require_response)
    self.request = self:lpcall(require_request)
    self.router = self:lpcall(require_router,self.request.uri)
    self.plugins = {}
    local instance = {}
    setmetatable(instance, {__index = self})
    return instance
end

function _M.get_controller_action(self)
    local controller_path = self.config.action_path_name..self.request.controller_name.."."..self.request.action_name.."."
    if self.request.action_name == "index" then
        -- local err = {
        --     code = 201,
        --     msg = self.request.action_name.." not found!"
        -- }
        -- local err = Error_lib:new(err.msg,err.code)
        -- response:setBody(err.body)
        -- response:send_HTTP_NOT_FOUND()
        self.request.action_name = self.request.controller_name
        controller_path = self.config.action_path_name..self.request.action_name.."."
    end
    local version = self.request.params.v or 1
	local action_api = self.request.action_name.."_v"..version..self.config.action_suffix
	local action_apth_name = controller_path..action_api
    return action_apth_name
end

function _M.run(self)
    self:runPlugins('routerStartup')
	self:run_route()
    self:runPlugins('routerShutdown')
	local matched_controller_action = self:get_controller_action()
	local matched_controller_module = self:lpcall(require_controller, matched_controller_action)
    if self.config.enable_view then
        self.view = self:lpcall(require_view, self.config.view)
    end
    self:call_action(matched_controller_module)
end

function _M.runPlugins(self,hook)
    for _, plugin in ipairs(self.plugins) do
        if plugin[hook] ~= nil then
            plugin[hook](plugin)
        end
    end
end

function _M.registerPlugin(self)
    if self.config["plug"] ~= nil then
        for _,plugin in pairs(self.config["plug"]) do
            local _plugin = require(plugin):new(self.request, self.response)
            table.insert(self.plugins,_plugin)
        end
    end
end

function _M.lpcall(self,...)
    local ok, rs_or_error = pcall( ... )
    if ok then
        return rs_or_error
    else
        local err
        if self.config.debug then
        	err = {
        			code = 100,
        			msg = rs_or_error
        		}
        else
            err = {
                    code = 102,
                    msg = "not exist"
                }
        end
        self:raise_sys_error(err)
    end
end

function _M.run_route(self)
	local ok, controller_name_or_error, action= pcall(function(router_instance) return router_instance:route_match() end, self.router)
    if ok and controller_name_or_error then
        self.request.controller_name = controller_name_or_error
        self.request.action_name = action
    else
		local err = {
			code = 201,
			msg = controller_name_or_error
		}
        self:raise_sys_error(err)
    end
end
return _M