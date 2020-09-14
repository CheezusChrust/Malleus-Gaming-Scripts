--Prop penetration checker to prevent massive lag due to props being unfrozen inside of eachother, helps a lot to stop generic spam
--Requires basicmessaging.lua

if SERVER then
    local allEnts = {}
    local plyMeta = FindMetaTable("Player")

    function plyMeta:FreezeProps()
        for _, ent in pairs(ents.GetAll()) do
            if ent:GetPhysicsObject():IsValid() and ent:CPPIGetOwner() and ent:CPPIGetOwner() == self then
                ent:GetPhysicsObject():EnableMotion(false)
            end
        end
    end

    --Maintain a table of existing entities, instead of repeatedly calling ent.GetAll() every tick which is horribly inefficient
    hook.Add("OnEntityCreated", "PenCheck::EntCreated", function(ent)
        timer.Simple(0, function()
            if not IsValid(ent:CPPIGetOwner()) then return end

            if ent:IsValid() and ent:GetPhysicsObject():IsValid() and ent:GetPhysicsObject() ~= game.GetWorld():GetPhysicsObject() and ent:CPPIGetOwner() ~= Entity(0) then
                allEnts[ent] = true
            end
        end)
    end)

    hook.Add("EntityRemoved", "PenCheck::EntRemoved", function(ent)
        if allEnts[ent] then
            allEnts[ent] = nil
        end
    end)

    hook.Add("Think", "PenCheck::Think", function()
        for ent, _ in pairs(allEnts) do
            --Get rid of NULL entities
            if not ent:IsValid() then
                allEnts[ent] = nil
                continue
            end

            if ent:GetParent():IsValid() or not ent:GetPhysicsObject():IsMoveable() then continue end

            --Check whether unfrozen entities are penetrating eachother, and if they are, maintain a table of them per-player
            if ent:CPPIGetOwner() and ent:GetPhysicsObject():IsValid() then
                if not ent:CPPIGetOwner().penetrating then
                    ent:CPPIGetOwner().penetrating = {}
                end

                ent:CPPIGetOwner().penetrating[ent] = ent:GetPhysicsObject():IsPenetrating() and true or nil
            end
        end

        --Check how many entities are penetrating eachother per-player, if this exceeds a set value, freeze the penetrating entities
        --freezeCount represents the number of times a player's props have been frozen due to penetration issues
        --If a player's props are frozen due to penetration issues 3 times in a short period, lock them out of everything for 60 seconds
        for _, ply in pairs(player.GetAll()) do
            if not ply.penetrating then continue end
            local count = table.Count(ply.penetrating)

            if ply.freezeLockout and count > 0 then
                ply:FreezeProps()
                continue
            end

            if count > 3 then
                if not ply.freezeCount then
                    ply.freezeCount = 0
                end

                ply.freezeCount = ply.freezeCount + 1
                ply:SendMsg(Color(255, 127, 0), "[AntiLag] ", Color(255, 0, 0), count .. " of your entities were frozen due to penetrating eachother")

                for ent, _ in pairs(ply.penetrating) do
                    if not ent:IsValid() then
                        ply.penetrating[ent] = nil
                        continue
                    end

                    ent:GetPhysicsObject():EnableMotion(false)

                    if ent:GetClass() == "prop_vehicle_jeep" or ent:GetClass() == "prop_vehicle_jalopy" then
                        ent:Remove()
                        ply:SendMsg(Color(255, 127, 0), "[AntiLag] ", Color(255, 0, 0), "Cannot freeze " .. ent:GetClass() .. ", removing")
                    end

                    ply.penetrating[ent] = nil
                end

                if ply.freezeCount > 2 then
                    ply:FreezeProps()
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
        end
    end)

    timer.Create("PenCheck::Cooldown", 30, 0, function()
        for _, ply in pairs(player.GetAll()) do
            if ply.freezeCount and ply.freezeCount > 0 then
                ply.freezeCount = ply.freezeCount - 1
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

    hook.Add("OnPhysgunReload", "PenCheck::Lockout", function(_, ply)
        if ply.freezeLockout then return false end
    end)
else
    hook.Add("CanTool", "PenCheck::Lockout", function(ply)
        if ply:GetNWBool("PCLockout") == true then return false end
    end)
end