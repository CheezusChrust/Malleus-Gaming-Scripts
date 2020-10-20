if SERVER then
    local preC = Color(100, 255, 100)
    local pre = "[AntiLag] "
    CreateConVar("antilag_pencheck_lockoutduration", 15, {FCVAR_ARCHIVE}, "How long a player is restricted from interacting with or creating entities after too much entity penetration, in seconds", 1, 1800)
    CreateConVar("antilag_pencheck_enable", 1, {FCVAR_ARCHIVE}, "Enable penetration checking", 0, 1)
    CreateConVar("antilag_pencheck_maxpenetrating", 3, {FCVAR_ARCHIVE}, "Maximum amount of props that can be penetrating eachother before freezing them", 2, 10)
    CreateConVar("antilag_ticktime_threshold", 750, {FCVAR_ARCHIVE}, "What 'score' is required in order to trigger the anti lag features - this is calculated by repeatedly adding the previous tick time and subtracting the expected tick time", 100, 10000)
    CreateConVar("antilag_ticktime_cooldownrate", 3, {FCVAR_ARCHIVE}, "Rate at which the lag 'score' is lowered per tick", 1, 100)
    CreateConVar("antilag_ticktime_enablecheck", 1, {FCVAR_ARCHIVE}, "Enable or disable freezing and nocolliding props based on time between ticks", 0, 1)

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
        local trackedEnts = {}
        local PLAYER = FindMetaTable("Player")

        function PLAYER:FreezeProps()
            for _, ent in pairs(ents.GetAll()) do
                if ent:GetPhysicsObject():IsValid() and ent:CPPIGetOwner() and ent:CPPIGetOwner() == self then
                    ent:GetPhysicsObject():EnableMotion(false)
                end
            end
        end

        --Maintain a table of existing entities, instead of repeatedly calling ent.GetAll() every tick which is horribly inefficient
        hook.Add("OnEntityCreated", "PenCheck::EntCreated", function(ent)
            timer.Simple(0, function()
                if not ent:CPPIGetOwner() then return end

                if ent:IsValid() and ent:GetPhysicsObject():IsValid() and ent:GetPhysicsObject() ~= game.GetWorld():GetPhysicsObject() and ent:CPPIGetOwner() ~= Entity(0) then
                    trackedEnts[ent] = true
                end
            end)
        end)

        hook.Add("EntityRemoved", "PenCheck::EntRemoved", function(ent)
            if trackedEnts[ent] then
                trackedEnts[ent] = nil
            end
        end)

        hook.Add("Think", "PenCheck::Think", function()
            if not GetConVar("antilag_pencheck_enable"):GetBool() then return end
            for ent, _ in pairs(trackedEnts) do
                --Get rid of NULL entities or bad physobjects
                if not ent:IsValid() or not ent:GetPhysicsObject():IsValid() then
                    trackedEnts[ent] = nil
                    continue
                end

                --Skip frozen and parented entities
                if ent:GetParent():IsValid() or not ent:GetPhysicsObject():IsMoveable() then continue end

                --Check whether unfrozen entities are penetrating eachother, and if they are, maintain a table of them per-player
                if ent:CPPIGetOwner() and ent:CPPIGetOwner():IsValid() and ent:GetPhysicsObject():IsValid() then
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

                if count > GetConVar("antilag_pencheck_maxpenetrating"):GetInt() then
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

                        timer.Simple(GetConVar("antilag_pencheck_lockoutduration"):GetInt(), function()
                            if not ply:IsValid() then return end
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
        local lagScore = 0
        local lagEvent = false

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

        hook.Add("Tick", "AntiLag::Tick", function()
            if not GetConVar("antilag_ticktime_enablecheck"):GetBool() then return end
            local tickTime = SysTime() - lastTick
            local tickTimeMs = math.Round(tickTime * 1000)
            lagScore = lagScore + math.max(tickTimeMs, intervalMs)

            if lagScore > GetConVar("antilag_ticktime_threshold"):GetInt() and not lagEvent then
                BroadcastMsg(Color(100, 255, 100), "[AntiLag]", Color(255, 255, 255), " All props have been frozen and entity collisions have been temporarily disabled until lag subsides")
                lagEvent = true
                freezeAll()
                disableCollisions()
            end

            if lagScore < 50 and lagEvent then
                BroadcastMsg(Color(100, 255, 100), "[AntiLag]", Color(255, 255, 255), " Lag subsided, collisions restored")
                lagEvent = false
                restoreCollisions()
            end

            lagScore = math.Clamp(lagScore - intervalMs - GetConVar("antilag_ticktime_cooldownrate"):GetInt(), 0, 2500)
            lastTick = SysTime()
        end)

        --Prevent any new props and spawned dupes from having collisions during a lag event
        hook.Add("OnEntityCreated", "AntiLag::DisableCollisionsOnCreation", function(ent)
            if lagEvent then
                timer.Simple(0, function()
                    if ent:IsValid() and ent:GetPhysicsObject():IsValid() then
                        collisionGroups[ent] = ent:GetCollisionGroup()
                        ent:SetCollisionGroup(20)
                    end
                end)
            end
        end)

        hook.Add("AdvDupe_FinishPasting", "AntiLag::PasteCollisions", function(data)
            if lagEvent then
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
            if ent:IsValid() and ent:GetPhysicsObject():IsValid() then
                ent:GetPhysicsObject():EnableMotion(false)
            end
        end
    end)

    --Disable parenting on funky entities
    do
        local parentBlacklist = {
            ["prop_vehicle_jeep"] = true,
            ["prop_vehicle_airboat"] = true,
            ["prop_vehicle_jalopy"] = true
        }

        local ENTITY = FindMetaTable("Entity")

        if ENTITY.OLD_SetParent then
            ENTITY.SetParent = ENTITY.OLD_SetParent
        end

        ENTITY.OLD_SetParent = ENTITY.SetParent

        function ENTITY:SetParent(parent, attachmentId)
            if parent and string.find(self:GetModel() or "", "raceseat") and self:IsVehicle() and string.find(parent:GetModel() or "", "superthin") then return end
            if parent and parentBlacklist[self:GetClass()] then return end
            self:OLD_SetParent(parent, attachmentId)
        end
    end
else
    --Prevent clients from seeing their toolgun work clientside while restricted from using it
    hook.Add("CanTool", "PenCheck::Lockout", function(ply)
        if ply:GetNWBool("PCLockout") then return false end
    end)
end