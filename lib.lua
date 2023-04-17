local b = beamer
local S = b.S
b.lib = {}

function b.lib.beam_local()
    local user = b.to["user"]
    local player = b.to["player"]
    local user_object = minetest.get_player_by_name(user)
    local player_object = minetest.get_player_by_name(player)

    if (not user_object) then
        return

    end -- if(not user_object)

    if(not player_object) then
        minetest.chat_send_player(user:get_name(), b.red .. S("Player") .. " " .. b.orange .. b.to["player"] .. b.red .. " " .. S("not found or not online."))
        return

    end-- if(not player_object)

    local user_inventory = user_object:get_inventory()
    local player_inventory = player_object:get_inventory()
    local item_in_inventory = b.to["object"] .. " " .. b.to["value"]

    if(not user_inventory:contains_item("main", item_in_inventory)) then
        minetest.chat_send_player(user, b.red .. S("Not enough items in your Inventory!"))
        return

    end-- if(not user_inventory)

    if(not player_inventory:room_for_item("main", item_in_inventory)) then
        minetest.chat_send_player(user, b.red .. S("No room for so much items in") .. " " ..
                                        b.orange .. player .. " " ..
                                        b.red .. S("Inventory") .. "!")
        return

    end-- if(not player_inventory)

    if(b.ignore[player]) then
        minetest.chat_send_player(user, b.red .. S("Player") .. " " .. b.orange .. player .. b.red .. " " .. S("has turned beaming off."))
        return

    end --if(b.ignore)

    minetest.sound_play("beamer_sound", { to_player = username, loop = false,})
    user_inventory:remove_item("main", item_in_inventory)
    player_inventory:add_item("main", item_in_inventory)
    minetest.chat_send_player(user,     b.green .. S("Beaming of") .. " " .. b.orange .. item_in_inventory ..
                                        b.green .. " " .. S("to") .. " " .. b.orange .. player .. " " ..
                                        b.green .. S("with success") .. "!")
    minetest.chat_send_player(player,   b.green .. b.orange .. user .. " " ..
                                        b.green .. S("has beamed") .. " " .. b.orange .. item_in_inventory .. " " ..
                                        b.green .. S("in your Inventory") .. "!")

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
