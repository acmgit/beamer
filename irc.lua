local b = beamer
local socket = b.socket
b.socket = nil

b.irc_running = false
b.crlf = "\r\n"
local irc_on
if(b.irc_on) then
    irc_on = "on"
else
    irc_on = "off"
end

minetest.log("action","[MOD] " .. b.modname .. ": Modul IRC : " .. irc_on)

b.irc_server_name = minetest.settings:get("beamer.irc_server_name") or "libera.chat"
b.irc_server_port = tonumber(minetest.settings:get("beamer.irc_server_port")) or 6667
b.irc_channel_name = minetest.settings:get("beamer.irc_channel_name") or "##MT_Serverdata"
b.irc_channel_topic = minetest.settings:get("beamer.irc_channel_topic") or "MT_Server_Datachannel"
b.irc_channel_password = minetest.settings:get("beamer.irc_channel_password") or ""
b.irc_client_timeout = tonumber(minetest.settings:get("beamer.irc_client_timeout")) or 0.03
b.irc_automatic_reconnect = minetest.settings:get_bool("beamer.irc_automatic_reconnect") or false
b.irc_automatic_reconnect_max = tonumber(minetest.settings:get("beamer.irc_automatic_reconnect_max")) or 5
b.irc_user_password = minetest.settings:get("beamer.irc_user_password") or ""
b.irc_server_step = tonumber(minetest.settings:get("beamer.irc_server_step")) or 2
b.irc_automatic_reconnect_number = 0

if(b.irc) then

   function b.lib.irc_connect()
        if not b.irc_running then
            b.irc_running = true

        end

        minetest.log("action", "[MOD] " .. b.modname .. " : Module Irc: Try to connect to: "
                                            .. b.irc_server_name .. ":" .. b.irc_server_port)
        local cl, err = assert(socket.connect(b.irc_server_name, b.irc_server_port))  -- connect to irc
        minetest.log("action", "[MOD] " .. b.modname .. " : Module Irc: Start connection: " .. (err or "ok"))
        b.client = cl

        minetest.log("action", "[MOD] " .. b.modname .. " : Module Irc: Set client_timeout to: "
                                        .. b.irc_client_timeout)
        err = b.client:settimeout(b.irc_client_timeout)                                           -- and set timeout
        minetest.log("action", "[MOD] " .. b.modname .. " : Module Irc: Settimeout: " ..  (err or "ok"))

        minetest.log("action", "[MOD] " .. b.modname .. " : Module Irc: Set Nick: " .. b.server_name)
        local line = "NICK " .. b.server_name .. " " .. b.crlf
        err = b.client:send(line)
        minetest.log("action", "[MOD] " .. b.modname .. " : Module Irc: " .. line .. " Error: " .. (err or "ok"))

        minetest.log("action", "Set User: " .. b.server_name .. " 0 0 " .. b.server_name)
        line = "USER " .. b.server_name .. " 0 0 " .. b.server_name .. b.crlf
        err = b.client:send(line)
        minetest.log("action","[MOD] " .. b.modname .. " : Module Irc: " .. line .. " Error: " .. (err or "ok"))

        if(b.irc_user_password ~= "") then
            line = "PASS " .. b.irc_user_password .. b.crlf
            minetest.log("action","[MOD] " .. b.modname .. " : Module Irc: " ..  line
                                           .. "Error: " .. (err or "ok"))
            err = b.client:send(line)
            minetest.log("action","[MOD] " .. b.modname .. " : Module Irc: " .. line .. " Error: " .. (err or "ok"))

        end -- if(b.irc_user_password =~ ""

        if(b.irc_channel_password ~= "") then
                line = "JOIN " .. b.irc_channel_name .. " " .. b.irc_channel_password .. b.crlf

        else
                line = "JOIN " .. b.irc_channel_name .. b.crlf

        end -- if(not b.irc_password
        err = b.client:send(line)
        minetest.log("action","[MOD] " .. b.modname .. " : Module Irc: " .. line .. " Error: " .. (err or "ok"))

        line = "TOPIC " .. b.irc_channel_name .. " :" .. b.irc_channel_topic .. b.crlf
        err = b.client:send(line)
        minetest.log("action", "[MOD] " .. b.modname .. " : Module Irc: " .. line .. "Error:" .. (err or "ok"))

    end -- function b.lib.irc_connect

    function b.lib.receive_from_irc(line)
        if(not b.irc_running) then return end
        local e
        _, e = string.find(line, "PRIVMSG " .. b.irc_channel_name .. " :")
        e = e or 0
        local pkg = string.sub(line, e + 1, string.len(line))
        local package = minetest.deserialize(pkg)
        if(package) then
            b.lib.receive(package)
        end

    end -- function lib.receive()

end


if (b.irc) then

    b.lib.irc_connect()

    minetest.register_on_shutdown(function()
        -- Close the Connection to IRC-Server and close the network
        if (b.client) then
            local package = {}
            package["error"] = b.error.unregister_server
            package["server_from"] = b.server_name
            b.lib.send_irc(package)

            minetest.log("action", "Shutdown IRC.")
            b.client:send("QUIT" .. b.crlf)
            b.client:close()
            b.client = nil
            b.irc_running = false

        end -- if(b.client

    end) -- register_on_shutdown

    local timer = 0
    local line, err
    minetest.register_globalstep(function(dtime)
        timer = timer + dtime;
        if (timer >= 2) then
            line, err = b.client:receive("*l","++")                                 -- get line from the IRC
            if (line ~= nil) then
                local a,e = string.find(line,"PING")
                if( (a) and (e) )then                                                        -- Line was a Ping
                    local ping = string.sub(line,e+1)
                    b.client:send("PONG" .. ping .. b.crlf)                                 -- Answer with Pong
                else
                    b.lib.receive_from_irc(line)
                    minetest.log("action", "[MOD] " .. b.modname .. "Receive_IRC : " .. line)

                end -- if( (a) and (e)

            end -- if(line
            timer = 0
        elseif ((err ~= nil) and (err ~= "timeout")) then
            if(err == "closed") then                                                   -- Connection closed?
                b.client:close()                                                      -- Close the Connection
                b.irc_running = false

                if ((b.irc_automatic_reconnect) and (b.irc_automatic_reconnect_number < b.irc_automatic_reconnect_max)) then
                    b.lib.irc_connect()
                    b.irc_automatic_reconnect_number = b.irc_automatic_reconnect_number + 1

                end -- if(b.automatic_reconnect

            end -- if(err == "closed"

        end -- if(err ~= nil


    end) -- function()

    local package = {}
    package["error"] = b.error.register_server
    package["server_from"] = b.server_name
    b.lib.send_irc(package)

end --if (b.irc)
