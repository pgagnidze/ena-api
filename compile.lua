local parser = require "ena.parser"
local interpreter = require "ena.interpreter"
local compiler = require "ena.compiler"
local cjson = require "cjson"

local function containsShellCommands(input)
    if string.find(input, "%$%s*%b()") or
       string.find(input, "%$%s*%b\"\"") or
       string.find(input, "ბრძანება%s*%b\"\"") or
       string.find(input, "ბრძანება%s*%b()") or
       string.find(input, "გაუშვი%s*ბრძანება%s*%b()") or
       string.find(input, "გაუშვი%s*ბრძანება%s*%b\"\"") then
        return true
    end
    return false
end

local function containsPrintCommands(input)
    if string.find(input, "@%s*%b()") or
       string.find(input, "@%s*%b\"\"") or
       string.find(input, "@%s*[%w_]+") or
       string.find(input, "მაჩვენე%s+%b()") or
       string.find(input, "მაჩვენე%s+%b\"\"") or
       string.find(input, "მაჩვენე%s+[%w_]+") or
       string.find(input, "მაჩვენე%s+მნიშვნელობა%s*%b()") or
       string.find(input, "მაჩვენე%s+მნიშვნელობა%s*%b\"\"") or
       string.find(input, "მაჩვენე%s+მნიშვნელობა%s+[%w_]+") then
        return true
    end
    return false
end


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

    if containsShellCommands(json.code) then
        ngx.say(cjson.encode({ status = "error", error = "Shell commands are not supported" }))
        return
    end

    if containsPrintCommands(json.code) then
        ngx.say(cjson.encode({ status = "error", error = "Print commands are not supported" }))
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
