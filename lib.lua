local b = beamer
local S = b.S
b.lib = {}

function b.lib.send(package)
    local server_from = package["server_from"]
    local server_to = package["server_to"]
    local sender = package["sender"]
    local receiver = package["receiver"]
    local item = string.match(package["items"], "[%a%p]+")
    local amount = tonumber(string.match(package["items"], "[%d]+"))
    local players = minetest.get_connected_players()

    if(not players[sender]) then return end

    if (not b.lib.check_item_exist(item)) then
        minetest.chat_send_player(sender, b.red .. S("Unknown Object") .. " " ..
                                            b.orange .. item ..
                                            b.red .. "!")
        return

    end

    if (string.match(server_from .. "@" .. sender, server_to .. "@" .. receiver)) then
        minetest.chat_send_player(sender, b.red .. S("You can not beam something to yourself!"))
        return

    end

    if(not b.lib.check_amount(amount)) then
        minetest.chat_send_player(sender, b.red .. S("Illegal Number of objects!"))
        return

    end

    if(not b.lib.check_user_has_item(sender, package["items"])) then
        minetest.chat_send_player(sender, b.red .. S("Not enough items in your Inventory!"))
        return

    end

    if(not string.match(server_from, server_to)) then
        -- send global
        b.lib.send_irc(package)
        b.lib.write_send(sender)

    else
        -- send local
        b.lib.write_send(sender)
        b.lib.receive(package)

    end

end -- send(package)

function b.lib.send_irc(package)

end

function b.lib.handle_error(package)
    local server_from = package["server_from"]
    local server_to = package["server_to"]

    if(not string.match(server_from, server_to)) then
        local server = package["server_from"]
        package["server_from"] = package["server_to"]
        package["server_to"] = server

        b.lib.send_irc(package)
    else
        minetest.chat_send_player(package["sender"], b.error.string[package["error"]])

    end

end -- b.lib.handle_error

function b.lib.receive(package)
    if (not string.match(package["server_to"],b.servername)) then return end       -- it's not our server, ignore it
    if (package["error"]) then                                                     -- has an error, errorhandling
        b.lib.handle_error(package)
        return

    end


    local server_from = package["server_from"]
    local sender = package["sender"]
    local receiver = package["receiver"]
    local item = string.match(package["items"], "[%a%p]+")
    local amount = tonumber(string.match(package["items"], "[%d]+"))

    local players = minetest.get_connected_players()

    -- Player is not online
    if(not players[receiver]) then
        package["error"] = b.error.player_unknown
        b.send_error(package)
        return

    end

    -- Player ignores beaming
    if(b.ignore[receiver]) then
        package["error"] = b.error.locked_beam
        b.send_error(package)
        return

    end

    -- Unkown Object
    if(not b.check_item_exist(item)) then
        package["error"] = b.error.unkown_object
        b.send_error(package)
        return

    end

    -- Playerinventory is full
    if(not b.check_player_inventory_is_full(receiver)) then
        package["error"] = b.error.player_inventory_is_full
        b.send_error(package)
        return

    end

    local receiver_inventory = minetest.get_object_inventory(receiver)
    receiver_inventory:add_item("main", package["items"])

    minetest.chat_send_player(receiver, b.orange .. server_from ..
                                        b.green .. "@" ..
                                        b.orange .. sender ..
                                        b.green .. S("has beamed") ..
                                        b.orange .. amount .. " " .. item ..
                                        b.green .. S("in your Inventory") .. "!")

end -- receive(package)


function b.lib.write_send(username, items, receiver)
    minetest.sound_play("beamer_sound", { to_player = username, loop = false,})
    minetest.chat_send_player(username,     b.green .. S("Beaming of") .. " " .. b.orange .. items ..
                                        b.green .. " " .. S("to") .. " " .. b.orange .. receiver .. " " ..
                                        b.green .. "!")
end -- write_send

function b.lib.send_error(package)
        package["server_to"] = package["server_from"]
        package["server_from"] = b.servername
        b.send(package)

end

