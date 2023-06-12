local parser = require "ena.parser"
local interpreter = require "ena.interpreter"
local compiler = require "ena.compiler"
local cjson = require "cjson"

local function containsShellCommands(input)
    if
        string.find(input, "%$%s*%b()") or string.find(input, '%$%s*%b""') or string.find(input, 'ბრძანება%s*%b""') or
            string.find(input, "ბრძანება%s*%b()") or
            string.find(input, "გაუშვი%s*ბრძანება%s*%b()") or
            string.find(input, 'გაუშვი%s*ბრძანება%s*%b""')
     then
        return true
    end
    return false
end

ngx.header["Content-Type"] = "application/json"
ngx.req.read_body()
local method = ngx.req.get_method()
local data = ngx.req.get_body_data()

if method ~= "POST" then
    ngx.say(cjson.encode({status = "error", error = "მხოლოდ POST მეთოდია დაიშვება"})) -- Only POST method is allowed
    return
end

if data then
    local status, json = pcall(cjson.decode, data)
    if not status then
        ngx.say(cjson.encode({status = "error", error = "არასწორი JSON ფორმატი"})) -- Invalid JSON
        return
    end

    if containsShellCommands(json.code) then
        ngx.say(cjson.encode({status = "error", error = "შელის ბრძანებები არ დაიშვება"})) -- Shell commands are not supported
        return
    end

    local astStatus, ast = pcall(parser.parse, json.code)
    if not astStatus or not ast then
        ngx.say(cjson.encode({status = "error", error = "პარსინგის შეცდომა"})) -- Parsing error
        return
    end

    local compStatus, code = pcall(compiler.compile, ast, true)
    if not compStatus or not code then
        local errorMessage = string.match(code, ":.+:(.+)$")
        ngx.say(cjson.encode({status = "error", error = "კომპილაციის შეცდომა: " .. errorMessage})) -- Compile error
        return
    end

    local trace = {}
    local execStatus, result, output = pcall(interpreter.execute, code, trace, true)
    if not execStatus then
        local errorMessage = string.match(result, ":.+:(.+)$")
        ngx.say(cjson.encode({status = "error", error = "გაშვების შეცდომა: " .. errorMessage})) -- Execution error
        return
    end

    local body = {
        result = result,
        output = output
    }
    ngx.say(cjson.encode({status = "success", body = body}))
else
    ngx.say(cjson.encode({status = "error", error = "მონაცემები ვერ მოიძებნა"})) -- No data received
end
