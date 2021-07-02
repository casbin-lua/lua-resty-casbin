# lua-resty-casbin

lua-resty-casbin is an authorization plugin/middleware for OpenResty, based on [lua-casbin](https://github.com/casbin/lua-casbin/).

## Installation

If you do not have LuaRocks installed for OpenResty then install it by:

```
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

Then install Casbin's latest current release (v1.11.0) using:

```
sudo /usr/local/openresty/luajit/bin/luarocks install https://raw.githubusercontent.com/casbin/lua-casbin/master/casbin-1.11.0-1.rockspec

```

(For detailed setup instructions, check it [here](https://github.com/casbin/lua-casbin/blob/master/Setup-OpenResty.md))


## Usage

- Copy the `casbin_middleware` folder to the top level (`/`) of your OpenResty application.
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

## Getting Help

- [Casbin](https://casbin.org/)

## License

This project is under the Apache 2.0 License.