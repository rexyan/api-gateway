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

-- 表中是否含有某个字符串
function string_find(t, target_string)
	for _, v in ipairs(t) do
        if string.find(target_string, v, 1, true) then
           return true 
        end
    end
	return false
end

-- 表是否为空
function table_is_empty(t)
    return table.getn(t) == 0
 end

-- 字符串切分
function split(inputstr, sep)
	if sep == nil then
			sep = "%s"
	end
	local t={} ; i=1
	for str in string.gmatch(inputstr, "([^"..sep.."]+)") do
			t[i] = str
			i = i + 1
	end
	return t
end

-- url_encode
function url_encode(s)  
	s = string.gsub(s, "([^%w%.%- ])", function(c) return string.format("%%%02X", string.byte(c)) end)  
   return string.gsub(s, " ", "+")  
end  

-- url_decode
function urlDecode(s)  
   s = string.gsub(s, '%%(%x%x)', function(h) return string.char(tonumber(h, 16)) end)  
   return s  
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