-- @Date    : 2016-01-27 11:00:26
-- @Author  : Miao Lian (miaolian19890421@163.com)
-- @Version : 1.0
-- @Description : 

local App_proj = {
	-----------------项目目录（暂不使用）-----------------
	proj_root = "/data/sysadmin/service_deploy_data/c2-hd-webplat/new_framwork/application/",

	-----------------action目录-----------------
	action_path_name = "application.content_action.",

	-----------------action结尾名-----------------
	action_suffix = "_act",

	-----------------插件目录-----------------
	-- plug = {"application.plug.access.test"},

	-----------------调试开关-----------------
	debug = true,

	-----------------view 配置-----------------
	view = {
		-- templete root
		template_root = "application/views",
		-- templete location(templete文件走capture)
		template_location = "/templates"
	},
	enable_view = false
}

return App_proj
