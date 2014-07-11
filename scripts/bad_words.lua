--[[
	Copyright (c) 2011-2014 Kevin Smith
	Licensed under the GNU General Public License v3.
	See LICENSE for more information.
--]]

function bad_words(body, muc, nick, message)
	words = {"sbwriel"}
	print("Received line from '" .. nick .. "' in '" .. muc .. "':")
	print(body)

	for _, word in pairs(words) do
		if string.len(string.match(body, word)) > 0 then
			--swiftob_reply_to(message, "Kicking "..nick.." for bad word "..word)
			swiftob_muc_kick(muc, nick)
		end
	end
end

--swiftob.register_listener(bad_words, { include_own_messages = false })
