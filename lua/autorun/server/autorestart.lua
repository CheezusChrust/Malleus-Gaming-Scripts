--Auto restart the server at 4:00AM every day
--Requires basicmessaging.lua

timer.Create("autorestart", 60, 0, function()
    local time = os.date("%H-%M")

    if time == "03-00" then
        BroadcastMsg(Color(255, 0, 255), "[Server] ", Color(255, 255, 255), "Warning! For performance reasons the server will restart one hour from now.")
    end

    if time == "03-30" then
        BroadcastMsg(Color(255, 0, 255), "[Server] ", Color(255, 255, 255), "Warning! For performance reasons the server will restart 30 minutes from now.")
    end

    if time == "03-45" then
        BroadcastMsg(Color(255, 0, 255), "[Server] ", Color(255, 255, 255), "Warning! For performance reasons the server will restart 15 minutes from now.")
    end

    if time == "03-50" then
        BroadcastMsg(Color(255, 0, 255), "[Server] ", Color(255, 255, 255), "Warning! For performance reasons the server will restart 10 minutes from now.")
    end

    if time == "03-55" then
        BroadcastMsg(Color(255, 0, 255), "[Server] ", Color(255, 255, 255), "Warning! For performance reasons the server will restart in FIVE MINUTES. Save your stuff!")
    end

    if time == "03-59" then
        BroadcastMsg(Color(255, 0, 255), "[Server] ", Color(255, 255, 255), "Warning! Restarting in one minute!")
    end

    if time == "04-00" then
        BroadcastMsg(Color(255, 0, 255), "[Server] ", Color(255, 255, 255), "Restarting")
        print("Server restart triggered.")
        RunConsoleCommand("_restart")
    end
end)

print("AutoRestart Loaded")