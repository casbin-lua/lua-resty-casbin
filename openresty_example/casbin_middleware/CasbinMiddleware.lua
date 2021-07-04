--Copyright 2021 The casbin Authors. All Rights Reserved.
--
--Licensed under the Apache License, Version 2.0 (the "License");
--you may not use this file except in compliance with the License.
--You may obtain a copy of the License at
--
--    http://www.apache.org/licenses/LICENSE-2.0
--
--Unless required by applicable law or agreed to in writing, software
--distributed under the License is distributed on an "AS IS" BASIS,
--WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
--See the License for the specific language governing permissions and
--limitations under the License.

local Enforcer = require("casbin")

CasbinMiddleware = {}

--[[
    - creates a new Casbin Middleware based on model path and policy path
    - if no model passed in, uses the default authz_model.conf
    - if no policy passed in, uses the default authz_policy.csv
]]
function CasbinMiddleware:new(next, modelPath, policyPath)
    local o = {}
    setmetatable(o, self)
    self.__index = self

    if not modelPath then modelPath = "casbin_middleware/authz_model.conf" end
    if not policyPath then policyPath = "casbin_middleware/authz_policy.csv" end
    local e = Enforcer:new(modelPath, policyPath)
    o.enforcer = e
    o.next = next -- function called if request is authorised
    return o
end

-- function to be called at every request
function CasbinMiddleware:check()
    if self:checkPermission() then
        if self.next then
            return self.next()
        end
        return true
    else
        self:requirePermission()
    end
end

--[[
    - checks permission using the enforce function and returns its result
    - Currently, gets user from the value of the header "username"
    - Customize this based on your authentication method
]]
function CasbinMiddleware:checkPermission()
    local headers = ngx.req.get_headers()

    local usr = headers["username"]
    local path = ngx.var.request_uri
    local method = ngx.var.request_method

    -- if usr, path and method are not nil, continue
    if usr and path and method then
        return self.enforcer:enforce(usr, path, method)
    end

    return false
end

-- if request is unauthorized, returns a 403 HTTP status code
function CasbinMiddleware:requirePermission()
	-- Changes the status to 403
    ngx.status = 403
    -- Shows the 403 forbidden page, customize this based on your application
    return ngx.exit(403)
end