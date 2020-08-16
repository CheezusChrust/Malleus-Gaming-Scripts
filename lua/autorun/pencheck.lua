--Prop penetration checker to prevent massive lag due to props being unfrozen inside of eachother, helps a lot to stop generic spam
--Requires basicmessaging.lua

if SERVER then
    local plyMeta = FindMetaTable("Player")

    function plyMeta:FreezeAll()
        for _, ent in pairs(ents.GetAll()) do
            if ent:GetPhysicsObject():IsValid() and ent:CPPIGetOwner() and ent:CPPIGetOwner() == self then
                ent:GetPhysicsObject():EnableMotion(false)
            end
        end
    end

    hook.Add("Think", "PenCheck::Think", function()
        for _, ent in pairs(ents.GetAll()) do
            if IsValid(ent) and ent:IsValid() and ent:CPPIGetOwner() and ent:CPPIGetOwner():IsValid() and ent:GetPhysicsObject():IsValid() and ent:GetPhysicsObject():IsMoveable() and not ent:IsPlayerHolding() then
                if not ent:CPPIGetOwner().penetrating then
                    ent:CPPIGetOwner().penetrating = {}
                end

                ent:CPPIGetOwner().penetrating[ent] = ent:GetPhysicsObject():IsPenetrating() and true or nil
            end
        end

        for _, ply in pairs(player.GetAll()) do
            if ply.penetrating then
                for ent, _ in pairs(ply.penetrating) do
                    if not ent:IsValid() then
                        ply.penetrating[ent] = nil
                    end
                end

                local count = table.Count(ply.penetrating)

                if ply.freezeLockout and count > 0 then
                    ply:FreezeAll()
                    goto cont
                end

                if count > 3 then
                    if not ply.freezeCount then
                        ply.freezeCount = 0
                    end

                    ply.freezeCount = ply.freezeCount + 1
                    ply:SendMsg(Color(255, 127, 0), "[AntiLag] ", Color(255, 0, 0), count .. " of your entities were frozen due to penetrating eachother")

                    for ent, _ in pairs(ply.penetrating) do
                        ent:GetPhysicsObject():EnableMotion(false)
                        ply.penetrating[ent] = nil
                    end

                    if ply.freezeCount > 2 then
                        ply:FreezeAll()
                        ply.freezeLockout = true
                        ply:SetNWBool("PCLockout", true)
                        ply:SendMsg(Color(255, 127, 0), "[AntiLag] ", Color(255, 0, 0), "Stop doing that - all of your entities have been frozen and you have been temporarily restricted from further spawning...")
                        BroadcastMsg(Color(255, 0, 255), "[Server] ", Color(255, 0, 0), ply:Nick() .. " has been temporarily restricted due to repeatedly creating penetrating physics objects")

                        timer.Simple(60, function()
                            ply.freezeLockout = false
                            ply:SetNWBool("PCLockout", false)
                            ply.freezeCount = 0
                        end)
                    end
                end

                ::cont::
            end
        end
    end)

    hook.Add("CanTool", "PenCheck::Lockout", function(ply)
        if ply.freezeLockout then return false end
    end)

    hook.Add("PlayerSpawnProp", "PenCheck::Lockout", function(ply)
        if ply.freezeLockout then return false end
    end)

    hook.Add("PlayerSpawnSENT", "PenCheck::Lockout", function(ply)
        if ply.freezeLockout then return false end
    end)

    hook.Add("PlayerSpawnVehicle", "PenCheck::Lockout", function(ply)
        if ply.freezeLockout then return false end
    end)

    hook.Add("PhysgunPickup", "PenCheck::Lockout", function(ply)
        if ply.freezeLockout then return false end
    end)

    hook.Add("OnPhysgunReload", "PenCheck::Lockout", function(ply)
        if ply.freezeLockout then return false end
    end)
else
    hook.Add("CanTool", "PenCheck::Lockout", function(ply)
        if ply:GetNWBool("PCLockout") == true then return false end
    end)
end

print("PenCheck Loaded")