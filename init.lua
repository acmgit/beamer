--[[
   ****************************************************************
   *******                      Beam                         ******
   *******       A Mod to transfer nodes in Minetest         ******
   *******                  License: GPL 3.0                 ******
   *******                     by A.C.M.                     ******
   ****************************************************************
--]]

beamer = {}
local b = beamer

-- Colors for Chat
b.green = minetest.get_color_escape_sequence('#00FF00')
b.red = minetest.get_color_escape_sequence('#FF0000')
b.orange = minetest.get_color_escape_sequence('#FF6700')
b.blue = minetest.get_color_escape_sequence('#0000FF')
b.yellow = minetest.get_color_escape_sequence('#FFFF00')
b.purple = minetest.get_color_escape_sequence('#FF00FF')
b.pink = minetest.get_color_escape_sequence('#FFAAFF')
b.white = minetest.get_color_escape_sequence('#FFFFFF')
b.black = minetest.get_color_escape_sequence('#000000')
b.grey = minetest.get_color_escape_sequence('#888888')
b.light_blue = minetest.get_color_escape_sequence('#8888FF')
b.light_green = minetest.get_color_escape_sequence('#88FF88')
b.light_red = minetest.get_color_escape_sequence('#FF8888')

b.version = "1.2"
b.modname = minetest.get_current_modname()
b.path = minetest.get_modpath(beamer.modname)
b.S = nil
b.ignore = {}

if(minetest.get_translator ~= nil) then
    b.S = minetest.get_translator(beamer.modname)

else
    b.S = function ( s ) return s end

end

local S = b.S

b.servername = minetest.settings:get("beamer.servername") or "Local"
b.irc = minetest.settings:get_bool("beamer.irc_online") or false
b.irc_name = minetest.settings:get("beamer.irc_server_ip") or "libera.chat"
b.irc_channelname = minetest.settings:get("beamer.irc_channelname") or "##MT_Data"

b.error = {}

local nr = 1
b.error.player_unknown              = nr
b.error.player_inventory_is_full    = nr + 1
b.error.locked_beam                 = nr + 2
b.error.unkown_item                 = nr + 3

b.error.string = {
                    [b.error.player_unknown]                = b.red .. S("Player unkown or offline."),
                    [b.error.player_inventory_is_full]      = b.red .. S("Inventory is full."),
                    [b.error.locked_beam]                   = b.red .. S("Locked beaming."),
                    [b.error.unkown_item]                   = b.red .. S("Unknown Item."),
                }

b.package = {
                ["server_from"] = "",
                ["server_to"] = "",
                ["sender"] = "",
                ["receiver"] = "",
                ["items"] = "",
}

-- ***************************************** Includes ************************************

dofile(b.path .. "/lib.lua")
dofile(b.path .. "/chatcommands.lua")


-- ***************************************** Main ****************************************

minetest.register_node("beamer:beamer", {
        description = S("Beamer"),
        paramtype2 = "facedir",
        drawtype = "nodebox",
        -- top, bottom, right, left, back, front
        tiles = {   "beamer_beamer_top.png",
                    "beamer_beamer_bottom.png",
                    "beamer_beamer_side_right.png",
                    "beamer_beamer_side_left.png",
                    "beamer_beamer_side_right.png",
                    "beamer_beamer_side_right.png"
                },
        groups = { cracky = 1, },
        is_ground_content = false,
        on_punch = function(pos, node, puncher, pointed_thing)
                        b.lib.punch_beamer(pos, node, puncher, pointed_thing)

                    end,
})

minetest.register_craft({
	output = "beamer:beamer",
	recipe = {	{"dye:blue", "default:obsidian_glass", "dye:red"},
				{"default:diamondblock", "default:mese", "default:diamondblock"},
                {"bucket:bucket_water", "default:furnace", "bucket:bucket_lava"}
			},
})

minetest.register_on_player_receive_fields(function(player, formname, fields)
    if formname == "beamer:inputform" and player then
        local username = player:get_player_name()
        local servername = fields.servername or "local"
        local playername = fields.playername or ""
        local node = fields.node or ""
        local amount = fields.amount or 0

        if fields.button_send then

            local pkg = {
                            ["error"] = nil,
                            ["server_from"] = b.servername,
                            ["server_to"] = servername,
                            ["sender"] = username,
                            ["receiver"] = playername,
                            ["items"] = node .. " " .. amount,
                        }

            b.lib.send(pkg)

        end -- if fields.button_send


        if fields.button_exit then
            minetest.chat_send_player(username, b.green .. S("Beaming finished."))
            b.beam_far = false

        end -- if fields.button_exit

    end -- if formname

end)

minetest.log("action", b.modname .. " V " .. b.version .. " successfully loaded.")
