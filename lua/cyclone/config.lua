local _M = {version = 0.1}

-- 获取白名单
function _M.get_ip_white_list()
    return {"127.0.0.1", "192.168.1.1"}
end

-- 获取黑名单
function _M.get_ip_black_list()
    return {"127.0.0.2", "192.168.1.2"}
end

-- 获取 host
function _M.get_allow_host()
    return {"www.baidu.com", "www.google.com"}
end

return _M