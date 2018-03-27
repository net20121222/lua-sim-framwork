-- @Date    : 2016-05-17 16:57:47
-- @Author  : MiaoLian (mlian@ulucu.com)
-- @Version : 1.0
-- @Description : 
local _M = { _VERSION = '0.01' }
local mt = { __index = _M }

function _M.connect(self)
	local sock,err = ngx.socket.tcp()
	if not sock then
		return false,err or "create socket failed"
	end
	-- local count,err = sock:getreusedtimes()
	-- if not count then
	-- 	return false,err
	-- end
	-- if count == 0 then
	-- 	sock:settimeout(self.con_timeout)
	-- end
	local con_sta, con_err = sock:connect(self.host, self.port)
	if not con_sta then
		return false,con_err or "connect failed"
	end
	return true,sock
end

function _M.set_timeout(self,sock)
	sock:settimeout(10000)
end

function _M.close(self,sock)
	local ok,err = sock:close() 
	if not ok then
		local errinfo = err or "close failed"
		ngx.log(ngx.ERR,errinfo)
	end
end

function _M.set_keepalive(self,sock)
	local ok,err = sock:setkeepalive(60000, 100)
	if not ok then
		local errinfo = err or "setkeepalive failed"
		ngx.log(ngx.ERR,errinfo)
	end
end

function _M.send(self,sock,msg)
	-- sock:settimeout(5000)
	local msg = msg.."\r\n\r\n"
	local send_bytes,send_err = sock:send(msg)
	if not send_bytes then
		return false,send_err or "send msg err"
	end
	return true,send_bytes
end

function _M.receive(self,sock)
	local reader = sock:receiveuntil("\r\n\r\n")
	self:set_timeout(sock)
	local data, err, partial = reader()
	if not data then
		self:close(sock)
		return false,err or "receive msg err"
	end
	return true,data
end

function _M.send_receive_msg(self,msg)
	local sta,sock_or_err = self:connect()
	if not sta then
		return false,sock_or_err
	end
	local send_sta,send_bytes = self:send(sock_or_err,msg)
	if not send_sta then
		return false,send_bytes
	end
	local rev_sta,rev_info = self:receive(sock_or_err)
	if not rev_sta then
		return false,rev_info
	end
	self:set_keepalive(sock_or_err)
	return true,rev_info
end

function _M.new(self,opts)
	local config = {}
	config.host = opts.ip or "127.0.0.1"
	config.port = opts.port or 80
	-- config.timeout = opts.con_timeout or 2000

	return setmetatable(config, mt)
end

return _M