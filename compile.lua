local parser = require "ena.parser"
local interpreter = require "ena.interpreter"
local compiler = require "ena.compiler"
local cjson = require "cjson"

ngx.header["Content-Type"] = "application/json"
ngx.req.read_body()
local method = ngx.req.get_method()
local data = ngx.req.get_body_data()

if method ~= "POST" then
    ngx.say(cjson.encode({ status = "error", error = "Only POST method is allowed" }))
    return
end

if data then
    local status, json = pcall(cjson.decode, data)
    if not status then
        ngx.say(cjson.encode({ status = "error", error = "Invalid JSON" }))
        return
    end

    local astStatus, ast = pcall(parser.parse, json.code)
    if not astStatus or not ast then
        ngx.say(cjson.encode({ status = "error", error = "Parsing failed" }))
        return
    end

    local compStatus, code = pcall(compiler.compile, ast)
    if not compStatus or not code then
        ngx.say(cjson.encode({ status = "error", error = "Compilation failed" }))
        return
    end

    local trace = {}
    local execStatus, result = pcall(interpreter.execute, code, trace)
    if not execStatus or not result then
        ngx.say(cjson.encode({ status = "error", error = "Execution failed" }))
        return
    end

    local body = {
        result = result
    }
    ngx.say(cjson.encode({ status = "ok", body = body }))
else
    ngx.say(cjson.encode({ status = "error", error = "No data received" }))
end
