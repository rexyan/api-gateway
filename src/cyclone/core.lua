local config = require("cyclone.config")
local request = require("cyclone.request")

local limit_traffic = require "resty.limit.traffic"
local limit_conn = require "resty.limit.conn"
local limit_req = require "resty.limit.req"

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
        local args_rules = custom_rule[2]
        local body_rules = custom_rule[3]
        
        -- 规则全部为空，则返回 true
        if table_is_empty(header_rules) and table_is_empty(args_rules) and table_is_empty(body_rules) then
            return true
        end

        for k, v in pairs(header_rules) do
            if req_headers[k] and req_headers[k] == v then
                header_check_rule_result = true
            end
        end
        
        -- 校验 args
        local args = request.get_args(local_req) or {}
        for k, v in pairs(args_rules) do
            if args[k] and args[k] == v then
                args_check_rule_result = true
            end
        end

        -- 校验 body
        local body = request.get_body(nil, local_req) or {}
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

-- 验证 jwt token
function _M.check_jwt_token(token)
    -- TODO 校验 Token
    return true
end

-- CAS Token 转换用户信息
function _M.cyclone_auth()
    -- 判断哪些链接需要进行认证
    local no_auth_list = config.get_no_auth_list()
    local current_req_url = ngx.req

    if not is_in_array(current_req_url, no_auth_list) then
        -- 验证 jwt token
        return _M.check_jwt_token()
    end

    return true
end


-- 请求限流
function _M.limit_req_conn()
    -- 限制请求速率
    -- 限制并发连接数
    local lim1, err = limit_req.new("limit_req_store", 300, 200)   -- 限制请求速率。每秒的速率设置为 300。如果超过 300 但小于 500（300+200 计算得到），就需要排队等候；如果超过 500，就会直接拒绝。
    local lim2, err = limit_conn.new("limit_conn_store", 300, 500, 0.5)   -- 限制并发连接数。限制一个 ip 客户端最大并发请求个数， 第二个参数为漏桶的桶容量，最后一个参数其实是你要预估这些并发（或者说单个请求）要处理多久
    
    local limiters = {lim1, lim2}
    local host = ngx.var.host
    local client = ngx.var.binary_remote_addr
    local keys = {host, client}
    local states = {}

    local delay, err = limit_traffic.combine(limiters, keys, states)
    if not delay then
        if err == "rejected" then
            ngx.log(ngx.INFO, "request rejected")
            return ngx.exit(503)
        end
        ngx.log(ngx.ERR, "failed to limit traffic: ", err)
        return ngx.exit(500)
    end

    if lim2:is_committed() then
        local ctx = ngx.ctx
        ctx.limit_conn = lim2
        ctx.limit_conn_key = keys[2]
    end

    if delay >= 0.001 then
        ngx.sleep(delay)
    end

end


-- 释放请求限流计数
function _M.release_limit_req_conn()
    local ctx = ngx.ctx
    local lim = ctx.limit_conn
    if lim then
        local key = ctx.limit_conn_key
        local conn, err = lim:leaving(key, 0.5)
        if not conn then
            ngx.log(ngx.ERR,"failed to record the connection leaving ", "request: ", err)
            return
        end
    end
end

return _M