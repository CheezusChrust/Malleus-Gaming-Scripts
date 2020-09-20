--Block people from using annoying models

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

--Freeze all entities immediately on creation
--TODO: Find out why this errors if props are spammed fast enough
--[[
hook.Add("OnEntityCreated", "FunnyProps::EntFreeze", function(ent)
    if ent:GetClass() == "prop_physics" and IsValid(ent) and ent:IsValid() then
        timer.Simple(0, function()
            ent:GetPhysicsObject():EnableMotion(false)
        end)
    end
end)
--]]

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
hook.Add("AdvDupe_FinishPasting", "FunnyProps::PasteFreeze", function(data)
    for _, ent in pairs(data[1].CreatedEntities) do
        ent:GetPhysicsObject():EnableMotion(false)
    end
end)


--Block cancerous models for non-admins
hook.Add("PlayerSpawnProp", "FunnyProps::ModelBlock", function(ply, model)
    for _, m in pairs(models) do
        if string.find(model, m, 1, true) and not ply:IsAdmin() then
            print(ply:Nick() .. " attempted to spawn blocked model " .. model)

            return false
        end
    end
end)

--Block cancerous SENTs from non-admins
hook.Add("PlayerSpawnSENT", "FunnyProps::SENTBlock", function(ply, ent)
    for _, s in pairs(sents) do
        if string.find(ent, s, 1, true) and not ply:IsAdmin() then
            print(ply:Nick() .. " attempted to spawn blocked SENT " .. ent)

            return false
        end
    end
end)