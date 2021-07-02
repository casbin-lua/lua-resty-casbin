local http = require("socket.http")

local function getHTTPCode(page, username, HTTPMethod)
    local _, code, _, _ = http.request{url = "http://127.0.0.1:8080" .. page, headers = {["username"] = username}, method = HTTPMethod}
    return code
end

describe("Middleware Tests", function ()
    it("Homepage Tests", function ()
        assert.is.Same(getHTTPCode("/", "anonymous", "GET"), 200)
        assert.is.Same(getHTTPCode("/", "alice", "GET"), 200)
        assert.is.Same(getHTTPCode("/", "anonymous", "POST"), 403)
        assert.is.Same(getHTTPCode("/", "alice", "POST"), 200)
        assert.is.Same(getHTTPCode("/", "alice", "PUT"), 200)
    end)

    it("Resource Tests", function ()
        assert.is.Same(getHTTPCode("/resource1", "anonymous", "GET"), 403)
        assert.is.Same(getHTTPCode("/resource1", "alice", "GET"), 200)
        assert.is.Same(getHTTPCode("/resource1", "anonymous", "POST"), 403)
        assert.is.Same(getHTTPCode("/resource1", "alice", "POST"), 200)
        assert.is.Same(getHTTPCode("/dataset1/res1", "anonymous", "GET"), 403)
        assert.is.Same(getHTTPCode("/dataset1/res1", "alice", "GET"), 200)
    end)

    it("RBAC Tests", function ()
        assert.is.Same(getHTTPCode("/", "admin", "GET"), 200)
        assert.is.Same(getHTTPCode("/", "alice", "GET"), 200)
        assert.is.Same(getHTTPCode("/res", "admin", "POST"), 200)
        assert.is.Same(getHTTPCode("/res", "alice", "POST"), 200)
    end)
end)