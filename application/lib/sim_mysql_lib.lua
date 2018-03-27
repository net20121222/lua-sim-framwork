-- @Date    : 2016-05-03 14:57:50
-- @Author  : MiaoLian (mlian@ulucu.com)
-- @Version : 1.0
-- @Description : 

local error = error
local ipairs = ipairs
local pairs = pairs
local require = require
local tonumber = tonumber
local tconcat = table.concat
local function tappend(t, v) t[#t+1] = v end

local mysql = require "resty.mysql"

-- settings
local timeout_subsequent_ops = 1000 -- 1 sec
local max_idle_timeout = 10000 -- 10 sec
local max_packet_size = 1024 * 1024 -- 1MB


local _M = {_VERSION = "0.01"}

local function mysql_connect(options)
    -- create sql object
    local db, err = mysql:new()
    if not db then error("failed to instantiate mysql: " .. err) end
    -- set 1 second timeout for subsequent operations
    db:set_timeout(timeout_subsequent_ops)
    -- connect to db
    local db_options = {
        host = options.host,
        port = options.port,
        database = options.database,
        user = options.user,
        password = options.password,
        max_packet_size = max_packet_size
    }
    local ok, err, errno, sqlstate = db:connect(db_options)
    if not ok then error("failed to connect to mysql: " .. err .. ": " .. tostring(errno)) end
    return db
end

local function mysql_keepalive(db, options)
    -- put it into the connection pool
    local ok, err = db:set_keepalive(max_idle_timeout, options.pool)
    if not ok then error("failed to set mysql keepalive: ", err) end
end

-- execute query on db
local function db_execute(db, sql)
	local default_query = "SET NAMES utf8"
	local res, err, errno, sqlstate = db:query(default_query)
	-- if not res then error("bad mysql result: " .. err .. ": " .. errno) end
    if not res then
        return res, err, errno, sqlstate
    end
    res, err, errno, sqlstate = db:query(sql)
    -- if not res then error("bad mysql result: " .. err .. ": " .. errno) end
    if not res then
        return res, err, errno, sqlstate
    end
    return res, err, errno, sqlstate
end

-- quote
-- function _M.quote(self,options, str)
--     return ngx.quote_sql_str(str)
-- end

-- return list of tables
function _M.tables(self)
    local res = self:execute("SHOW TABLES IN " .. self.options.database .. ";")
    local tables = {}

    for _, v in pairs(res) do
        for _, table_name in pairs(v) do
            tappend(tables, table_name)
        end
    end
    return tables
end

-- return schema as a table
-- function _M.schema(self,options)
--     local schema = {}
--     local tables = _M.tables(options)
--     for i, table_name in ipairs(tables) do
--         if table_name ~= Migration.migrations_table_name then
--             local columns_info = _M.execute(options, "SHOW COLUMNS IN " .. table_name .. ";")
--             tappend(schema, { [table_name] = columns_info })
--         end
--     end
--     return schema
-- end

-- execute a query
function _M.execute(self,sql)
    -- get db object
    local db = mysql_connect(self.options)
    -- execute query
    local res, err, errno, sqlstate = db_execute(db, sql)
    -- keepalive
    mysql_keepalive(db, self.options)
    -- return
    return res, err, errno, sqlstate
end

--- Execute a query and return the last ID
-- function _M.execute_and_return_last_id(self, sql, id_col)
--     -- get db object
--     local db = mysql_connect(self.options)
--     -- execute query
--     db_execute(self.options, db, sql)
--     -- get last id
--     local id_col = id_col
--     local res = db_execute(self.options, db, "SELECT LAST_INSERT_ID() AS " .. id_col .. ";")
--     -- keepalive
--     mysql_keepalive(db, options)
--     return tonumber(res[1][id_col])
-- end

function _M.new(self,options)
    -- check for required params
    local required_options = {
        host = true,
        port = true,
        database = true,
        user = true,
        password = true
    }
    for k, _ in pairs(options) do required_options[k] = nil end
    local missing_options = {}
    for k, _ in pairs(required_options) do tappend(missing_options, k) end

    if #missing_options > 0 then error("missing required database options: " .. tconcat(missing_options, ', ')) end
    options.pool = 100
    local instance = {
        options = options
    }
    setmetatable(instance,{__index = self})
    return instance
end

return _M