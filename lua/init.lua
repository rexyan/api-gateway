--
-- Cyclone Api Gateway
-- 1. 支持黑白名单设置（IP，请求头，自定义字段）
-- 2. 支持基于 “漏桶” 算法请求限流
-- 3. 支持 cas token 转换为 jwt token
-- 4. 支持自定义定义拦截规则
--
local balancer = require "ngx.balancer"
local cyclone_core = require "cyclone.core"
local cyclone_util = require "cyclone.util"

local _M = {version = 0.1}

function _M.http_init()
end

function _M.http_init_worker()
end


function _M.http_access_phase()
    local uri = ngx.var.uri
    local host = ngx.var.host
    local method = ngx.req.get_method()
    ngx.say(method)
    local remote_addr = ngx.var.remote_addr
    cyclone_core.fake_fetch(uri, host, method, remote_addr)
    cyclone_util.check_remote_addr()
    cyclone_util.http_for()

end

function _M.http_header_filter_phase()
    if ngx.ctx then
        -- do something
    end
end

function _M.http_body_filter_phase()
    if ngx.ctx then
        -- do something
    end
end

function _M.http_log_phase()
    if ngx.ctx then
        -- do something
    end
end

function _M.http_admin()
end

function _M.http_ssl_phase()
    if ngx.ctx then
        -- do something
    end
end

function _M.http_balancer_phase()
    local ok, err = balancer.set_current_peer(ngx.ctx.ip, ngx.ctx.port)
    if not ok then
        ngx.log(ngx.ERR, "failed to set the current peer: ", err)
        return ngx.exit(500)
    end
end

return _M
