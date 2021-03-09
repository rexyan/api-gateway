local config = require("cyclone.config")
local request = require("cyclone.request")

local _M = {version = 0.1}


-- 校验 IP 是否在白名单或者黑名单中
-- 如果 IP 既在白名单也在黑名单中, 则白名单优先级高于黑名单
function _M.check_remote_addr()
    local remote_addr = ngx.var.remote_addr
    local white_list = config.get_ip_white_list()
    local block_list = config.get_ip_black_list()
    
    if white_list and is_in_array(white_list, remote_addr) then
        return true
    end

    if block_list and is_in_array(block_list, remote_addr) then
        return false
    end

    return true
end

-- 校验 host
function _M.check_host()
    local host = ngx.var.host
    local allow_host = config.get_allow_host()
    if allow_host then 
        if table_is_empty(allow_host) then
            return true
        end

        if is_in_array(allow_host, host) then
            return true
        else
            return false
        end
    end
    return true
end

-- 校验自定义字段
function _M.check_custom_rule()
    local header_check_rule_result = false
    local args_check_rule_result = false
    local body_check_rule_result = false
    local custom_rule = config.get_custom_rule()

    local local_req = ngx.req

    if custom_rule then
        -- 校验请求头
        local req_headers = request.headers(local_req) or {}
        local header_rules = custom_rule[1]

        for k, v in pairs(header_rules) do
            if req_headers[k] and req_headers[k] == v then
                header_check_rule_result = true
            end
        end
        
        -- 校验 args
        local args = request.get_args(local_req) or {}
        local args_rules = custom_rule[2]
        for k, v in pairs(args_rules) do
            if args[k] and args[k] == v then
                args_check_rule_result = true
            end
        end

        -- 校验 body
        local body = request.get_body(nil, local_req) or {}
        local body_rules = custom_rule[3]
        for k, v in pairs(body_rules) do
            if body[k] and body[k] == v then
                body_check_rule_result = true
            end
        end
        return header_check_rule_result and args_check_rule_result and body_check_rule_result
    else
        return true
    end
end


-- CAS Token 转换用户信息
function _M.convert_cas_token()
    -- 判断哪些链接需要进行认证转换，不进行的直接放行
    local no_auth_list = config.get_no_auth_list()
    local current_req_url = ngx.req

    if not is_in_array(current_req_url, no_auth_list) then
        -- 获取用户信息
        
    end
end

return _M