function b.lib.get_servername(player)

        if (beamer.servername ~= "") then
            minetest.chat_send_player(player, b.green .. S("The Servername is: ") ..
                                              b.orange .. beamer.servername .. "!")

        else
            minetest.chat_send_player(player, b.red .. S("There is no servername set.") .. "\n" ..
                                              b.orange .. S("Only local beam possible."))

        end

end -- get_servername()

function b.lib.toggle_beam(player)
    if(b.ignore[player]) then
        b.ignore[player] = nil
        minetest.chat_send_player(player, b.green .. S("Beamen is possible again."))
    else
        b.ignore[player] = true
        minetest.chat_send_player(player, b.green .. S("Beamen is locked."))

    end -- if(b.ignore)

end -- toggle_beam

function b.lib.check_playername(username)

    if(username == "") then
        minetest.chat_send_player(username, b.red .. S("You need a Playername to beam!"))
        return false

    end

    return true

end

function b.lib.check_amount(amount)
    local value = tonumber(amount)

    if(not value or value <= 0) then
        return false

    end

    return true

end

function b.lib.check_item_exist(item)
    if (not minetest.registered_items[item]) then
        return false

    end
    return true

end

function b.lib.check_user_has_item(username, items)
    local user_inventory = b.lib.get_object_inventory(username)

    if(not user_inventory:contains_item("main", items)) then
        return false

    end

    return true

end

function b.lib.check_player_is_online(username)
    local player_object = b.lib.get_object(b.to["player"])

    if(not player_object) then
        minetest.chat_send_player(username, b.red .. S("Player") .. " " ..
                                            b.orange .. b.to["player"] ..
                                            b.red .. " " .. S("not found or not online."))
        return false

    end

    return true

end

function b.lib.check_player_inventory_is_full(username, items)
    local player_inventory = b.lib.get_object_inventory(b.to["player"])

    if(not player_inventory:room_for_item("main", items)) then
        minetest.chat_send_player(username, b.red .. S("No room for so much items in") .. " " ..
                                        b.orange .. b.to["player"] .. " " ..
                                        b.red .. S("Inventory") .. "!")
        return false

    end

    return true

end

function b.lib.check_player_ignores_beaming(username)
    local player = b.to["player"]

    if(b.ignore[player]) then
        minetest.chat_send_player(username, b.red .. S("Player") .. " " ..
                                            b.orange .. player ..
                                            b.red .. " " .. S("has turned beaming off."))
        return false

    end

    return true

end

function b.lib.get_object(name)
    return minetest.get_player_by_name(name)

end

function b.lib.get_object_inventory(name)
    local object = b.lib.get_object(name)
    return object:get_inventory()

end

function b.lib.punch_beamer(pos, node, puncher, pointed_thing)
    if (not puncher) then return end

    local player_name = puncher:get_player_name()
    local item_stack = puncher:get_wielded_item()
    local item_name = item_stack:get_name()

    if(not item_name) then
        beamer.lib.show_formspec(puncher)
        return

    else -- if(not item)

        if (string.match(item_name, "pick") or (string.match(item_name, "axe"))) then
            minetest.node_dig(pos, node, puncher)

        else
            beamer.lib.show_formspec(puncher)

        end

    end -- if( not item)

end -- function punch_beamer


-- Shows Information about an Item you held in the Hand
function b.lib.show_item(name)

	local player = minetest.get_player_by_name(name) -- Get the Playerobject

	if( (player ~= nil) ) then

		local item = player:get_wielded_item() -- Get the current used Item

		if( (item ~= nil) )then
			if(item:get_name() ~= "") then
                minetest.chat_send_player(name, b.green .. S("Itemname:") .. " " .. b.orange .. item:get_name() ..
                                                  b.green .. " - " .. b.orange .. item:get_count() ..
                                                  b.green .. " / " .. b.orange .. item:get_stack_max()
                                          )

			else
				minetest.chat_send_player(name, b.red .. S("You have no Item in your Hand."))

			end -- if( item:get_name

		else
			minetest.chat_send_player(name, b.red .. S("You have no Item in your Hand."))

		end --- if( item

	end -- if( player

end -- chathelp.show_item()-- Shows Information about an Item you held in the Hand

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
