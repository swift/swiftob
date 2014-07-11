--[[
	Copyright (c) 2011-2014 Kevin Smith
	Licensed under the GNU General Public License v3.
	See LICENSE for more information.
--]]

local http = require("socket.http")

last_fetched = 0
xeps_by_number = {}
xeps_by_shortname = {}

function parse_xeps(body) 
	for xep_string in body:gmatch("<xep>.-</xep>") do
		local number = xep_string:match("<number>(.+)</number>")
		local name = xep_string:match("<name>(.+)</name>")
		local xeptype = xep_string:match("<type>(.+)</type>")
		local status = xep_string:match("<status>(.+)</status>")
		local updated = xep_string:match("<updated>(.+)</updated>")
		local shortname = xep_string:match("<shortname>(.+)</shortname>")
		local abstract = xep_string:match("<abstract>(.+)</abstract>"):gsub("\n", "")
		xep = {number=number, name=name, type=xeptype, status=status, updated=updated, shortname=shortname, abstract=abstract}
		xeps_by_number[tonumber(number)] = xep
		xeps_by_shortname[shortname:upper()] = xep
	end
end

function update_xeps()
	http.TIMEOUT = 5
	if os.time() > (last_fetched + 30 * 60) then
		b, c, h = http.request("http://xmpp.org/extensions/xeps.xml")
		if c == 200 then
			last_fetched = os.time()
			parse_xeps(b)
		end
	end
end

function xep_to_string(xep)
	return "XEP-"..xep["number"].."(Shortname "..xep["shortname"].."): "..xep["name"].."\n"..xep["type"].."/"..xep["status"].." Updated: "..xep["updated"]
end

function xep_command(command, params, message)
	update_xeps()
	local xep_number = tonumber(params)
	local xep
	if xep_number then
		xep = xeps_by_number[xep_number]
	else
		xep = xeps_by_shortname[params:upper()]
	end
	local reply
	if xep then
		reply = xep_to_string(xep)
	else 
		reply = "Sorry, that XEP doesn't seem to exist"
	end
	swiftob.reply_to(message, reply)
end

swiftob.register_command{
	name = "xep", 
	description = "Lookup XEP data", 
	callback = xep_command
}
