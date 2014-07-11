--[[
	Copyright (c) 2014 Remko Tronçon
	Licensed under the GNU General Public License v3.
	See LICENSE for more information.
--]]

--
-- This module implements serialization of values so they can be read
-- back using load()
--

-- Serialize values of primitive types
local function serialize_value(value)
	local result = tostring(value)
	if type(value) == 'number' then return result
	elseif type(value) == 'boolean' then return result
	elseif type(value) == 'string' then return string.format("%q", result)
	else error("Cannot serialize data of type " .. type(value))
	end
end

-- Serialize tables
local function serialize_table(table, indent, accumulator, history)
	local INDENT = '  '
	local accumulator = accumulator or ''
	local history = history or {}
	local indent = indent or ''
	accumulator = accumulator .. '{'
	history[table] = true
	local is_first = true
	for key, value in pairs(table) do
		if not is_first then
			accumulator = accumulator .. ','
		end
		is_first = false
		accumulator = accumulator .. '\n' .. indent .. INDENT .. '[' .. serialize_value(key) .. '] = '
		if type(value) == 'table' then
			if history[value] then
				error("Cannot serialize self-referencing tables")
			else
				accumulator = serialize_table(value, indent .. INDENT, accumulator, history)
			end
		else
			accumulator = accumulator .. serialize_value(value)
		end
	end
	history[table] = false
	if not is_first then
		accumulator = accumulator .. '\n' .. indent
	end
	accumulator = accumulator .. '}'
	return accumulator
end

local function serialize(value)
	if type(value) == "table" then return serialize_table(value)
	else return serialize_value(value) end
end

return { serialize = serialize }
