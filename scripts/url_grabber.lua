--[[
	Copyright (c) 2011-2014 Kevin Smith
	Licensed under the GNU General Public License v3.
	See LICENSE for more information.
--]]

function url_grabber(body, muc, nick, message)
	local url = body:match("http://.%S+")
	print("Looking for URL")
	print(url)
	if url then
		print ("found")
		local http = require("socket.http")
		http.TIMEOUT = 5
		--r, c, h = http.request({method = "HEAD", url = url})
		--clen = tonumber(h["content-length"])
		--if clen and clen > 0 and clen < 1024 * 1024 then
			b, c, h = http.request(url)
			local subjectish = b:match("<title>.+</title>")
			print("subjectish")
			print(subjectish)
			if subjectish then 
				local subject = string.gsub(subjectish, "</?title>", "")
				subject = subject:gsub("\n", " ");
				if subject then
					swiftob_reply_to(message, url..":\n"..subject)
				end
			end
		--else
		--	print("Skipping because missing or too long:")
		--	print(clen)
		--end
	end
end

--swiftob.register_listener(url_grabber, { include_own_messages = false })
