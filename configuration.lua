local util = require('util')

local function load(file)
	local current_script = nil
	local configuration = { scripts = {} }
	local env = {}
	setmetatable(env, { __index = configuration, __newindex = configuration })
	env.script = function(name)
		current_script = name
		configuration.scripts[name] = {}
		setmetatable(env, { 
			__index = configuration.scripts[name],
			__newindex = configuration.scripts[name]
		})
	end
	local configuration_chunk = assert(util.load_file(file, env))
	configuration_chunk()
	return configuration
end

return { load = load }
