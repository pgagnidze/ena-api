local mote = require("mote")
local parser = require("ena.parser")
local interpreter = require("ena.interpreter")
local compiler = require("ena.compiler")
local common = require("ena.helper.common")

mote.configure_cors({
	origin = "*",
	methods = "GET, POST, PUT, DELETE, PATCH, OPTIONS",
	headers = "X-CSRF-Token, X-Requested-With, Accept, Accept-Version, Content-Length, Content-MD5, Content-Type, Date, X-Api-Version",
	max_age = 86400,
})

local function contains_shell_commands(input)
	if
		string.find(input, "%$%s*%b()")
		or string.find(input, '%$%s*%b""')
		or string.find(input, 'ბრძანება%s*%b""')
		or string.find(input, "ბრძანება%s*%b()")
		or string.find(input, "გაუშვი%s*ბრძანება%s*%b()")
		or string.find(input, 'გაუშვი%s*ბრძანება%s*%b""')
	then
		return true
	end
	return false
end

local function error_response(ctx, status, message)
	ctx.response.status = status
	ctx.response.body = { status = "error", error = message }
end

mote.post("/compile", function(ctx)
	if not ctx.request.body or not ctx.request.body.code then
		return error_response(ctx, 400, "მონაცემები ვერ მოიძებნა")
	end

	local code = ctx.request.body.code

	if contains_shell_commands(code) then
		return error_response(ctx, 400, "შელის ბრძანებები არ დაიშვება")
	end

	local ast_status, ast = pcall(parser.parse, code)
	if not ast_status or not ast then
		local furthest_match = common.getFurthestMatch()
		local newline_count = common.count("\n", code:sub(1, furthest_match))
		local error_line = newline_count + 1
		return error_response(ctx, 400, "სინტაქსური შეცდომა ამ ხაზზე: " .. error_line)
	end

	local comp_status, compiled = pcall(compiler.compile, ast, true)
	if not comp_status or not compiled then
		local error_message = string.match(compiled, ":.+:(.+)$") or compiled
		return error_response(ctx, 400, "კომპილაციის შეცდომა: " .. error_message)
	end

	local trace = {}
	local exec_status, result, output = pcall(interpreter.execute, compiled, trace, true)
	if not exec_status then
		local error_message = string.match(result, ":.+:(.+)$") or result
		return error_response(ctx, 500, "გაშვების შეცდომა: " .. error_message)
	end

	ctx.response.body = { status = "success", body = { result = result, output = output } }
end)

local port = tonumber(os.getenv("PORT")) or 8080
local app = mote.create({ host = "0.0.0.0", port = port })
print("ena-api listening on :" .. port)
app:run()
