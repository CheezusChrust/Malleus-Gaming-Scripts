--Super simple serverside functions to add chat.AddText-like functionality

if SERVER then
    util.AddNetworkString("BasicMessaging::SendMsg")
    local plyMeta = FindMetaTable("Player")

    function plyMeta:SendMsg(...)
        net.Start("BasicMessaging::SendMsg")
        net.WriteTable({...})
        net.Send(self)
    end

    function BroadcastMsg(...)
        net.Start("BasicMessaging::SendMsg")
        net.WriteTable({...})
        net.Broadcast()
    end
else
    net.Receive("BasicMessaging::SendMsg", function()
        chat.AddText(unpack(net.ReadTable()))
    end)
end