--[[
	Copyright (c) 2014 Remko Tronçon
	Licensed under the GNU General Public License v3.
	See LICENSE for more information.
--]]

local function parse(args)
	local result = {}
	for _, arg in ipairs(args) do
		local _, _, parameter, value = string.find(arg, "^%-%-(%w+)=(.+)")
		if not parameter then
			_, _, parameter = string.find(arg, "^%-%-(%w+)")
		end
		if parameter then
			result[parameter] = value or true
		else
			table.insert(result, arg)
		end
	end
	return result
end

return { parse = parse }
