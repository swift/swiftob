--[[
	Copyright (c) 2014 Remko Tronçon
	Licensed under the GNU General Public License v3.
	See LICENSE for more information.
--]]

local function tick()
	print("Tick")
end

swiftob.register_periodical{
	interval = 10,
	callback = tick,
}
