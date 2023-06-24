if SERVER then
    local TargetColor = Color(88, 241, 96)
    local TextColor = Color(255, 255, 255)

    hook.Add("PlayerConnect", "JoinMsg::PlayerConnect", function(name, ip)
        ip = table.concat(string.Explode(".", string.Explode(":", ip)[1]), "%2E")

        local url = "http://ip-api.com/json/" .. ip

        http.Fetch(url, function(body)
            local tbl = util.JSONToTable(body)

            if tbl.status == "success" then
                BroadcastMsg(TargetColor, name, TextColor, " has connected from ", TargetColor, tbl.regionName .. ", " .. tbl.country)
            else
                BroadcastMsg(TargetColor, name, TextColor, " has connected from ", TargetColor, "parts unknown")
            end
        end, function(err)
            BroadcastMsg(TargetColor, name, TextColor, " has connected from ", TargetColor, "parts unknown")
            MsgC(Color(255, 0, 0), "[JoinMsg] Failed to connect to ip-api.com: ", err, "\n")
            MsgC(Color(255, 0, 0), "[JoinMsg] URL: ", url, "\n")
        end)
    end)

    hook.Add("PlayerInitialSpawn", "JoinMsg::PlayerInitialSpawn", function(ply)
        timer.Simple(0, function()
            BroadcastMsg(team.GetColor(ply:Team()), ply:Nick(), TextColor, " has spawned")
        end)
    end)

    local function playerByName(name)
        for _, ply in ipairs(player.GetAll()) do
            if ply:Nick() == name then
                return ply
            end
        end
    end

    gameevent.Listen("player_disconnect")
    hook.Add("player_disconnect", "JoinMsg::PlayerDisconnect", function(data)
        local name = data.name
        local reason = data.reason
        local ply = playerByName(name)

        reason = reason:TrimRight("\n")

        if reason == "Disconnect by user." then
            reason = ""
        elseif reason:find("-------===== [ BANNED ] =====-------") then
            reason = ""
        else
            reason = " (" .. reason:Replace(name .. " ", "") .. ")"
        end

        local teamColor = IsValid(ply) and team.GetColor(ply:Team()) or TargetColor

        BroadcastMsg(teamColor, name, TextColor, " has disconnected", TargetColor, reason)
    end )
else
    hook.Add("ChatText", "JoinMsg::Suppress", function(_, _, _, type)
        if type == "joinleave" then
            return true
        end
    end)
end