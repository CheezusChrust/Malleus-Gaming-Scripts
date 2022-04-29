--More prop info when aiming at entities
--Overrides the stock NADMod HUD

--Regular vectors are heavily compressed, have to do this for accuracy
local function setNWVectorPrecise(ent, key, value)
    ent:SetNWFloat(key .. "_x", value[1])
    ent:SetNWFloat(key .. "_y", value[2])
    ent:SetNWFloat(key .. "_z", value[3])
end

local function getNWVectorPrecise(ent, key, fallback)
    local x = ent:GetNWFloat(key .. "_x", fallback[1])
    local y = ent:GetNWFloat(key .. "_y", fallback[2])
    local z = ent:GetNWFloat(key .. "_z", fallback[3])

    return Vector(x, y, z)
end

if SERVER then
    timer.Create("PI::PropData", 0.1, 0, function()
        for _, ply in pairs(player.GetAll()) do
            local ent = ply:GetEyeTrace().Entity
            if not ent:IsValid() or not ent:GetPhysicsObject():IsValid() or not IsValid(ent:CPPIGetOwner()) then continue end
            local inertia = ent:GetPhysicsObject():GetInertia()
            setNWVectorPrecise(ply, "PI::Inertia", inertia)
            ply:SetNWInt("PI::Mass", ent:GetPhysicsObject():GetMass())
            local physprop = ent:GetPhysicsObject():GetMaterial()
            ply:SetNWString("PI::PhysProp", physprop[1] == "$" and "Unknown" or physprop)
        end
    end)
else
    CreateClientConVar("propinfo_mode", 2, true, false, "Display mode for PropInfo - 0 is off, 1 is basic info, 2 is full info", 0, 2)
    CreateClientConVar("propinfo_justify", 1, true, false, "0 - Justify left, 1 - Justify right", 0, 1)
    CreateClientConVar("propinfo_x", 0.99, true, false, "A number between 0 and 1, with 0 being the left of your screen and 1 being the right", 0, 1)
    CreateClientConVar("propinfo_y", 0.4, true, false, "A number between 0 and 1, with 0 being the top of your screen and 1 being the bottom", 0, 1)

    local function matrixToString(m, round)
        round = round or 10

        return "[" .. math.Round(m[1], round) .. ", " .. math.Round(m[2], round) .. ", " .. math.Round(m[3], round) .. "]"
    end

    local x, y = ScrW(), ScrH()

    timer.Simple(1, function()
        hook.Remove("HUDPaint", "NADMOD.HUDPaint") --Sorry NADmod!
    end)

    local ownedByWorld = {
        "prop_door",
        "prop_dynamic",
        "func_",
        "C_BaseEntity"
    }

    local function getEntityOwner(E)
        if not E:IsValid() then return end
        if not E:CPPIGetOwner() then
            for _, v in pairs(ownedByWorld) do
                if string.find(E:GetClass(), v) then return "World" end
            end
            return "Unknown"
        end
        return E:CPPIGetOwner():Nick()
    end

    hook.Add("HUDPaint", "PI::PropInfo", function()
        local aimEntity = LocalPlayer():GetEyeTrace().Entity
        if not aimEntity:IsValid() then return end
        if aimEntity:GetClass() == "player" then return end
        local xPos = tonumber(GetConVar("propinfo_x"):GetString()) or 0.01
        local yPos = tonumber(GetConVar("propinfo_y"):GetString()) or 0.01
        local mode = GetConVar("propinfo_mode"):GetInt()
        local mode2 = mode - (getEntityOwner(aimEntity) == "World" and 1 or 0)
        local justify = GetConVar("propinfo_justify"):GetInt()

        if mode < 1 then return end

        local inertia = getNWVectorPrecise(LocalPlayer(), "PI::Inertia", Vector())
        inertia = inertia:Length() > 4294967295 and Vector() or inertia
        local mass = math.Round(LocalPlayer():GetNWInt("PI::Mass"))
        local physprop = LocalPlayer():GetNWString("PI::PhysProp")

        local split = string.Split(aimEntity:GetModel(), "/")
        local modelStr = split[#split] .. " [" .. aimEntity:EntIndex() .. "]"
        local classStr = "Class: " .. aimEntity:GetClass()
        local ownerStr = "Owner: " .. getEntityOwner(aimEntity)
        local angleStr = "Angle: " .. matrixToString(aimEntity:GetAngles(), 3)
        local inertiaStr = "Inertia: " .. (inertia ~= Vector() and matrixToString(inertia, 2) or "Unknown")
        local physpropStr = "Physprop: " .. (physprop and physprop or "Unknown")

        surface.SetFont("ChatFont")
        local w0 = select(1, surface.GetTextSize(ownerStr))
        local w1 = select(1, surface.GetTextSize(modelStr))
        local w2 = mode2 > 1 and select(1, surface.GetTextSize(inertiaStr)) or 0
        local w3 = select(1, surface.GetTextSize(classStr))
        local w4 = mode2 > 1 and select(1, surface.GetTextSize(angleStr)) or 0
        local w5 = mode2 > 1 and select(1, surface.GetTextSize(physpropStr)) or 0
        local width = math.max(w0 + 8, w1 + 8, w2 + 8, w3 + 8, w4 + 8, w5 + 8)

        if justify < 1 then
            draw.RoundedBox(5, x * xPos, y * yPos, width, 62 + (mode2 - 1) * 80, Color(0, 0, 0, 127))
        else
            draw.RoundedBox(5, (x * xPos) - width, y * yPos, width, 62 + (mode2 - 1) * 80, Color(0, 0, 0, 127))
        end

        draw.SimpleText(ownerStr, "ChatFont", x * (xPos + 0.002 - justify * 0.004), y * (yPos + 0.002), Color(255, 255, 255), justify * 2, 0)
        draw.SimpleText(modelStr, "ChatFont", x * (xPos + 0.002 - justify * 0.004), y * (yPos + 0.002) + 20, Color(255, 255, 255), justify * 2, 0)
        draw.SimpleText(classStr, "ChatFont", x * (xPos + 0.002 - justify * 0.004), y * (yPos + 0.002) + 40, Color(255, 255, 255), justify * 2, 0)

        if mode2 > 1 then
            draw.SimpleText(angleStr, "ChatFont", x * (xPos + 0.002 - justify * 0.004), y * (yPos + 0.002) + 60, Color(255, 255, 255), justify * 2, 0)
            draw.SimpleText(inertiaStr, "ChatFont", x * (xPos + 0.002 - justify * 0.004), y * (yPos + 0.002) + 80, Color(255, 255, 255), justify * 2, 0)
            draw.SimpleText("Mass: " .. (mass and (mass .. "kg") or "Unknown"), "ChatFont", x * (xPos + 0.002 - justify * 0.004), y * (yPos + 0.002) + 100, Color(255, 255, 255), justify * 2, 0)
            draw.SimpleText(physpropStr, "ChatFont", x * (xPos + 0.002 - justify * 0.004), y * (yPos + 0.002) + 120, Color(255, 255, 255), justify * 2, 0)
        end
    end)
end