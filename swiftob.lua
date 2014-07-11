--[[
	Copyright (c) 2014 Remko Tronçon
	Licensed under the GNU General Public License v3.
	See LICENSE for more information.
--]]

local table = require('table')
local debug = require('debug')
local io = require('io')
local os = require('os')

local sluift = require('sluift')
local environment = require('environment')
local serialize = require('serialize')
local storage = require('storage')

-- The (maximum) interval between iterators of the event loop.
-- This shouldn't really impact anything, so better leave it as it is.
local SLEEP_INTERVAL = 10
local SCRIPTS_DIR = "scripts"

-- Forward declarations
local reload

local client = nil
local tasks = {}
local commands = {}
local listeners = {}
local periodicals = {}
local quit_requested = false
local restart_requested = false

local function have_lua52()
	local _, _, major, minor = string.find(_VERSION, "^Lua (%d+)%.(%d)")
	if tonumber(major) > 5 then return true
	elseif tonumber(major) == 5 then return tonumber(minor) >= 2
	else return false end
end

local function call(f)
	return xpcall(f, function(e) print(debug.traceback(e)) end)
end

local function quit()
	quit_requested = true
end

local function restart()
	restart_requested = true
end

local function is_role_allowed(role, allowed_role)
	if role == "owner" then return true end
	for _, allowed_role in pairs(allowed_role) do
		if allowed_role == 'anyone' or role == allowed_role then return true end
	end
	return false
end

local function get_role(jid)
	-- TODO
end

local function command_descriptions_for_jid(jid, is_muc)
	local role = get_role(jid)
	local bang = ''
	if is_muc then bang = '!' end
	local result = {'Available commands:'}
	for _, command in pairs(commands) do
		if is_role_allowed(role, command.allowed_role) then
			table.insert(result, bang .. command.name .. ": " .. command.description)
		end
	end
	return table.concat(result, '\n')
end

local function register_task(task) 
	table.insert(tasks, {
		next_activation_time = os.time(),
		coroutine = coroutine.create(task)
	})
end

local function register_command(command)
	if not command.name then error("Missing command name") end
	if not command.callback then error("Missing command callback") end
	command.description = command.description or ""
	command.allowed_role = command.allowed_role or "anyone"
	table.insert(commands, command)
end

local function register_listener(listener, options)
	options = options or {}
	if options.include_own_messages == nil then
		options.include_own_messages = true
	end
	table.insert(listeners, {
		callback = listener,
		include_own_messages = options.include_own_messages
	})
end

local function register_periodical(periodical)
	if not periodical.callback then error("Missing callback") end
	if not periodical.interval then error("Missing interval") end
	table.insert(periodicals, {
		interval = periodical.interval,
		callback = periodical.callback,
		next_activation_time = os.time()
	})
end

local function reply_to(message, body, options)
	local options = options or {}
	local to = message['from']
	local message_type = message.type
	if options.out_of_muc then 
		to = sluift.jid.to_bare(to)
		message_type = 'chat'
	end

	if message_type == 'groupchat' then
		body = sluift.jid.resource(message['from']) .. ': ' .. body
	end

	if client:is_connected() then
		client:send_message{to = to, type = message_type, body = body}
	else
		print("Dropping message")
	end
end

local function load_script(script_file, privileged)
	local script_storage = storage.load(script_file .. '.storage')

	-- Create swiftob interface
	local swiftob = {
		register_task = register_task,
		register_command = register_command,
		register_listener = register_listener,
		register_periodical = register_periodical,
		get_setting = function(...) script_storage:get_setting(...) end,
		set_setting = function(...) script_storage:set_setting(...) end,
		reply_to = reply_to,

		-- Sluift modules
		jid = sluift.jid,
		base64 = sluift.base64,
		idn = sluift.idn,
		crypto = sluift.crypto,
		fs = sluift.fs,
		itunes = sluift.itunes,
		disco = sluift.disco,

		-- Sluift functions
		copy = sluift.copy,
		with = sluift.with,
		read_file = sluift.read_file,
		tprint = sluift.tprint
	}

	-- Add privileged commands
	if privileged then
		swiftob.quit = quit
		swiftob.restart = restart
		swiftob.reload = reload
		swiftob.command_descriptions_for_jid = command_descriptions_for_jid
	end

	-- Add fallback to client
	setmetatable(swiftob, {
		__index = function(table, key) 
			if client then
				local f = client[key]
				if f then
					return function(...) 
						return f(client, ...) 
					end
				end
			end
		end
	})

	-- Create the script sandbox environment
	local env = environment.new_environment()
	env.swiftob = swiftob
	env.sleep = coroutine.yield

	-- Load the script
	local script, message
	if have_lua52() then
		script, message = loadfile(script_file, 't', env)
		if not script then 
			print("Unable to read " .. script_file .. ": " .. message)
			return 
		end
	else
		script, message = loadfile(script_file)
		if not script then 
			print("Unable to read " .. script_file .. ": " .. message)
			return 
		end
		setfenv(script, env)
	end

	local result, message = call(script)
	if not result then
		print(message)
	end
