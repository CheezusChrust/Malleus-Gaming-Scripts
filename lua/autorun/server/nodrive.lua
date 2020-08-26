--Because driving props is the worst feature

hook.Add("CanProperty", "block_drive", function(ply, property, ent)
    if not ply:IsAdmin() and property == "drive" then return false end
end)

print("AntiDrive Loaded")