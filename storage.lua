--[[
	Copyright (c) 2014 Remko Tronçon
	Licensed under the GNU General Public License v3.
	See LICENSE for more information.
--]]

--
-- This module implements a persistent key/value storage.
--

local serialize = require('serialize')

local storage_mt = {}

local function load(file)
	local storage = { file = file, data = {}}
	local data_chunk = loadfile(file)
	if data_chunk then
		storage.data = data_chunk()
		if type(storage.data) ~= "table" then
			storage.data = {}
		end
	end
	setmetatable(storage, storage_mt)
	return storage
end

local function save(storage)
	local f = io.open(storage.file, 'w')
	f:write('return ' .. serialize.serialize(storage.data))
	f:close()
end

local function get_setting(storage, key)
	return storage.data[key]
end

local function set_setting(storage, key, value)
	if type(key) ~= 'string' then error("Setting key needs to be a string") end
	if not serialize.serialize(value) then error("Setting value is not serializable") end
	storage.data[key] = value
	save(storage)
end

storage_mt.__index = {
	save = save,
	get_setting = get_setting,
	set_setting = set_setting
}

return {
	load = load
}
