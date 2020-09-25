if SERVER then
    local preC = Color(100, 255, 100)
    local pre = "[AntiLag] "

    --Block people from using annoying/crashy models
    do
        local models = {
            --"models/props_c17/oildrum001_explosive.mdl",
            --"models/props_junk/gascan001a.mdl",
            --"models/props_junk/propane_tank001a.mdl",
            "models/props_phx/ww2bomb.mdl",
            "models/props_phx/oildrum001_explosive.mdl",
            "models/props_phx/misc/potato_launcher_explosive.mdl",
            "models/props_explosive/explosive_butane_can.mdl",
            "models/props_explosive/explosive_butane_can02.mdl",
            "models/props_phx/misc/flakshell_big.mdl",
            "models/misc/500lb_shell.mdl",
            "models/props_phx/mk-82.mdl",
            "models/props_phx/oildrum001.mdl",
            "models/props_phx/torpedo.mdl",
            "models/props_phx/amraam.mdl",
            "models/props_phx/facepunch_barrel.mdl",
            "models/props_phx/cannonball_solid.mdl",
            "models/props_phx/ball.mdl",
            "models/props_phx/huge/",
            "models/props_combine/combine_citadel001.mdl",
            "models/Cranes/crane_frame.mdl",
            --"models/props_wasteland/medbridge_base01.mdl",
            --"models/props_canal/canal_bridge03b.mdl",
            --"models/props_canal/canal_bridge03a.mdl",
            --"models/props_canal/canal_bridge02.mdl",
            --"models/props_canal/canal_bridge01.mdl"
        }

        local sents = {
            "grenade_helicopter",
            "prop_thumper"
        }

        hook.Add("PlayerSpawnProp", "FunnyProps::ModelBlock", function(ply, model)
            for _, m in pairs(models) do
                if string.find(model, m) and not ply:IsAdmin() then
                    print(ply:Nick() .. " attempted to spawn blocked model " .. model)

                    return false
                end
            end
        end)

        hook.Add("PlayerSpawnSENT", "FunnyProps::SENTBlock", function(ply, ent)
            for _, s in pairs(sents) do
                if string.find(ent, s) and not ply:IsAdmin() then
                    print(ply:Nick() .. " attempted to spawn blocked SENT " .. ent)

                    return false
                end
            end
        end)
    end

    --Entity penetration checker to prevent massive lag due to entities being unfrozen inside of eachother
    do
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
                if IsValid(ent:CPPIGetOwner()) and ent:GetPhysicsObject():IsValid() then
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

                if count > 2 then
                    if not ply.freezeCount then
                        ply.freezeCount = 0
                    end

                    ply.freezeCount = ply.freezeCount + 1
                    ply:SendMsg(preC, pre, Color(255, 255, 255), count .. " of your entities were frozen due to penetrating eachother")

                    for ent, _ in pairs(ply.penetrating) do
                        if not ent:IsValid() then
                            ply.penetrating[ent] = nil
                            continue
                        end

                        ent:GetPhysicsObject():EnableMotion(false)

                        if ent:GetClass() == "prop_vehicle_jeep" or ent:GetClass() == "prop_vehicle_jalopy" then
                            ent:Remove()
                            ply:SendMsg(preC, pre, Color(255, 255, 255), "Cannot freeze " .. ent:GetClass() .. ", removing")
                        end

                        ply.penetrating[ent] = nil
                    end

                    if ply.freezeCount > 3 then
                        ply:FreezeProps()
                        ply.freezeLockout = true
                        ply:SetNWBool("PCLockout", true)
                        ply:SendMsg(preC, pre, Color(255, 255, 255), "Stop doing that - all of your entities have been frozen and you have been temporarily restricted from further spawning...")
                        BroadcastMsg(preC, pre, Color(255, 255, 255), ply:Nick() .. " has been temporarily restricted due to repeatedly creating penetrating physics objects")

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

        local function lockout(ply)
            if ply.freezeLockout then return false end
        end

        hook.Add("CanTool", "PenCheck::Lockout", lockout)
        hook.Add("PlayerSpawnProp", "PenCheck::Lockout", lockout)
        hook.Add("PlayerSpawnSENT", "PenCheck::Lockout", lockout)
        hook.Add("PlayerSpawnVehicle", "PenCheck::Lockout", lockout)
        hook.Add("PhysgunPickup", "PenCheck::Lockout", lockout)
        hook.Add("OnPhysgunReload", "PenCheck::Lockout", lockout)
    end

    --Check time between each tick, try and deal with lag if tick time "score" exceeds set value
    do
        local interval = engine.TickInterval()
        local intervalMs = math.Round(interval * 1000)
        local lastTick = SysTime()
        local lag = 0
        local bigLag = false

        local function freezeAll()
            for _, v in pairs(ents.GetAll()) do
                if v:IsValid() and v:CPPIGetOwner() and v:GetPhysicsObject():IsValid() then
                    v:GetPhysicsObject():EnableMotion(false)
                end
            end
        end

        local collisionGroups = {}

        local function disableCollisions()
            for _, v in pairs(ents.GetAll()) do
                if v:IsValid() and v:CPPIGetOwner() and v:CPPIGetOwner():IsValid() and v:GetPhysicsObject():IsValid() then
                    collisionGroups[v] = v:GetCollisionGroup()
                    v:SetCollisionGroup(20)
                end
            end
        end

        local function restoreCollisions()
            for k, v in pairs(collisionGroups) do
                if k:IsValid() then
                    k:SetCollisionGroup(v)
                end
            end

            table.Empty(collisionGroups)
        end

        hook.Add("Tick", "LagDet::Tick", function()
            local tickTime = SysTime() - lastTick
            local tickTimeMs = math.Round(tickTime * 1000)
            lag = lag + math.max(tickTimeMs, intervalMs)

            if tickTimeMs > 500 then
                MsgC(Color(255, 0, 0), "Warning: last tick took " .. tickTimeMs .. "ms\n")
            end

            if lag > 500 and not bigLag then
                BroadcastMsg(Color(100, 255, 100), "[AntiLag]", Color(255, 255, 255), " All props have been frozen and entity collisions have been temporarily disabled until lag subsides")
                bigLag = true
                freezeAll()
                disableCollisions()
            end

            if lag < 50 and bigLag then
                BroadcastMsg(Color(100, 255, 100), "[AntiLag]", Color(255, 255, 255), " Lag subsided, collisions restored")
                bigLag = false
                restoreCollisions()
            end

            lag = math.Clamp(lag - intervalMs - 3, 0, 2500)
            lastTick = SysTime()
        end)

        --Prevent any new props and spawned dupes from having collisions during a lag event
        hook.Add("OnEntityCreated", "AntiLag::DisableCollisionsOnCreation", function(ent)
            if bigLag then
                timer.Simple(0, function()
                    if ent:IsValid() and ent:GetPhysicsObject():IsValid() then
                        collisionGroups[ent] = ent:GetCollisionGroup()
                        ent:SetCollisionGroup(20)
                    end
                end)
            end
        end)

        hook.Add("AdvDupe_FinishPasting", "AntiLag::PasteCollisions", function(data)
            if bigLag then
                for _, ent in pairs(data[1].CreatedEntities) do
                    if ent:IsValid() and ent:GetPhysicsObject():IsValid() then
                        collisionGroups[ent] = ent:GetCollisionGroup()
                        ent:SetCollisionGroup(20)
                    end
                end
            end
        end)
    end

    --Disable being able to double tap R to unfreeze all owned ents
    --Couldn't find a hook specifically for this, had to do this jank
    do
        local PLAYER = FindMetaTable("Player")

        if PLAYER.OLD_PhysgunUnfreeze then
            PLAYER.PhysgunUnfreeze = PLAYER.OLD_PhysgunUnfreeze
        end

        PLAYER.OLD_PhysgunUnfreeze = PLAYER.PhysgunUnfreeze

        function PLAYER:PhysgunUnfreeze()
            local ret = self:OLD_PhysgunUnfreeze()
            self.LastPhysUnfreeze = -math.huge

            return ret
        end
    end

    --Prevent dupes from being pasted with "Unfreeze all entities after paste"
    hook.Add("AdvDupe_FinishPasting", "AntiLag::PasteFreeze", function(data)
        for _, ent in pairs(data[1].CreatedEntities) do
            ent:GetPhysicsObject():EnableMotion(false)
        end
    end)

    --Disable being able to parent race seats to superthin sprops plates - causes crashes
    do
        local ENTITY = FindMetaTable("Entity")

        if ENTITY.OLD_SetParent then
            ENTITY.SetParent = ENTITY.OLD_SetParent
        end

        ENTITY.OLD_SetParent = ENTITY.SetParent

        function ENTITY:SetParent(parent, attachmentId)
            if parent and string.find(self:GetModel(), "raceseat") and self:IsVehicle() and string.find(parent:GetModel(), "superthin") then return end
            self:OLD_SetParent(parent, attachmentId)
        end
    end
else
    --Prevent clients from seeing their toolgun work clientside while restricted from using it
    hook.Add("CanTool", "PenCheck::Lockout", function(ply)
        if ply:GetNWBool("PCLockout") then return false end
    end)
end