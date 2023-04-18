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

b.version = "1.1"
b.modname = minetest.get_current_modname()
b.path = minetest.get_modpath(beamer.modname)
b.S = nil
b.list = {}
b.to = {}
b.ignore = {}

if(minetest.get_translator ~= nil) then
    b.S = minetest.get_translator(beamer.modname)

else
    b.S = function ( s ) return s end

end

local S = b.S
b.servername = S("local")

dofile(b.path .. "/lib.lua")
dofile(b.path .. "/chatcommands.lua")

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
                        beamer.lib.show_formspec(puncher)

                    end
})

function b.lib.show_formspec(player)
        local playername = player:get_player_name()
        minetest.show_formspec(playername, "beamer:inputform",
                                "size[8.17,1.42]" ..
                                "field[0.16,0.48;2.36,0.87;servername;" .. S("Servername") .. ";" .. b.servername ..  "]" ..
                                "field[2.4,0.48;2.6,0.87;playername;" .. S("Playername") .. ";]" ..
                                "field[4.88,0.48;2.6,0.87;node;" .. S("Node") .. ";default:cobble]" ..
                                "field[7.36,0.48;1.24,0.87;amount;" .. S("Number") .. ";1]" ..
                                "image_button[-0.14,0.98;2.37,0.83;blank.png;button_send;" .. S("Send") .. "]" ..
                                "image_button_exit[5.7,0.98;2.61,0.83;blank.png;button_exit;" .. S("Exit") .. "]"
                            )
end

minetest.register_on_player_receive_fields(function(player, formname, fields)
    if formname == "beamer:inputform" and player then
        local username = player:get_player_name()
        local servername = fields.servername or ""
        local playername = fields.playername or ""
        local node = fields.node or ""
        local amount = fields.amount or 0

        if fields.button_send then

            b.to = {    user = username,
                        server = servername,
                        player = playername,
                        object = node,
                        value = amount,
                }

            b.lib.beam_local()

        end -- if fields.button_send


        if fields.button_exit then
            minetest.chat_send_player(username, b.green .. S("Beaming finished."))
            b.beam_far = false

        end -- if fields.button_exit

    end -- if formname

end)
