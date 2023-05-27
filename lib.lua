local b = beamer
local S = b.S
b.lib = {}

function b.lib.send(package)
    if(package["server_to"] == "") then package["server_to"] = b.server_name end

    local server_from = package["server_from"]
    local server_to = package["server_to"] or b.server_name
    local sender = package["sender"]
    local receiver = package["receiver"]
    local item = string.match(package["items"], "[%a%p]+")
    local amount = tonumber(string.match(package["items"], "[%d]+"))

    if (not minetest.registered_items[item]) then
        minetest.chat_send_player(sender, b.red .. S("Unknown Item") .. " " ..
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
        if(not b.irc) then
            minetest.chat_send_player(package["sender"], b.red .. S("Far serverbeaming is offline."))
            return

        end

        b.lib.write_send(package)
        b.lib.send_item(package["sender"], package["items"])                -- removes the items from the inventory
        b.lib.send_irc(package)

    else
        -- send local
        b.lib.send_item(package["sender"], package["items"])                -- removes the items from the inventory
        b.lib.write_send(package)
        b.lib.receive(package)

    end


end -- send(package)

function b.lib.send_irc(package)
    local message = minetest.serialize(package)
    message = "PRIVMSG "   .. b.irc_channel_name .. " :" .. message .. b.crlf
    b.client:send(message)

end

function b.lib.handle_error(package)
    local dummy

    dummy = package["server_from"]
    package["server_from"] = package["server_to"]
    package["server_to"] = dummy

    dummy = package["sender"]
    package["sender"] = package["receiver"]
    package["receiver"] = dummy

    local server_to = package["server_to"]
    local receiver = package["receiver"]

    if (string.match(server_to, b.server_name)) then                                          -- sending local
        if(minetest.get_player_by_name(receiver)) then                                       -- receiver is online?
            minetest.chat_send_player(receiver, b.error.string[package["error"]])
            b.lib.write_receive(package)
            b.lib.receive_item(receiver, package["items"])

        end                                                                                 -- unlucky one,
                                                                                            -- sender is offline

    else                                                                                    -- sending global
        b.lib.send_irc(package)

    end

end -- b.lib.handle_error

function b.lib.receive(package)
    if (package["error"] == b.error.register_server) then
            b.serverlist[#b.serverlist + 1] = package["server_from"]
            minetest.chat_send_all(b.orange .. package["server_from"] .. " " .. b.error.string[package["error"]])

            if (not package["server_to"]) then
                package["server_to"] = package["server_from"]
                package["server_from"] = b.server_name
                b.lib.send_irc(package)
            end

            return
    end

    if (package["error"] == b.error.unregister_server) then
        local servername = package["server_from"]
        for k,v in pairs(b.serverlist) do
            if(string.match(v, servername)) then
                b.serverlist[k] = nil
            end

        end
        minetest.chat_send_all(b.orange .. package["server_from"] .. " " .. b.error.string[package["error"]])
        return

    end

    if (not string.match(package["server_to"],b.server_name)) then return end       -- it's not our server, ignore it

    if (package["error"]) then  -- has an error, errormessage and package back
        minetest.chat_send_player(package["receiver"], b.error.string[package["error"]])
        b.lib.write_receive(package)
        b.lib.receive_item(package["receiver"], package["items"])
        return

    end

    local receiver = package["receiver"]
    local item = string.match(package["items"], "[%a%p]+")
    local receiver_object = minetest.get_player_by_name(receiver)

    -- Player is not online
    if(not receiver_object) then
        package["error"] = b.error.player_unknown
        b.lib.handle_error(package)
        return

    end

    -- Player ignores beaming
    if(b.ignore[receiver]) then
        package["error"] = b.error.locked_beam
        b.lib.handle_error(package)
        return

    end

    -- Unkown Object
    if(not b.lib.check_item_exist(item)) then
        package["error"] = b.error.unknown_item
        b.lib.handle_error(package)
        return

    end

    -- Playerinventory is full
    if(not b.lib.check_player_inventory_is_full(receiver, package["items"])) then
        package["error"] = b.error.player_inventory_is_full
        b.lib.handle_error(package)
        return

    end

    b.lib.write_receive(package)
    b.lib.receive_item(package["receiver"], package["items"])

end -- receive(package)

function b.lib.receive_item(receiver, items)
    local receiver_inventory = b.lib.get_inventory(receiver)
    if(receiver_inventory) then
        receiver_inventory:add_item("main", items)

    end

end

function b.lib.send_item(sender, items)
    local sender_inventory = b.lib.get_inventory(sender)
    if(sender_inventory) then
        sender_inventory:remove_item("main", items)

    end

end

function b.lib.write_receive(package)
    local receiver = package["receiver"]
    local items = package["items"]
    minetest.chat_send_player(receiver, b.orange .. package["sender"] ..
                                        b.green .. "@" ..
                                        b.orange .. package["server_from"] .. " " ..
                                        b.green .. S("has beamed") .. " " ..
                                        b.orange .. items .. " " ..
                                        b.green .. S("in your Inventory") .. "!")

end

function b.lib.write_send(package)
    minetest.sound_play("beamer_sound", { to_player = package["sender"], loop = false,})
    minetest.chat_send_player(package["sender"],    b.green .. S("Beaming of") .. " " ..
                                                    b.orange .. package["items"] ..
                                                    b.green .. " " .. S("to") .. " " ..
                                                    b.orange .. package["receiver"] ..
                                                    b.green .. "@" ..
                                                    b.orange .. package["server_to"] ..
                                                    b.green .. "!")

end -- write_send

function b.lib.get_servername(player)

        if (beamer.servername ~= "") then
            minetest.chat_send_player(player, b.green .. S("The Servername is: ") ..
                                              b.orange .. b.server_name .. b.green .. "!")

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
    local player_object = minetest.get_player_by_name(username)
    if(not player_object) then return false end

    local player_inventory = player_object:get_inventory()
    if(not player_inventory) then return false end

    if(not player_inventory:contains_item("main", items)) then
        return false

    end

    return true

end

function b.lib.check_player_is_online(username, receiver)
    local player_object = minetest.get_player_by_name(receiver)

    if(not player_object) then
        minetest.chat_send_player(username, b.red .. S("Player") .. " " ..
                                            b.orange .. receiver ..
                                            b.red .. " " .. S("not found or not online."))
        return false

    end

    return true

end

function b.lib.check_player_inventory_is_full(receiver, items)
    local player_object = minetest.get_player_by_name(receiver)
    if (not player_object) then return false end

    local player_inventory = player_object:get_inventory()
    if(not player_inventory) then return false end

    if(not player_inventory:room_for_item("main", items)) then
        return false

    end

    return true

end

function b.lib.get_inventory(username)
    local player_object = minetest.get_player_by_name(username)

    if not(player_object) then return false end
    return player_object:get_inventory()

end

function b.lib.punch_beamer(pos, node, puncher, pointed_thing)
    if (not puncher) then return end

    local player_name = puncher:get_player_name()
    local item_stack = puncher:get_wielded_item()
    local item_name = item_stack:get_name()

    if(not item_name) then
        b.lib.show_formspec(puncher)
        return

    else -- if(not item)

        if (string.match(item_name, "pick") or (string.match(item_name, "axe"))) then
            minetest.node_dig(pos, node, puncher)

        else
            b.lib.show_formspec(puncher)

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
        local serverlist = ""
        for key,value in pairs(b.serverlist) do
            serverlist = serverlist .. value .. ","

        end

        minetest.show_formspec(playername, "beamer:inputform",
                    "formspec_version[6]" ..
                    "size[13,5]" ..
                    "label[0.2,0.3;" .. S("Server") .. "]" ..
                    "textlist[0.2,0.6;4.8,2.8;list;" .. serverlist .. ";;false]" ..
                    "field[5.1,1.9;7.4,0.8;itemstring;" .. S("Item") .. ";" .. b.formspec_fields["itemname"] .. "]" ..
                    --"field_close_on_enter[itemstring;false]" ..
                    "field[5.1,3.2;3,0.8;amount;" .. S("Amount") .. ";" .. b.formspec_fields["amount"] .. "]" ..
                    --"field_close_on_enter[amount;false]" ..
                    "field[5.1,0.6;7.3,0.8;receiver;" .. S("Receiver") .. ";" .. b.formspec_fields["receiver"] .. "]" ..
                    --"field_close_on_enter[receiver;false]" ..
                    "item_image[8.4,3;1,1;" .. b.formspec_fields["itemname"] .. "]" ..
                    "button_exit[9.7,4;3,0.8;btn_exit;" .. S("Exit") .. "]" ..
                    "button[0.2,4;3,0.8;btn_send;" .. S("Send") .. "]"
                    )
end

function b.lib.get_formspec_index(fields)



end
