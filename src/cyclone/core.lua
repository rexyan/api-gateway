local _M = {version = 0.1}

function _M.fake_fetch()
    ngx.ctx.ip = "127.0.0.1"
    ngx.ctx.port = 1980
    ngx.say("<p>hello " .. "data" .. "!</p>")
end

return _M