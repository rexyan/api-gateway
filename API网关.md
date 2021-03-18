## 功能支持
### 已有功能
1. 支持黑白名单设置（IP，请求头，自定义字段）【针对所有】
2. 支持基于 “漏桶” 算法请求限流【针对所有】
3. 支持 CAS Token 转换 JWT Token，请求返回用户信息【针对所有】
4. 支持自定义定义拦截规则【针对所有】

### 未来规划功能

1. 规则支持范围更精准，支持对单个 URL 进行设置
2. 数据库支持，使用 watch 机制实时获取动态配置信息
3. 功能抽取为插件，实现灵活组装和配置
4. 支持请求计数，Web 界面展示和配置




## 开发环境搭建

### Windows 搭建

OpenResty 下载地址：https://openresty.org/download/openresty-1.19.3.1-win64.zip

常用命令：

1. 启动：
   
   ```
start nginx 或 nginx.exe
   ```
   
2. 停止：
   
   ```
   nginx.exe -s stop 或 nginx.exe -s quit
   ```
   
   注：stop是快速停止nginx，可能并不保存相关信息；quit是完整有序的停止nginx，并保存相关信息。
   
3. 重新载入 Nginx：
   
    ```
    nginx.exe -s reload
    ```

   当配置信息修改，需要重新载入这些配置时使用此命令。

4. 重新打开日志文件：
   
   ```
   nginx.exe -s reopen
   ```
   
5. 查看Nginx版本：
   
   ```
   nginx -v
   ```
   
6. 查看进程：
    dos窗口下可以输入` tasklist /fi “imagename eq nginx.exe”` 查看nginx是否正常启动
    
7. 杀死进程

   ```
    taskkill -PID 25956 -F
   ```



### 类 Unix 系统搭建

