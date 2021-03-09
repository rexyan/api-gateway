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

-- 403 
function _M.http_forbidden()
    ngx.exit(403)
end

-- 200
function _M.http_ok()
    ngx.exit(200)
end

return _M