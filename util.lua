local function have_lua52()
	local _, _, major, minor = string.find(_VERSION, "^Lua (%d+)%.(%d)")
	if tonumber(major) > 5 then return true
	elseif tonumber(major) == 5 then return tonumber(minor) >= 2
	else return false end
end

local function load_file(file, env)
	if have_lua52() then
		return loadfile(file, 't', env)
	else
		local script, message = loadfile(file)
		if not script then return script, message end
		setfenv(script, env)
		return script
	end
end

return { load_file = load_file }
