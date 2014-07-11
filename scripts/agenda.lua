--[[
	Copyright (c) 2011-2014 Kevin Smith
	Licensed under the GNU General Public License v3.
	See LICENSE for more information.
--]]

agendas = {}
currents = {}

function full_agenda(from)
	fullagenda = {}
	fullagenda[1] = "Roll call"
	fullagenda[2] = "Agenda bashing"
	for i, v in ipairs(agendas[from]) do
		table.insert(fullagenda, v)
	end
	table.insert(fullagenda, "Date of next meeting")
	table.insert(fullagenda, "Any other business")
	return fullagenda
end

function agenda_full_command(command, params, message)
	from = swiftob.jid.to_bare(message['from'])
	ensure_loaded(from)
	agenda = agendas[from]
	fullagenda = full_agenda(from)
	reply = ""
	for i, v in ipairs(fullagenda) do
		reply = reply..i..") "..v.."\n"
	end
	reply = reply.."Fini"
	swiftob.reply_to(message, reply)
end

function agenda_append_command(command, params, message)
	from = swiftob.jid.to_bare(message['from'])
	agenda_append(from, params)
	agenda_save(from)
	swiftob.reply_to(message, "Done.")
end

function agenda_up_command(command, params, message)
	from = swiftob.jid.to_bare(message['from'])
	ensure_loaded(from)
	up = tonumber(params)
	if up == nil then up = 1 end
	currents[from] = currents[from] + up
	if currents[from] <= 0 then currents[from] = 1 end
	item = full_agenda(from)[currents[from]]
	if item == nil then item = "Fini." end
	reply = currents[from]..") "..item
	swiftob.reply_to(message, reply)
end


function agenda_clear_command(command, params, message)
	from = swiftob.jid.to_bare(message['from'])
	agendas[from] = {}
	agenda_save(from)
	swiftob.reply_to(message, "Done.")
end

function agenda_save(from)
	agenda = agendas[from]
	swiftob.set_setting("count@@@"..from, #agenda)
	for i, v in ipairs(agenda) do
		swiftob.set_setting(i.."@@@"..from, v)
	end
end

function ensure_loaded(from)
	if agendas[from] == nil then
		agenda_load(from)
	end
end

function agenda_load(from)
	agendas[from] = {}
	currents[from] = 0
	num_items = tonumber(swiftob.get_setting("count@@@"..from) or "")
	if num_items == nil then num_items = 0 end
	for i = 1, num_items do
		agenda_append(from, swiftob.get_setting(i.."@@@"..from) or "")
	end
end

function agenda_append(from, item)
	ensure_loaded(from)
	agenda = agendas[from]
	table.insert(agenda, item)
	agendas[from] = agenda
end

swiftob.register_command{name = "agenda", allowed_role = "anyone", description = "print the full agenda", 
	callback = agenda_full_command}
swiftob.register_command{name = "agendaappend", allowed_role = "owner", description = "append an item to the agenda", 
	callback = agenda_append_command}
swiftob.register_command{name = "agendaclear", allowed_role = "owner", description = "clear the agenda", 
	callback = agenda_clear_command}
swiftob.register_command{name = "agendaup", allowed_role = "owner", description = "Moves the current counter by n, and returns the current agenda item", 
	callback = agenda_up_command}



