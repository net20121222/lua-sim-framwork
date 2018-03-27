-- @Date    : 2016-05-03 13:41:56
-- @Author  : MiaoLian (mlian@ulucu.com)
-- @Version : 1.0
-- @Description : 

local common_lib = require("application.help.common_help")
local common = common_lib:new() 

local next = next
local pairs = pairs
local setmetatable = setmetatable
local tconcat = table.concat
local type = type
local function tappend(t, v) t[#t+1] = v end

-- [field_and_values 将table的数据转化成mysql中的数据段]
-- @param  {[function]} quote  [转义字符函数]
-- @param  {[table]} attrs  [需要转化的table]
-- @param  {[string]} concat [数据段的连接符(AND/OR)]
-- @param  {[string]} sign   [数据段的连接符(< = > <= >=)]
-- @return {[string]}        [转化好的数据段]
local function field_and_values(quote, attrs, concat, sign)
    local str_sign = sign or "="
    local fav = {}
    for field, value in pairs(attrs) do
        local key_pair = {}
        local str_field = "`"..field.."`"
        tappend(key_pair, str_field)
        if type(value) == 'string' then 
            value = quote(value) 
        elseif type(value) == 'boolean' then
            value = quote("") 
        end
        tappend(key_pair, str_sign)
        tappend(key_pair, value)

        tappend(fav, tconcat(key_pair))
    end
    return tconcat(fav, concat)
end

-- [value_quote 将数组table内容进行转义]
-- @param  {[function]} quote [转义函数]
-- @param  {[table]} attrs [转义数组]
-- @return {[table]}       [数组]
local function value_quote(quote,attrs)
    local tab_attrs = {}
    for i=1,#attrs do
        if type(attrs[i]) == 'string' then 
            attrs[i] = quote(attrs[i]) 
        elseif type(attrs[i]) == 'boolean' then
            attrs[i] = quote("") 
        end
        tappend(tab_attrs,attrs[i])
    end
    return tab_attrs
end

-- [delete_empty 清空拼接table数组的空数据]
-- @param  {[table]} attrs [table数组]
-- @return {[table]}       [table数组]
local function delete_empty(attrs)
    local tab_attrs = {}
    for i=1,#attrs do
        if attrs[i] and attrs[i] ~= "" then
            tappend(tab_attrs,attrs[i])
        end
    end
    return tab_attrs
end

-- [in_value mysql语句in拼接]
-- @param  {[function]} quote [转义字符函数]
-- @param  {[string]} value [字符串,"1,2,3"]
-- @return {[string]}       [转移好的字符串]
-- local tab_sql = {
--         a= "3",
--         b = "4,5,6"
--     }
-- b IN (4,5,6 ) AND a IN (3 )
local function in_value(quote,value)
    local in_string = {}
    if not value then
        return ""
    end
    local tab_value = common:split(value,",")
    
    for _,num_or_string in pairs(tab_value) do
        local num = tonumber(num_or_string)
        if num then
            tappend(in_string,num)
        else 
            num = quote(num_or_string)
            tappend(in_string,num)
        end
    end
    return tconcat(in_string,",")
end

-- [in_value_ori mysql语句in拼接]
-- @param  {[function]} quote [转义字符函数]
-- @param  {[string]} value [字符串,"1,2,3"]
-- @return {[string]}       [转移好的字符串]
-- local tab_sql = {
--         a= "3",
--         b = ""4","5","6""
--     }
-- b IN ('4','5','6' ) AND a IN ('3' )
local function in_value_ori(quote,value)
    local in_string = {}
    if not value then
        return ""
    end
    local tab_value = common:split(value,",")
    
    for _,num_or_string in pairs(tab_value) do
        if type(num_or_string) == 'string' then 
            num_or_string = quote(num_or_string) 
        elseif type(value) == 'boolean' then
            num_or_string = quote("") 
        end
        tappend(in_string,num_or_string)
    end
    return tconcat(in_string,",")
end


-- [build_where 生成where语句函数]
-- @param  {[type]} self  []
-- @param  {[table]} sql   [拼接的table数组]
-- @param  {[table]} attrs [字段名和数据的table]
-- @return {[type]}       []
local function build_where(self, sql, attrs)
    if attrs ~= nil then
        if type(attrs) == 'table' then
            if next(attrs) ~= nil then
                tappend(sql, " WHERE (")
                tappend(sql, field_and_values(self.quote, attrs, ' AND '))
                tappend(sql, ")")
            end
        else
            tappend(sql, " WHERE (")
            tappend(sql, attrs)
            tappend(sql, ")")
        end
    end
end

-- [build_where_specil 生成特殊where语句函数]
-- @param  {[type]} self  []
-- @param  {[table]} sql   [拼接的table数组]
-- @param  {[table]} attrs [条件语句数组]
-- local attrs = {
--         "b IN (4 ) AND a IN (3 )",
--         "b LIKE '%4%' AND a LIKE '%3%'"
--     }
-- SELECT count(*) FROM tb_http_api_config WHERE (b IN (4 ) AND a IN (3 ) AND b LIKE '%4%' AND a LIKE '%3%') LIMIT 13;
local function build_where_specil(self, sql, attrs)
    if attrs ~= nil then
        local value_pair = {}
        if type(attrs) == 'table' then
            tappend(sql, " WHERE (")
            for _,value in pairs(attrs) do
                tappend(value_pair, value)
            end
            tappend(sql,tconcat(value_pair, " AND "))
            tappend(sql, ")")
        else
            tappend(sql, " WHERE (")
            tappend(sql, attrs)
            tappend(sql, ")")
        end
    end
end

local sim_mysql_orm = {_VERSION = "0.01"}

-- [new 生成对象]
-- @param  {[type]} self  []
-- @param  {[string]} table_name   [拼接的表的名字]
-- @return {[table]}       [函数列表]
function sim_mysql_orm.new(self,table_name)
	local quote_fun = function(str) return ngx.quote_sql_str(str) end
    -- init instance
    local instance = {
        table_name = table_name,
        quote = quote_fun
    }
    setmetatable(instance, {__index = self})
    return instance
end

-- 插入模块
-- [insert 单条=号插入语句生成]
-- @param  {[type]} self  []
-- @param  {[table]} attrs   [插入的field和value]
-- @return {[string]}       [单条插入语句]
-- local tab_sql1 = {
--     ["aaa"] = 123,
--     ["bbb"] = "123"
-- }
-- INSERT INTO tb_http_api_config (aaa,bbb) VALUES (123,'123');
function sim_mysql_orm.insert(self,attrs,others)
    -- health check
    if attrs == nil or next(attrs) == nil then
        error("no attributes were specified to create new model instance")
    end
    -- init sql
    local sql = {}
    -- build fields
    local fields = {}
    local values = {}
    for field, value in pairs(attrs) do
        tappend(fields, field)
        if type(value) == 'string' then 
            value = self.quote(value) 
        elseif type(value) == 'boolean' then
            value = self.quote("") 
        end
        tappend(values, value)
    end
    -- build sql
    tappend(sql, "INSERT INTO ")
    tappend(sql, self.table_name)
    tappend(sql, " (")
    tappend(sql, tconcat(fields, ','))
    tappend(sql, ") VALUES (")
    tappend(sql, tconcat(values, ','))
    tappend(sql, ")")
    if others then
        tappend(sql, others)
    end
    tappend(sql, ";")
    -- hit server
    return tconcat(sql)
end

-- [insert 多条插入语句生成]
-- @param  {[type]} self  []
-- @param  {[table]} attrs   [插入的field,和value]
-- @return {[string]}       [多条插入语句]
--  local tab_sql = {
--     field = {"test1","test2","test3"},
--     values = {{1,"2",3},{true,"5",6}}
-- }
-- INSERT INTO tb_http_api_config (test1,test2,test3) VALUES ((1,'2',3),('','5',6));
function sim_mysql_orm.insert_more(self,attrs)
    -- health check
    if attrs == nil or next(attrs) == nil then
        error("no attributes were specified to insert new model instance")
    end

    if not attrs.field or not attrs.values then
        error("no field,values were specified to insert new model instance")
    end
    -- init sql
    local sql = {}

    local values = {}
    for _, value in pairs(attrs.values) do
        local one_values = {}
        tappend(one_values, "(")
        local quote_value = value_quote(self.quote,value)
        tappend(one_values, tconcat(quote_value,","))
        tappend(one_values, ")")
        tappend(values,tconcat(one_values))
    end
    -- build sql
    tappend(sql, "INSERT INTO ")
    tappend(sql, self.table_name)
    tappend(sql, " (")
    tappend(sql, tconcat(attrs.field,","))
    tappend(sql, ") VALUES (")
    tappend(sql, tconcat(values, ','))
    tappend(sql, ");")
    -- hit server
    return tconcat(sql)
end

-- 查询模块
-- [where_specil 多条查询语句生成]
-- @param  {[type]} self  []
-- @param  {[table]} attrs   [查询的条件数组]
-- @param  {[table]} options   [查询限制条件ORDER BY,LIMIT,OFFSET,GROUP BY]
-- @param  {[proty]} proty   [查询结果的指定]
-- @return {[string]}       [多条查询语句]
-- local tab_sql = {
--         "b IN (4 ) AND a IN (3 )",
--         "b LIKE '%4%' AND a LIKE '%3%'"
--     }
-- SELECT count(*) FROM tb_http_api_config WHERE (b IN (4 ) AND a IN (3 ) AND b LIKE '%4%' AND a LIKE '%3%') LIMIT 13;
function sim_mysql_orm.where_specil(self,attrs, options,proty)
    local proty = proty or "*"
    -- init sql
    local sql = {}
    -- start
    tappend(sql, "SELECT ")
    tappend(sql, proty)
    tappend(sql, " FROM ")
    tappend(sql, self.table_name)
    attrs = delete_empty(attrs)
    -- where
    build_where_specil(self, sql, attrs)
    -- options
    if options then
        -- group by
        if options.group ~= nil then
            tappend(sql, " GROUP BY ")
            tappend(sql, options.group)
        end
        -- order
        if options.order ~= nil then
            tappend(sql, " ORDER BY ")
            tappend(sql, options.order)
        end
        -- limit
        if options.limit ~= nil then
            tappend(sql, " LIMIT ")
            tappend(sql, options.limit)
        end
        -- offset
        if options.offset ~= nil then
            tappend(sql, " OFFSET ")
            tappend(sql, options.offset)
        end

    end
    -- close
    tappend(sql, ";")
    -- execute
    return tconcat(sql)
end

-- [LIKE 查询LIKE语句生成]
-- @param  {[type]} self  []
-- @param  {[table]} attrs   [查询LIKE语句的table]
-- @param  {[table]} sign   [查询like语句匹配前后,"front"匹配前面,"back"匹配后面,nil为全部匹配]
-- @return {[string]}       [查询IN语句]
-- local tab_sql1 = {
--     a = 3,
--     b = 4
-- }
-- b LIKE '%4%' AND a LIKE '%3%'
function sim_mysql_orm.LIKE(self,attrs,sign)
    local sql_like = {}
    local front = "'%"
    local back = "%'"
    if sign == "front" then
        back = "'"
    end
    if sign == "back" then
        front = "'"
    end
    for field,value in pairs(attrs) do
        local key_pair = {}
        tappend(key_pair,field)
        tappend(key_pair," LIKE ")
        tappend(key_pair,front..value..back)
        tappend(sql_like,tconcat(key_pair))                       
    end
    return tconcat(sql_like,' AND ')
end

-- [IN 查询IN语句生成]
-- @param  {[type]} self  []
-- @param  {[table]} attrs   [查询IN语句的table]
-- @param  {[string]} ori   [查询IN语句的table中字符串数字是否转换,true不转换,false转换]
-- @return {[string]}       [查询IN语句]
-- local tab_sql1 = {
--     a = 3,
--     b = 4
-- }
-- b IN (4 ) AND a IN (3 )或者b IN ('4','5','6' ) AND a IN ('3' )
function sim_mysql_orm.IN(self,attrs,ori)
    local sql_in = {}
    local in_quote_value = in_value
    if ori then
        in_quote_value = in_value_ori
    end
    for field,value in pairs(attrs) do
        local key_pair = {}
        tappend(key_pair,field)
        tappend(key_pair," IN (")
        tappend(key_pair,in_quote_value(self.quote,value))
        tappend(key_pair,")")
        tappend(sql_in,tconcat(key_pair))                        
    end
    return tconcat(sql_in,' AND ')
end

-- [operate 查询operate(<,>,<=,>=,=)语句生成]
-- @param  {[type]} self  []
-- @param  {[table]} attrs   [查询operate语句的table]
-- @param  {[string]} sign   [查询operate语句的符号<,>,<=,>=,=]
-- @return {[string]}       [查询operate语句]
-- local tab_sql1 = {
--     a = "3",
--     b = "4,5,6"
-- }
-- (`b`='4,5,6' AND `a`='3')
function sim_mysql_orm.operate(self,attrs,sign)
    return field_and_values(self.quote, attrs, ' AND ',sign)
end

-- [where 单条查询语句生成]
-- @param  {[type]} self  []
-- @param  {[table]} attrs   [单条查询语句的field,value]
-- @param  {[string]} options   [查询限制条件ORDER BY,LIMIT,OFFSET,GROUP BY]
-- @param  {[proty]} proty   [查询结果的指定]
-- @return {[string]}       [单条查询语句]
-- local tab_sql1 = {
--     a = "3",
--     b = "456"
-- }
-- "SELECT count(*) FROM tb_http_api_config WHERE (`b`='456' AND `a`='3') LIMIT 13;
function sim_mysql_orm.where(self,attrs, options,proty)
    local proty = proty or "*"
    -- init sql
    local sql = {}
    -- start
    tappend(sql, "SELECT ")
    tappend(sql, proty)
    tappend(sql, " FROM ")
    tappend(sql, self.table_name)
    -- where
    build_where(self, sql, attrs)
    -- options
    if options then
        -- order
        if options.order ~= nil then
            tappend(sql, " ORDER BY ")
            tappend(sql, options.order)
        end
        -- limit
        if options.limit ~= nil then
            tappend(sql, " LIMIT ")
            tappend(sql, options.limit)
        end
        -- offset
        if options.offset ~= nil then
            tappend(sql, " OFFSET ")
            tappend(sql, options.offset)
        end
        -- group by
        if options.group ~= nil then
            tappend(sql, " GROUP BY ")
            tappend(sql, options.group)
        end
    end
    -- close
    tappend(sql, ";")
    -- execute
    return tconcat(sql)
end

-- 删除模块
-- [delete_where 单条=号连接删除语句生成]
-- @param  {[type]} self  []
-- @param  {[table]} attrs   [单条查询语句的field,value]
-- @param  {[string]} options   [查询限制条件LIMIT]
-- @return {[string]}       [单条查询语句]
-- local tab_sql1 = {
--     a = "3",
--     b = "456"
-- }
-- DELETE FROM tb_http_api_config WHERE (`b`='456' AND `a`='3') LIMIT 13;
function sim_mysql_orm.delete_where(self,attrs, options)
    -- init sql
    local sql = {}
    -- start
    tappend(sql, "DELETE FROM ")
    tappend(sql, self.table_name)
    -- where
    build_where(self, sql, attrs)
    -- options
    if options then
        -- limit
        if options.limit ~= nil then
            tappend(sql, " LIMIT ")
            tappend(sql, options.limit)
        end
    end
    -- close
    tappend(sql, ";")
    -- execute
    return tconcat(sql)
end

-- [delete_where_sepcil 单条特殊删除语句生成]
-- @param  {[type]} self  []
-- @param  {[table]} attrs   [单挑删除语句条件数组]
-- @param  {[string]} options   [查询限制条件LIMIT]
-- @return {[string]}       [单条特殊删除语句]
-- local attrs = {
--     "`b`>'456' AND `a`>'3'",
--     "`b`='456' AND `a`='3'"
-- }
-- "DELETE FROM tb_http_api_config WHERE (`b`>'456' AND `a`>'3' AND `b`='456' AND `a`='3') LIMIT 13;
function sim_mysql_orm.delete_where_sepcil(self,attrs, options)
    -- init sql
    local sql = {}
    -- start
    tappend(sql, "DELETE FROM ")
    tappend(sql, self.table_name)
    attrs = delete_empty(attrs)
    -- where
    build_where_specil(self, sql, attrs)
    -- options
    if options then
        -- limit
        if options.limit ~= nil then
            tappend(sql, " LIMIT ")
            tappend(sql, options.limit)
        end
    end
    -- close
    tappend(sql, ";")
    -- execute
    return tconcat(sql)
end

-- 更新模块
-- [insert 单条=号条件更新语句生成]
-- @param  {[type]} self  []
-- @param  {[table]} attrs   [更新的field和value]
-- @param  {[table]} where_attrs   [更新的条件field和value]
-- @return {[string]}       [单条=号更新语句]
-- local attrs = { first_name = 'roberto', last_name = 'gin', age = 3, seen_at = '2013-10-12T16:31:21 UTC' }
-- local where_attrs = { id = 4, first_name = 'robbb' }
-- UPDATE tb_http_api_config SET `seen_at`='2013-10-12T16:31:21 UTC',`last_name`='gin',`first_name`='roberto',`age`=3 WHERE (`first_name`='robbb' AND `id`=4);
function sim_mysql_orm.update_where(self,attrs, where_attrs)
    -- health check
    if attrs == nil or next(attrs) == nil then
        error("no attributes were specified to create new model instance")
    end
    -- init sql
    local sql = {}
    -- start
    tappend(sql, "UPDATE ")
    tappend(sql, self.table_name)
    tappend(sql, " SET ")
    -- updates
    tappend(sql, field_and_values(self.quote, attrs, ','))
    -- where
    build_where(self, sql, where_attrs)
    -- close
    tappend(sql, ";")
    -- execute
    return tconcat(sql)
end

-- [insert 单条条件更新语句生成]
-- @param  {[type]} self  []
-- @param  {[table]} attrs   [更新的field和value]
-- @param  {[table]} where_attrs   [更新的条件string数组]
-- @return {[string]}       [单条更新语句]
-- local attrs = { first_name = 'roberto', last_name = 'gin', age = 3, seen_at = '2013-10-12T16:31:21 UTC' }
-- local where_attrs = {"`b`>'456' AND `a`>'3'"}
-- UPDATE tb_http_api_config SET `seen_at`='2013-10-12T16:31:21 UTC',`last_name`='gin',`first_name`='roberto',`age`=3 WHERE (`b`>'456' AND `a`>'3');
function sim_mysql_orm.update_where_specil(self,attrs, where_attrs)
    -- health check
    if attrs == nil or next(attrs) == nil then
        error("no attributes were specified to create new model instance")
    end
    -- init sql
    local sql = {}
    -- start
    tappend(sql, "UPDATE ")
    tappend(sql, self.table_name)
    tappend(sql, " SET ")
    -- updates
    tappend(sql, field_and_values(self.quote, attrs, ','))
    -- where
    build_where_specil(self, sql, where_attrs)
    -- close
    tappend(sql, ";")
    -- execute
    return tconcat(sql)
end

return sim_mysql_orm
