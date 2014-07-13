--[[
	Copyright (c) 2014 Remko Tronçon
	Licensed under the GNU General Public License v3.
	See LICENSE for more information.
--]]

--
-- This module implements serialization of values so they can be read
-- back using load()
--

local function insert(t, ...)
	for _, v in pairs({...}) do
		table.insert(t, v)
	end
end

-- Serialize values of primitive types
local function serialize_value(value)
	local result = tostring(value)
	if type(value) == 'number' then return result
	elseif type(value) == 'boolean' then return result
	elseif type(value) == 'string' then return string.format("%q", result)
	else error("Cannot serialize data of type " .. type(value))
	end
end

-- Serialize tables.
-- Returns a list of strings.
local function serialize_table(table, indent, accumulator, history)
	local INDENT = '  '
	local accumulator = accumulator or {}
	local history = history or {}
	local indent = indent or ''
	insert(accumulator, '{')
	history[table] = true
	local is_first = true
	for key, value in pairs(table) do
		if not is_first then
			insert(accumulator, ',')
		end
		is_first = false
		insert(accumulator, '\n', indent, INDENT, '[', serialize_value(key), '] = ')
		if type(value) == 'table' then
			if history[value] then
				error("Cannot serialize self-referencing tables")
			else
				serialize_table(value, indent .. INDENT, accumulator, history)
			end
		else
			insert(accumulator, serialize_value(value))
		end
	end
	history[table] = false
	if not is_first then
		insert(accumulator, '\n', indent)
	end
	insert(accumulator, '}')
	return accumulator
end

local function serialize(value)
	if type(value) == "table" then return table.concat(serialize_table(value))
	else return serialize_value(value) end
end

return { serialize = serialize }
