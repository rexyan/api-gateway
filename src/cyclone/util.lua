local config = require("cyclone.config")

local _M = {version = 0.1}

-- 元素是否在表中
function is_in_array(t, val)
	for _, v in ipairs(t) do
		if v == val then
			return true
		end
	end
	return false
end

-- 表是否为空
function table_is_empty(t)
    return table.getn(t) == 0
 end

-- 校验 IP 是否在白名单或者黑名单中。白名单优先级高于黑名单
function _M.check_remote_addr()
    local remote_addr = ngx.var.remote_addr
    local white_list = config.get_ip_white_list()
    local block_list = config.get_ip_black_list()
    if is_in_array(white_list, remote_addr) then
        return true
    end

    if is_in_array(block_list, remote_addr) then
        return false
    end

    return true
end

-- 校验 host
function _M.check_host()
    local host = ngx.var.host
    local allow_host = config.get_allow_host()
    
    if table_is_empty(allow_host) then
        return true
    end

    if is_in_array(allow_host, host) then
        return true
    else
        return false
    end
end

-- 403 
function _M.http_forbidden()
    ngx.exit(403) {"data"}
end

return _M