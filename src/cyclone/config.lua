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
    return {"www.baidu.com", "www.google.com", "127.0.0.1"}
end

-- 获取自定义规则
function _M.get_custom_rule()
    return {
        {},
        {},
        {}
    }

    -- return {
    --     {a = -1, a1 = 1},   -- request header
    --     {b = -2, b1 = 2},   -- request args
    --     {c = -3, c1 = 3}    -- request body
    -- }   
end


-- 获取不需要认证的 URL 地址
function _M.get_no_auth_list()
    return {"/cas/login", "/cas/logout"}
end

return _M