### API Gateway

#### 功能支持

1. 支持黑白名单设置（IP，请求头，自定义字段）
2. 支持基于 “漏桶” 算法请求限流

3. 支持 cas token 转换为 jwt token

4. 支持自定义定义拦截规则



#### 启动 openresty 服务

```shell
openresty -p `pwd` -c conf/nginx.conf
```
或
```
nginx -p ./ -c conf/nginx.conf
```


#### Visual Studio Code + LUA ide

支持 LUA ide Debug 调试

```lua
require("LuaDebugOpenrestyJit")("localhost", 7003)
```



#### Nginx.conf

```nginx
worker_processes  1;
error_log  logs/error.log;
events {
    worker_connections  1024;
}

http {
	lua_package_path  "$prefix/src/?.lua;;";
	init_by_lua_block {
        require "resty.core"
        api_gateway = require("init")
        api_gateway.http_init()
  }
  init_worker_by_lua_block {
    api_gateway.http_init_worker()
  }
	
  include       mime.types;
  default_type  application/octet-stream;
  sendfile        on;
  keepalive_timeout  65;

  server {
    listen       8888;
    server_name  localhost;
    lua_code_cache off;
    access_by_lua_block {
      api_gateway.http_access_phase()
    }
    location / {
      root   html;
      index  index.html index.htm;
    }
		location /hello {
			default_type text/html;
			content_by_lua 'ngx.say("<p>hello, world</p>")';
		}
    error_page   500 502 503 504  /50x.html;
    location = /50x.html {
      root   html;
    } 
    }
}
```

