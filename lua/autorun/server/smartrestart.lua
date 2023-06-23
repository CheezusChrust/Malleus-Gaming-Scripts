--Automatically restarts the server 15 minutes after the last player left, and once per hour when empty

function formatTime(seconds)
    local units = {"second", "minute", "hour"}

    local cutoffs = {60, 60, 24}

    local unitIndex = 1

    while seconds >= cutoffs[unitIndex] and unitIndex < #cutoffs do
        seconds = seconds / cutoffs[unitIndex]
        unitIndex = unitIndex + 1
    end

    seconds = math.floor(seconds)

    return string.format("%d %s%s", seconds, units[unitIndex], seconds == 1 and "" or "s")
end

local nextRestartTime = SysTime() + 3600
local lastRestart = SysTime()
local restarting = false
local announceAt = {
    [600] = true,
    [300] = true,
    [120] = true,
    [60] = true,
    [30] = true,
    [15] = true
}

hook.Add("PlayerDisconnected", "SmartRestart::PlayerDC", function()
    nextRestartTime = SysTime() + 900
end)

hook.Add("PlayerConnect", "SmartRestart::PlayerConnect", function()
    nextRestartTime = SysTime() + 300
end)

timer.Create("SmartRestart::Clock", 1, 0, function()
    if SysTime() > nextRestartTime and player.GetCount() == 0 then
        RunConsoleCommand("_restart")
    end

    if not restarting and (SysTime() > lastRestart + 86400) then
        BroadcastMsg(Color(255, 0, 0), "The server has been running for 24 hours. It will be restarted in 15 minutes.")
        nextRestartTime = SysTime() + 900
        restarting = true
    end

    if restarting then
        local timeLeft = math.max(0, math.floor(nextRestartTime - SysTime()))

        if announceAt[timeLeft] or timeLeft <= 10 then
            BroadcastMsg(Color(255, 0, 0), "The server will restart in " .. formatTime(timeLeft) .. ".")
        end

        if timeLeft == 0 then
            RunConsoleCommand("_restart")
        end
    end
end)