local b = beamer
local S = b.S
b.lib = {}

function b.lib.beam_local()

    local username = b.to["user"]
    local user_object = b.lib.get_object(username)

    if (not user_object) then
        return

    end -- if(not user_object)



    if not b.lib.check_all(username) then return end

    local user_inventory = b.lib.get_object_inventory(b.to["user"])
    local player_inventory = b.lib.get_object_inventory(b.to["player"])
    local item_in_inventory = b.to["object"] .. " " .. b.to["value"]
    local playername = b.to["player"]

    minetest.sound_play("beamer_sound", { to_player = username, loop = false,})
    user_inventory:remove_item("main", item_in_inventory)
    player_inventory:add_item("main", item_in_inventory)
    minetest.chat_send_player(username,     b.green .. S("Beaming of") .. " " .. b.orange .. item_in_inventory ..
                                        b.green .. " " .. S("to") .. " " .. b.orange .. b.to["player"] .. " " ..
                                        b.green .. S("with success") .. "!")
    minetest.chat_send_player(playername,   b.green .. b.orange .. username .. " " ..
                                        b.green .. S("has beamed") .. " " .. b.orange .. item_in_inventory .. " " ..
                                        b.green .. S("in your Inventory") .. "!")

    b.to = nil

end -- beam_local

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

function b.lib.check_all(username)

    if (not b.lib.check_playername(username)) then return false end
    if (not b.lib.check_playername(username)) then return false end
    if (not b.lib.check_username_is_playername(username)) then return false end
    if (not b.lib.check_object_exist(username)) then return false end
    if (not b.lib.check_object_amount(username)) then return false end
    if (not b.lib.check_user_has_item(username)) then return false end
    if (not b.lib.check_player_is_online(username)) then return false end
    if (not b.lib.check_player_inventory_is_full(username)) then return false end
    if (not b.lib.check_player_ignores_beaming(username)) then return false end

    return true

end

function b.lib.check_playername(username)
    local playername = b.to["player"]

    if(playername == "") then
        minetest.chat_send_player(username, b.red .. S("You need a Playername to beam!"))
        return false

    end

    return true

end

function b.lib.check_username_is_playername(username)
    local playername = b.to["player"]

    if(username == playername) then
        minetest.chat_send_player(username, b.red .. S("You can not beam something to yourself!"))
        return false

    end

    return true

end

function b.lib.check_object_amount(username)
    local value = tonumber(b.to["value"])

    if(not value or value <= 0) then
        minetest.chat_send_player(username, b.red .. S("Illegal Number of objects!"))
        return false

    end

    return true

end

function b.lib.check_object_exist(username)
    local node = b.to["object"]
    print(node)
    if (not minetest.registered_items[node]) then
        minetest.chat_send_player(username, b.red .. S("Unknown Object") .. " " .. b.orange .. node .. b.red .. "!")
        return false

    end

    return true

end

function b.lib.check_user_has_item(username)
    local user_inventory = b.lib.get_object_inventory(username)
    local item_in_inventory = b.to["object"] .. " " .. b.to["value"]

    if(not user_inventory:contains_item("main", item_in_inventory)) then
        minetest.chat_send_player(username, b.red .. S("Not enough items in your Inventory!"))
        return false

    end

    return true

end

function b.lib.check_player_is_online(username)
    local player_object = b.lib.get_object(b.to["player"])

    if(not player_object) then
        minetest.chat_send_player(username, b.red .. S("Player") .. " " .. b.orange .. b.to["player"] .. b.red .. " " .. S("not found or not online."))
        return false

    end

    return true

end

function b.lib.check_player_inventory_is_full(username)
    local player_inventory = b.lib.get_object_inventory(b.to["player"])

    if(not player_inventory:room_for_item("main", item_in_inventory)) then
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
        minetest.chat_send_player(username, b.red .. S("Player") .. " " .. b.orange .. player .. b.red .. " " .. S("has turned beaming off."))
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
