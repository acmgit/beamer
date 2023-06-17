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

b.version = "1.5"
b.modname = minetest.get_current_modname()
b.path = minetest.get_modpath(beamer.modname)
b.S = nil
b.ignore = {}
b.serverlist = {}
b.formspec_fields = {}
b.formspec_fields["itemname"] = "default:cobble"
b.formspec_fields["receiver"] = ""
b.formspec_fields["amount"] = 1

if(minetest.get_translator ~= nil) then
    b.S = minetest.get_translator(beamer.modname)

else
    b.S = function ( s ) return s end

end

local S = b.S

b.server_name = minetest.settings:get("beamer.servername") or "Local"
b.irc = minetest.settings:get_bool("beamer.irc") or false
b.serverlist[#b.serverlist + 1] = b.server_name

b.socket = {}
b.client = nil

b.error = {}

local nr = 1
b.error.player_unknown              = nr
nr = nr + 1
b.error.player_inventory_is_full    = nr
nr = nr + 1
b.error.locked_beam                 = nr
nr = nr + 1
b.error.unknown_item                = nr
nr = nr + 1
b.error.register_server             = nr
nr = nr + 1
b.error.unregister_server           = nr
nr = nr + 1
b.error.invalid_package             = nr

b.error.string = {
                    [b.error.player_unknown]                = b.red .. S("Player unkown or offline."),
                    [b.error.player_inventory_is_full]      = b.red .. S("Inventory is full."),
                    [b.error.locked_beam]                   = b.red .. S("Locked beaming."),
                    [b.error.unknown_item]                  = b.red .. S("Unknown Item."),
                    [b.error.register_server]               = b.green .. S(" has registered for beaming."),
                    [b.error.unregister_server]             = b.red .. S(" isn't available for beaming."),
                    [b.error.invalid_package]             = b.red .. S(" transporter malfunction."),
                }

if (b.irc) then
    local env, request_env = _G, minetest.request_insecure_environment
    env = request_env()

    if (not request_env) then
        minetest.log("action", "[MOD] " .. b.modname .. ": Init: Could not initalise insequre_environment.")
        b.irc_on = false

    end -- if(request_env

    if (not env) then
        minetest.log("action", "[MOD] " .. b.modname .. ": Init: Please add the mod to secure.trusted_mods to run.")
        b.irc = false

    else -- if (not env

        local old_require = require
        require = env.require
        b.socket = require("socket")
        require = old_require

        minetest.log("action", "[MOD] " .. b.modname .. " : Init: Socket-Library loaded.")
    end

end

-- ***************************************** Includes ************************************

dofile(b.path .. "/lib.lua")
dofile(b.path .. "/chatcommands.lua")
dofile(b.path .. "/irc.lua")
dofile(b.path .. "/crypt.lua")

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
                        b.lib.punch_beamer(pos, node, puncher)

                    end,
})

minetest.register_craft({
	output = "beamer:beamer",
	recipe = {	{"dye:blue", "default:obsidian_glass", "dye:red"},
				{"default:diamondblock", "default:mese", "default:diamondblock"},
                {"bucket:bucket_water", "default:furnace", "bucket:bucket_lava"}
			},
})

local servername

minetest.register_on_player_receive_fields(function(player, formname, fields)
    if not (player and player:is_player()) then
        return
    end

    if formname == "beamer:inputform" and player then
        local username = player:get_player_name()
        local playername = fields.receiver or ""
        local node = fields.itemstring or ""
        local amount = fields.amount or 0

        b.formspec_fields["itemname"] = node
        b.formspec_fields["amount"] = amount
        b.formspec_fields["receiver"] = playername

        local event = minetest.explode_textlist_event(fields.list)

        if (event.type == "CHG") and event.index then
		    servername = b.serverlist[event.index]

        end

        if (event.type == "DCL") and event.index then    -- DCL =doubleclick CHG = leftclick single
		   servername = b.serverlist[event.index]

		end -- if event.type

        if fields.btn_send then

            local pkg = {
                            ["error"] = nil,
                            ["server_from"] = b.server_name or b.server_name,
                            ["server_to"] = servername or b.server_name,
                            ["sender"] = username,
                            ["receiver"] = playername,
                            ["items"] = node .. " " .. amount,
                        }

            b.lib.send(pkg)

        end -- if fields.button_send


        if fields.btn_exit then
            minetest.chat_send_player(username, b.green .. S("Beaming finished."))
            b.formspec_fields["itemname"] = "default:cobble"
            b.formspec_fields["amount"] = 1
            b.formspec_fields["receiver"] = ""
            servername = ""
            return true

        end -- if fields.button_exit
        b.lib.show_formspec(player)

    end -- if formname

end)

minetest.log("action", b.modname .. " V " .. b.version .. " successfully loaded.")
