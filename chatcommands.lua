local b = beamer
local S = beamer.S

minetest.register_chatcommand("beamer", {
	params = "servername | toggle",
	description = "servername " .. S("Tells you the servername.") .. "\n" ..
                  "toggle " .. S("Locks or unlocks beaming."),

    func = function(player, param)
        if(string.match(param, "servername")) then
            b.lib.get_servername(player)

        elseif(string.match(param, "toggle")) then
            b.lib.toggle_beam(player)

        else
            minetest.chat_send_player(player,b.red .. S("Usage: servername | toggle"))

        end

	end,
}) -- chatcommand "servername"