Mac 用户推荐使用 [homebrew](https://brew.sh/) 进行安装，其他系统用户可参考[官方文档](https://openresty.org/cn/installation.html)给出的详细信息。



### Nginx 和 OpenResty  执行阶段

Nginx 和 OpenResty 两者都有对应的生命周期或者执行阶段，在开发过程中，可以在特定阶段做指定的功能。

- `set_by_lua`，用于设置变量；
- `rewrite_by_lua`，用于转发、重定向等；
- `access_by_lua`，用于准入、权限等；
- `content_by_lua`，用于生成返回内容；
- `header_filter_by_lua`，用于应答头过滤处理；
- `body_filter_by_lua`，用于应答体过滤处理；
- `log_by_lua`，用于日志记录。



**Nginx**

```nginx
typedef enum {
    NGX_HTTP_POST_READ_PHASE = 0,
 
    NGX_HTTP_SERVER_REWRITE_PHASE,
 
    NGX_HTTP_FIND_CONFIG_PHASE,
    NGX_HTTP_REWRITE_PHASE,
    NGX_HTTP_POST_REWRITE_PHASE,
 
    NGX_HTTP_PREACCESS_PHASE,
 
    NGX_HTTP_ACCESS_PHASE,
    NGX_HTTP_POST_ACCESS_PHASE,
 
    NGX_HTTP_PRECONTENT_PHASE,
 
    NGX_HTTP_CONTENT_PHASE,
 
    NGX_HTTP_LOG_PHASE
} ngx_http_phases;
```



**OpenResty **

![](//r.photo.store.qq.com/psc?/V12EvAd609VbnF/ruAMsa53pVQWN7FLK88i5rjtI5dzb5UcXN58Ddfomf8xu8.lGMz2DPLpf1eXe*FtBxbvHv0VRR8xl7r7w3lUWaE0edPnglz0pbC3LBsoNXA!/mnull&bo=7QOOA.0DjgMDCSw!&rf=photolist&t=5/r/_yake_qzoneimgout.png)





### LUA ide 调试项目

LUA ide 是 Visual Studio *Code* 的一款收费插件，可免费使用一个星期。安装插件可在应用商店中搜索 luaide，然后再 lua 入口文档新增以下代码即可使用 luaide 进行调试，详细信息可参考 [文档]( https://www.showdoc.com.cn/luaide?page_id=687771476825747) 

```lua
require("LuaDebugOpenrestyJit")("localhost", 7003)
```



## 项目搭建

### 项目目录结构

```
│  .gitignore
│  README.md
│  socket.so
├─.vscode
│      launch.json
│      settings.json
├─conf                           # nginx 配置文件目录
│      mime.types
│      nginx.conf 
├─html
│      index.html
├─logs                           # nginx 日志文件目录
│      access.log
│      error.log
│      nginx.pid
├─src                            # Lua 项目文件目录
│  │  init.lua                   # 入口文件
│  │  LuaDebugOpenrestyJit.lua   # Lua ide 调试依赖文件
│  └─cyclone                     # API 网关目录   
│      │  config.lua             # 配置文件
│      │  core.lua               # 核心功能封装文件
│      │  request.lua            # 请求功能封装文件
│      │  response.lua           # 响应功能封装文件
│      │  util.lua               # 工作类封装文件
│      │  version.lua            # 网关版本控制文件
│      └─config_file             # 配置文件目录（目前未使用）
│              config.txt
```





## 学习资料

### Nginx 教程

[agentzh 的 Nginx 教程（版本 2020.03.19）](https://openresty.org/download/agentzh-nginx-tutorials-zhcn.html)



### apisix nginx 配置

```nginx
master_process on;

worker_processes 1;

error_log logs/error.log warn;
pid logs/nginx.pid;

worker_rlimit_nofile 20480;

events {
    worker_connections 10620;
}

worker_shutdown_timeout 3;

http {
    lua_package_path  "$prefix/lua/?.lua;;";

    log_format main '$remote_addr - $remote_user [$time_local] $http_host "$request" $status $body_bytes_sent $request_time "$http_referer" "$http_user_agent" $upstream_addr $upstream_status $upstream_response_time';
    access_log logs/access.log main buffer=16384 flush=5;

    init_by_lua_block {
        require "resty.core"
        apisix = require("apisix")
        apisix.http_init()
    }

    init_worker_by_lua_block {
        apisix.http_init_worker()
    }

    upstream apisix_backend {
        server 0.0.0.1;
        balancer_by_lua_block {
            apisix.http_balancer_phase()
        }

        keepalive 320;
    }

    server {
        listen 9443 ssl;
        ssl_certificate      cert/apisix.crt;
        ssl_certificate_key  cert/apisix.key;
        ssl_session_cache    shared:SSL:1m;

        listen 9080;

        server_tokens off;
        more_set_headers 'Server: APISIX web server';

        location = /apisix/nginx_status {
            allow 127.0.0.0/24;
            access_log off;
            stub_status;
        }

        location /apisix/admin {
            allow 127.0.0.0/24;
            content_by_lua_block {
                apisix.http_admin()
            }
        }

        ssl_certificate_by_lua_block {
            apisix.http_ssl_phase()
        }

        location / {
            set $upstream_scheme             'http';
            set $upstream_host               $http_host;
            set $upstream_upgrade            '';
            set $upstream_connection         '';
            set $upstream_uri                '';

            access_by_lua_block {
                apisix.http_access_phase()
            }

            proxy_http_version 1.1;
            proxy_set_header   Host              $upstream_host;
            proxy_set_header   Upgrade           $upstream_upgrade;
            proxy_set_header   Connection        $upstream_connection;
            proxy_set_header   X-Real-IP         $remote_addr;
            proxy_pass_header  Server;
            proxy_pass_header  Date;

            ### the following x-forwarded-* headers is to send to upstream server

            set $var_x_forwarded_for        $remote_addr;
            set $var_x_forwarded_proto      $scheme;
            set $var_x_forwarded_host       $host;
            set $var_x_forwarded_port       $server_port;

            if ($http_x_forwarded_for != "") {
                set $var_x_forwarded_for "${http_x_forwarded_for}, ${realip_remote_addr}";
            }
            if ($http_x_forwarded_proto != "") {
                set $var_x_forwarded_proto $http_x_forwarded_proto;
            }
            if ($http_x_forwarded_host != "") {
                set $var_x_forwarded_host $http_x_forwarded_host;
            }
            if ($http_x_forwarded_port != "") {
                set $var_x_forwarded_port $http_x_forwarded_port;
            }

            proxy_set_header   X-Forwarded-For      $var_x_forwarded_for;
            proxy_set_header   X-Forwarded-Proto    $var_x_forwarded_proto;
            proxy_set_header   X-Forwarded-Host     $var_x_forwarded_host;
            proxy_set_header   X-Forwarded-Port     $var_x_forwarded_port;

            # proxy pass
            proxy_pass         $upstream_scheme://apisix_backend$upstream_uri;

            header_filter_by_lua_block {
                apisix.http_header_filter_phase()
            }

            body_filter_by_lua_block {
                apisix.http_body_filter_phase()
            }

            log_by_lua_block {
                apisix.http_log_phase()
            }
        }
    }
}
```



### OpenResty 的发展

OpenResty 并不像其他的开发语言一样从零开始搭建，而是基于成熟的开源组件——NGINX 和 LuaJIT。OpenResty 诞生于 2007 年，不过，它的第一个版本并没有选择 Lua，而是用了 Perl，这跟作者章亦春的技术偏好有很大关系。

但 Perl 的性能远远不能达到要求，于是，在第二个版本中，Perl 就被 Lua 给替换了。 不过，**在 OpenResty 官方的项目中，Perl 依然占据着重要的角色，OpenResty 工程化方面都是用 Perl 来构建，比如测试框架、Linter、CLI 等**。后来，章亦春离开了淘宝，加入了美国的 CDN 公司 Cloudflare。因为 OpenResty 高性能和动态的优势很适合 CDN 的业务需求，很快， OpenResty 就成为 CDN 的技术标准。 通过丰富的 lua-resty 库，OpenResty 开始逐渐摆脱 NGINX 的影子，形成自己的生态体系，在 API 网关、软 WAF 等领域被广泛使用。



### 标准 Lua 和 LuaJIT

**标准 Lua 和 LuaJIT 是两回事儿，LuaJIT 只是兼容了 Lua 5.1 的语法。**在 OpenResty 几年前的老版本中，编译的时候，你可以选择使用标准 Lua VM ，或者 LuaJIT VM 来作为执行环境，不过，现在已经去掉了对标准 Lua 的支持，只支持 LuaJIT。OpenResty 维护了自己的 LuaJIT 分支，并扩展了很多独有的 API。

LuaJIT 的解释器会在执行字节码的同时，记录一些运行时的统计信息，比如每个 Lua 函数调用入口的实际运行次数，还有每个 Lua 循环的实际执行次数。当这些次数超过某个随机的阈值时，便认为对应的 Lua 函数入口或者对应的 Lua 循环足够热，这时便会触发 JIT 编译器开始工作。

JIT 编译器会从热函数的入口或者热循环的某个位置开始，尝试编译对应的 Lua 代码路径。编译的过程，是把 LuaJIT 字节码先转换成 LuaJIT 自己定义的中间码（IR），然后再生成针对目标体系结构的机器码。

所以，**所谓 LuaJIT 的性能优化，本质上就是让尽可能多的 Lua 代码可以被 JIT 编译器生成机器码，而不是回退到 Lua 解释器的解释执行模式**。



### 第三方模块列表

https://github.com/bungle/awesome-resty



### LuaJIT 拓展新接口

https://github.com/openresty/luajit2/#new-api



### NYI

LuaJIT 中 JIT 编译器的实现还不完善，有一些原语它还无法编译，因为这些原语实现起来比较困难，再加上 LuaJIT 的作者目前处于半退休状态。这些原语包括常见的 pairs() 函数、unpack() 函数、基于 Lua CFunction 实现的 Lua C 模块等。这样一来，当 JIT 编译器在当前代码路径上遇到它不支持的操作时，便会退回到解释器模式。而 JIT 编译器不支持的这些原语，NYI，全称为 Not Yet Implemented，[NYI 的完整列表](http://wiki.luajit.org/NYI)



### Worker 间的通信

**数据共享的几种方式**

1. **第一种是 Nginx 中的变量**

   ```nginx
   location /foo {
        set $my_var ''; # this line is required to create $my_var at config time
        content_by_lua_block {
            ngx.var.my_var = 123;
            ...
        }
    }
   ```

   

2. **第二种是`ngx.ctx`，可以在同一个请求的不同阶段之间共享数据**

   它其实就是一个普通的 Lua 的 table，所以速度很快，还可以存储各种 Lua 的对象。它的生命周期是请求级别的，当一个请求结束的时候，`ngx.ctx` 也会跟着被销毁掉。

   ```nginx
   location /test {
        rewrite_by_lua_block {
            ngx.ctx.host = ngx.var.host
        }
        access_by_lua_block {
           if (ngx.ctx.host == 'openresty.org') then
               ngx.ctx.host = 'test.com'
           end
        }
        content_by_lua_block {
            ngx.say(ngx.ctx.host)
        }
    }
   ```

3. **第三种方法是使用`模块级别的变量`，在同一个 worker 内的所有请求之间共享数据**

   ```lua
   -- mydata.lua
    local _M = {}
    
    local data = {
        dog = 3,
        cat = 4,
        pig = 5,
    }
    
    function _M.get_age(name)
        return data[name]
    end
    
    return _M
   ```

   nginx.conf 的配置如下

   ```nginx
   location /lua {
        content_by_lua_block {
            local mydata = require "mydata"
            ngx.say(mydata.get_age("dog"))
        }
    }
   ```

   在这个示例中，`mydata` 就是一个模块，它只会被 worker 进程加载一次，之后，这个 worker 处理的所有请求，都会共享 `mydata` 模块的代码和数据。需要特别注意的是，一般我们只用这种方式来保存**只读的数据**。如果涉及到写操作，你就要非常小心了，因为可能会有 **race condition**

4.  **shared dict** 

   这种方法是基于红黑树实现的，性能很好，但也有自己的局限性——你必须事先在 Nginx 的配置文件中，声明共享内存的大小，并且这不能在运行期更改：

   ```lua
   lua_shared_dict dogs 10m;
   ```

   shared dict 同样只能缓存字符串类型的数据，不支持复杂的 Lua 数据类型。这也就意味着，当我需要存放 table 等复杂的数据类型时，我将不得不使用 json 或者其他的方法，来序列化和反序列化，这自然会带来不小的性能损耗。




### OpenResty 编码指南

在 OpenResty 中，也有两个可以帮你自动化检测代码风格的工具：luacheck 和 lj-releng。前者是 Lua 和 OpenResty 世界通用的检测工具，后者则是 OpenResty 自己用 perl 写的代码检测工具。

**缩进**： 4 个空格作为缩进的标记

**空格**：在操作符的两边，都需要用一个空格来做分隔。例如：`local i = 1`

**空行**:  比如在行尾增加一个分号，函数之间需要用两个空行来做分隔，如果有多个 if elseif 的分支，它们之间也需要一个空行来做分隔。

**每行最大长度**： 每行不能超过 80 个字符，如果超过的话，需要换行并对齐。

**变量**： 永远使用局部变量，不要使用全局变量

**数组**： 使用`table.new` 来预先分配数组，一定不要在数组中使用 nil，如果一定要使用空值，请用 ngx.null 来表示

**字符串**： 不要在热代码路径上拼接字符串

**函数**： 函数的命名遵循 `snake_case`

**模块**： 所有 require 的库都要 local 化



### 压测悍马 wrk

wrk 和 OpenResty 有很多类似的地方。wrk 也不是从零开始编写的一个开源项目，它站在 LuaJIT 和 Redis 这两个巨人的肩膀上，充分利用了系统的多核资源来生成请求。除此之外，wrk 还暴露了 Lua API，你可以嵌入自己的 Lua 脚本，来自定义请求的头和内容，使用非常灵活。

```shell
wrk -t12 -c400 -d30s http://127.0.0.1:8080/index.html
```

wrk 会使用 12 个线程，保持 400 个长连接，持续 30 秒钟，来给指定的 API 接口发送 HTTP 请求。如果不指定参数的话，wrk 会默认启动 2 个线程和 10 个长连接。