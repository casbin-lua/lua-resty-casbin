# lua-resty-casbin

[![GitHub Action](https://github.com/casbin-lua/lua-resty-casbin/workflows/test/badge.svg?branch=master)](https://github.com/casbin-lua/lua-resty-casbin/actions)
[![Discord](https://img.shields.io/discord/1022748306096537660?logo=discord&label=discord&color=5865F2)](https://discord.gg/S5UjpzGZjN)

lua-resty-casbin is an authorization plugin/middleware for OpenResty, based on [lua-casbin](https://github.com/casbin/lua-casbin/).

## Installing OpenResty
You can follow [this guide](https://blog.openresty.com/en/ubuntu20-or-install/) to install OpenResty on Ubuntu 20.04 if you have not yet installed it.

## Installation

If you do not have LuaRocks installed for OpenResty then install it by:

```
sudo apt install make wget unzip zip

wget https://luarocks.org/releases/luarocks-3.3.1.tar.gz
tar zxpf luarocks-3.3.1.tar.gz
cd luarocks-3.3.1

./configure --prefix=/usr/local/openresty/luajit \
--with-lua=/usr/local/openresty/luajit/ \
--lua-suffix=jit-2.1.0-beta3 \
--with-lua-include=/usr/local/openresty/luajit/include/luajit-2.1

sudo make
sudo make install
```

**NOTE**: 
- This is assuming OpenResty (not the executable) is installed at `/usr/local/`, if it isn't so - replace `/usr/local/` with file path you have installed it in.
- Also assumed is that LuaJIT version is `2.1.0-beta3`, you can check which LuaJIT version it is by doing: `cd /usr/local/openresty/luajit/share/` and then `ls`. It will list a luajit folder like `luajit-2.1.0-beta3`, the suffix here is `jit-2.1.0-beta3`. If this isn't so, replace the suffix accordingly.

Then install Casbin's system dependencies by:
```
sudo apt update
sudo apt install gcc libpcre3 libpcre3-dev
```

**NOTE**: If you use `yum` you could use `pcre` and `pcre-devel` for PCRE.

Then install Casbin's latest current release using:

```
sudo /usr/local/openresty/luajit/bin/luarocks install casbin

```

**NOTE**: Here too the LuaRocks has its executable at `/usr/local/openresty/luajit/bin/luarocks`, if you have it installed somewhere else for OpenResty replace with that instead.


## Usage

- Install `lua-resty-casbin` by LuaRocks:
```
sudo /usr/local/openresty/luajit/bin/luarocks install https://raw.githubusercontent.com/casbin-lua/lua-resty-casbin/master/lua-resty-casbin-1.0.0-1.rockspec
```
- In your `conf/nginx.conf`, initialize a CasbinMiddleware in the `init_by_lua_block` as (where `authorizedRequest` is a function which is called after a request is authorised):
```lua
e = CasbinMiddleware:new(authorizedRequest)
```
- Then in your `content_by_lua_block`, insert the command to check if the request is authorized everytime a request is sent (after you have authenticated):
```lua
e:check()
```

## Example

You can try out an example of this by copying `openresty_example` directory to your system. Then to start the server:

```sh
cd openresty_example
sudo openresty -p $PWD/
```

This will start the server at `http://127.0.0.1:8080/`.

The current policy `authz_policy.csv` is:
```
p, *, /, GET
p, admin, *, *
g, alice, admin
```

This means that all users can access the homepage `/` but only users with admin permissions like alice can access other pages and other HTTP request methods.

For example, if you use:
```sh
curl --header "username: anonymous" 'http://127.0.0.1:8080/'
```
it will result in:
```sh
Authorized request
```
while,
```sh
curl --header "username: anonymous" 'http://127.0.0.1:8080/res1'
```
it will result in a 403 Forbidden page.


But if you send:
```sh
curl --header "username: alice" 'http://127.0.0.1:8080/res1'
```
it will result in:
```sh
Authorized request
```
since alice has admin permissions.

## Documentation

The authorization determines a request based on `{subject, object, action}`, which means what `subject` can perform what `action` on what `object`. In this plugin, the meanings are:
1. `subject`: the logged-in username as passed in the header
2. `object`: the URL path for the web resource like "dataset1/item1"
3. `action`: HTTP method like GET, POST, PUT, DELETE, or the high-level actions you defined like "read-file", "write-blog"
For how to write authorization policy and other details, please refer to the [Casbin's documentation](https://casbin.org/).

## Example (without the middleware)

You can use Casbin without the middleware as per your authorization design, this is a sample example for that. You can create a lua module for OpenResty applications as shown [here](https://blog.openresty.com/en/or-lua-module/) or add it to your existing lua module:

- In the file where you want to use Casbin, use `local Enforcer = require("casbin")` inside the `content_by_lua_block`. Here is a sample describing usage for basic model/policy and ABAC model/policy:

**Basic model/policy example (nginx.conf file)**
```
worker_processes 1;

events {
    worker_connections 1024;
}

http {
    lua_package_path "$prefix/lua/?.lua;;";

    server {
        listen 8080 reuseport;

        location / {
            default_type text/plain;
            content_by_lua_block {
                local Enforcer = require("casbin")
                local model  = "examples/basic_model.conf" -- The model file path
                local policy  = "examples/basic_policy.csv" -- The policy file path
                
                local e = Enforcer:new(model, policy) -- The Casbin Enforcer
                ngx.say("The result is:")
                ngx.say(e:enforce("alice", "data1", "read")) -- The enforce function with its arguments
            }
        }
    }
}
```

**NOTE**: To use this example, you need to create an `examples` directory at the top level of your application `/` along with the `conf` directory. And then copy the [basic_model.conf](https://raw.githubusercontent.com/casbin/lua-casbin/master/examples/basic_model.conf) and [basic_policy.csv](https://raw.githubusercontent.com/casbin/lua-casbin/master/examples/basic_policy.csv) to that `examples` directory.

**ABAC model/policy example (nginx.conf file)**
```
worker_processes 1;

events {
    worker_connections 1024;
}

http {
    lua_package_path "$prefix/lua/?.lua;;";

    server {
        listen 8080 reuseport;

        location / {
            default_type text/plain;
            content_by_lua_block {
                local Enforcer = require("casbin")
                local model  = "examples/abac_rule_model.conf"
    		local policy  = "examples/abac_rule_policy.csv"
    		local sub1 = {
        		Name = "Alice",
        		Age = 16
    		}
    		local sub2 = {
        		Name = "Bob",
        		Age = 20
    		}
    		local sub3 = {
        		Name = "Alice",
        		Age = 65
    		}
    		local e = Enforcer:new(model, policy)
    		ngx.say("The result is:")
    		ngx.say(e:enforce(sub2, "/data1", "read"))
            }
        }
    }
}
```

**NOTE**: Similar to the former example to use this, you need to create an `examples` directory at the top level of your application `/` along with the `conf` directory. And then copy the [abac_rule_model.conf](https://raw.githubusercontent.com/casbin/lua-casbin/master/examples/abac_model.conf) and [abac_rule_policy.csv](https://raw.githubusercontent.com/casbin/lua-casbin/master/examples/abac_rule_policy.csv) to that `examples` directory.

Then use `sudo openresty -p $PWD/` to start the server and use `curl http://127.0.0.1:8080/` to fetch the page which for the above examples should output in:
```
The result is:
true
```

You can check other examples [here](https://github.com/casbin/lua-casbin/blob/master/tests/main/enforcer_spec.lua) and the Built-In Functions currently supported [here](https://github.com/casbin/lua-casbin/blob/master/src/model/FunctionMap.lua).

## Getting Help

- [Casbin](https://casbin.org/)

## License

This project is under the Apache 2.0 License.