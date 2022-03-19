--Automatically restarts the server 15 minutes after the last player left, and once per hour when empty

local nextRestartTime = SysTime() + 3600
local lastRestart = SysTime()

hook.Add("PlayerDisconnected", "SmartRestart::PlayerDC", function()
    nextRestartTime = SysTime() + 900
end)

timer.Create("SmartRestart::Clock", 1, 0, function()
    if SysTime() > nextRestartTime and player.GetCount() == 0 then
        RunConsoleCommand("_restart")
    end

    if SysTime() > lastRestart + 86400 then
        BroadcastMsg(Color(255, 0, 0), "The server has been running for 24 hours. It will be restarted in 15 minutes.")
        RunConsoleCommand("hg restart 15m") --Custom mercury command, will be made standalone with this script in the future
        lastRestart = lastRestart + 1200 --Retry restart in 20 minutes if it gets cancelled
    end
end)