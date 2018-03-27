-- @Date    : 2016-05-13 16:44:21
-- @Author  : MiaoLian (mlian@ulucu.com)
-- @Version : 1.0
-- @Description : 

local ngx_timer = ngx.timer.at

local log = { _version = "0.1" }

log.level = "trace"

local modes = {
  { name = "trace" },
  { name = "debug"},
  { name = "info"},
  { name = "warn"},
  { name = "error"},
  { name = "fatal"}
}


local levels = {}
for i, v in ipairs(modes) do
  levels[v.name] = i
end

local round = function(x, increment)
    increment = increment or 1
    x = x / increment
    return (x > 0 and math.floor(x + .5) or math.ceil(x - .5)) * increment
end

local _tostring = function(...)
    local t = {}
    for i = 1, select('#', ...) do
        local x = select(i, ...)
        if type(x) == "number" then
            x = round(x, .01)
        end
        t[#t + 1] = tostring(x)
    end
    return table.concat(t, " ")
end

local function write_log(premature,outfile,msg,nameupper)
    if premature then
        return 
    end
    local fd,err= io.open(outfile, "a")
    if not fd then
        local err_info = string.format("[file-log] failed to open the file: %s", err or "nil")
        ngx.log(ngx.ERR, "[file-log] failed to open the file: ", err_info)
        return
    end
    local str = string.format("[%-6s%s] : %s\n",nameupper, ngx.localtime(), msg)
    fd:write(str)
    fd:close()
end

function log:new(file_path)
    local instance = {
        outfile = file_path or "/tmp/default_unknow.log"
    }

    for i, x in ipairs(modes) do
        local nameupper = x.name:upper()
        log[x.name] = function(self,...)
            -- Return early if we're below the log level
            if i < levels[log.level] then
                return
            end
            local msg = _tostring(...)
            -- Output to log file
            if self.outfile then
                ngx_timer(0, write_log, self.outfile, msg,nameupper)
            end
        end
    end
    return setmetatable(instance, {__index = self})
end

return log
