--Loader for files shared between multiple servers
--To use:
--  Place this script in each server's autorun folder
--  Create a directory with the same structure as the autorun folder anywhere on your system
--  Place any scripts you want running on both servers in the folder created above
--  Run the following command from a command prompt opened from within each server's lua folder:
--  mkdir /J autorunshared "C:/YOUR/SHARED/FILES/DIRECTORY/"

if SERVER then
    MsgN("==========[ Loading files shared between servers ]=========\n|")
    local files, _ = file.Find("autorunshared/server/*", "LUA")

    for _, f in ipairs(files) do
        MsgN("| autorunshared/server/" .. f)
        include("autorunshared/server/" .. f)
    end

    files, _ = file.Find("autorunshared/client/*", "LUA")

    for _, f in ipairs(files) do
        MsgN("| autorunshared/client/" .. f)
        AddCSLuaFile("autorunshared/client/" .. f)
    end

    files, _ = file.Find("autorunshared/*", "LUA")

    for _, f in ipairs(files) do
        MsgN("| autorunshared/" .. f)
        include("autorunshared/" .. f)
        AddCSLuaFile("autorunshared/" .. f)
    end

    MsgN("|\n=============[ Finished loading shared files ]=============")
elseif CLIENT then
    MsgN("==========[ Loading files shared between servers ]=========\n|")
    local files, _ = file.Find("autorunshared/*", "LUA")

    for _, f in ipairs(files) do
        MsgN("| autorunshared/" .. f)
        include("autorunshared/" .. f)
    end

    files, _ = file.Find("autorunshared/client/*", "LUA")

    for _, f in ipairs(files) do
        MsgN("| autorunshared/client/" .. f)
        include("autorunshared/client/" .. f)
    end

    MsgN("|\n=============[ Finished loading shared files ]=============")
end