end

local function load_privileged_script(script_file)
	load_script(script_file, true)
end

local function parse_command(message)
	local body = message['body']
	if message['type'] ~= 'groupchat' and not string.find(body, '^!') then
		body = '!' .. body
	end
	local _, _, command_name, arguments = string.find(body, "^!(%w+)%s+(.*)")
	if not command_name then
		_, _, command_name = string.find(body, "^!(%w+)$")
	end
	return command_name, arguments
end

local function get_earliest_activation_time()
	-- Initialize value
	local result
	if #tasks > 0 then
		result = tasks[1].next_activation_time
	elseif #periodicals > 0 then
		result = periodicals[1].next_activation_time
	else
		return SLEEP_INTERVAL
	end

	-- Find lowest task
	for _, task in pairs(tasks) do
		if task.next_activation_time < result then
			result = task.next_activation_time
		end
	end

	-- Find lowest periodical
	for _, periodical in pairs(periodicals) do
		if periodical.next_activation_time < result then
			result = periodical.next_activation_time
		end
	end

	return result
end

-- reloads all the scripts
function reload() 
	tasks = {}
	commands = {}
	listeners = {}
	periodicals = {}

	print("Loading scripts ...")
	load_privileged_script('builtins.lua')
	local scripts = sluift.fs.list(SCRIPTS_DIR)
	if scripts then
		for _, script in pairs(scripts) do
			if sluift.fs.is_file(script) and string.find(script, "%.lua$") then
				load_script(script)
			end
		end
	end
end


-- Load all the scripts
reload()

-- Start the loop
local jid = os.getenv("SWIFTOB_JID")
local password = os.getenv("SWIFTOB_PASS")
--sluift.debug = 1
client = sluift.new_client(jid, password)
while not quit_requested do
	restart_requested = false
	client:connect(function() 
		print("Connected")
		client:send_presence{type = 'available'}
		while not quit_requested and not restart_requested do
			local current_time = os.time()

			-- Process the tasks
			local new_tasks = {}
			for _, task in pairs(tasks) do
				if task.next_activation_time <= current_time then
					local success, sleep_time = coroutine.resume(task.coroutine)
					if coroutine.status(task.coroutine) ~= "dead" then
						task.next_activation_time = current_time + sleep_time
						table.insert(new_tasks, task)
					end
				else
					table.insert(new_tasks, task)
				end
			end
			tasks = new_tasks
			
			-- Process the periodicals
			for _, periodical in pairs(periodicals) do
				if periodical.next_activation_time <= current_time then
					call(periodical.callback)
					periodical.next_activation_time = current_time + periodical.interval
				end
			end

			-- Get the next event time
			local next_activation_time = get_earliest_activation_time()
			local event = client:get_next_event{timeout = next_activation_time - current_time}

			-- Dispatch the event
			if event and (event['type'] == 'message' or event['type'] == 'groupchat') then
				local message = sluift.copy(event)
				message.type = message.message_type
				message.message_type = nil

				-- Notify listeners 
				for _, listener in pairs(listeners) do
					-- TODO: Check own messages
					call(function() listener.callback(message) end)
				end

				-- Handle commands
				local command_name, arguments = parse_command(message)
				if command_name then
					for _, command in pairs(commands) do
						if command.name == command_name then
							call(function() command.callback(command_name, arguments, message) end) 
						end
					end
				end
			end
		end
	end)
end
