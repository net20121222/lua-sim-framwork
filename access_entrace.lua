-- @Date    : 2016-03-04 13:23:32
-- @Author  : MiaoLian (mlian@ulucu.com)
-- @Version : 1.0
-- @Description : 

local config = require('application.config.access_project')
local status,app = pcall(function(config) return require('sim_ulucu_sys_lib.application'):new(config) end,config)
if not status then
	ngx.status = 500
	ngx.say(app)
	ngx.exit(ngx.OK)
else
	app:registerPlugin()
	app:run()
end