--[[
	Copyright (c) 2011-2014 Kevin Smith
	Licensed under the GNU General Public License v3.
	See LICENSE for more information.
--]]

local function friendly_version(version) 
	local result = version['name']
	if version['version'] and version['version'] ~= "" then
		result = result .. " version " .. version['version']
	end
	if version['os'] and version['os'] ~= "" then
		result = result .. " on " .. version['os']
	end
	return result
end

local function version_command(command, params, message)
	 --jid = swiftob_muc_input_to_jid(params, message['from'])
	 swiftob.tprint(message)
	 local jid = params
	 if jid then
			local version, err = swiftob.get_software_version{to = jid, timeout = 10000}
			if version then
				swiftob.reply_to(message, params .. " is running " .. friendly_version(version))
			else
				swiftob.reply_to(message, "Error getting version from "..params..": " .. err)
			end
	 end
end

swiftob.register_command{
	name = "version", 
	description = "Ask for someone's version", 
	callback = version_command}
