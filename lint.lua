--[[
	Copyright (c) 2014 Remko Tronçon
	Licensed under the GNU General Public License v3.
	See LICENSE for more information.
--]]

--
-- Tool to check global variable assignments
--

local os = require('os')
local io = require('io')
local table = require('table')

local CHECK_TMP = 'check.tmp'

local function check_set_local_variable(file, line)
	-- Match 5.1 style
	local _, _, lineno, var = string.find(line, '%[(%d+)%]%s+SETGLOBAL%s+.*; (.*)')
	if not lineno then
		-- Match 5.2 style
		_, _, lineno, var = string.find(line, '%[(%d+)%]%s+SETTABUP%s+.*; _ENV "(.*)"')
	end

	if lineno then
		print(string.format("%s:%s: Writing global variable '%s'", file, lineno, var))
		return true
	end
	return false
end

local function check_get_local_variable(file, line)
	-- Match 5.1 style
	local _, _, lineno, var = string.find(line, '%[(%d+)%]%s+GETGLOBAL%s+.*; (.*)')
	if not lineno then
		-- Match 5.2 style
		_, _, lineno, var = string.find(line, '%[(%d+)%]%s+GETTABUP%s+.*; _ENV "(.*)"')
	end

	if lineno and not _G[var] then
		print(string.format("%s:%s: Reading global variable '%s'", file, lineno, var))
		return true
	end
	return false
end

local found_errors = false
for i = 1, #arg do
	local file = arg[i]
	local result = os.execute(string.format('luac -p -l %s > %s', file, CHECK_TMP))
	if result ~= 0 and result ~= true then 
		error(string.format("Error compiling %s", file)) 
	end
	local f = io.open(CHECK_TMP, 'r')
	while true do
		local line = f:read()
		if not line then break end
		found_errors = found_errors or check_set_local_variable(file, line)
		found_errors = found_errors or check_get_local_variable(file, line)
	end
	f:close()
	os.execute('rm -f check.tmp')
end

if found_errors then os.exit(-1) end

