local b = beamer
local S = beamer.S

minetest.register_chatcommand("beamer", {
	params = "servername | toggle | reconnect",
	description = "servername " .. S("Tells you the servername.") .. "\n" ..
                  "toggle " .. S("Locks or unlocks beaming."),

    func = function(player, param)
        if(string.match(string.lower(param), "servername")) then
            b.lib.get_servername(player)

        elseif(string.match(string.lower(param), "toggle")) then
            b.lib.toggle_beam(player)

        elseif(string.match(string.lower(param), "reconnect")) then
            if minetest.get_player_privs(player).kick then
                if (not b.irc) then
                    minetest.chat_send_player(player, b.red .. S("Far beaming is off. Ask your Admin."))

                elseif(not b.irc_running) then
                    b.lib.irc_connect()
                    b.irc_running = true
                    b.lib.reconnect_number = 0
                    minetest.chat_send_player(player, b.green .. S("Beamer is trying to reconnect."))

                else
                    minetest.chat_send_player(player, b.green .. S("Beamer is already online."))

                end

            end

        else
            minetest.chat_send_player(player,b.red .. "Usage: servername | toggle | reconnect")

        end

	end,
}) -- chatcommand "servername"

minetest.register_chatcommand("tricorder", {
    params = "",
    description = S("Scans the object in your hand."),
    func = function(player)
        b.lib.show_item(player)

    end

}) -- chatcommand "tricorder"
