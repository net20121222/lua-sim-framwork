-- @Date    : 2016-01-27 10:51:02
-- @Author  : Miao Lian (miaolian19890421@163.com)
-- @Version : 1.0
-- @Description : 

local config = require('application.config.content_project')
local status,app = pcall(function(config) return require('sim_ulucu_sys_lib.application'):new(config) end,config)
if not status then
	ngx.status = 500
	ngx.say(app)
	ngx.exit(ngx.OK)
else
	app:run()
end

