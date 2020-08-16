--More prop info when aiming at entities
--Overrides the stock NADMod HUD

if SERVER then
    util.AddNetworkString("PI::SendData")

    timer.Create("PI::PropData", 0.1, 0, function()
        for _, v in pairs(player.GetAll()) do
            local ent = v:GetEyeTrace().Entity
            if not ent:IsValid() or not ent:GetPhysicsObject():IsValid() or not IsValid(ent:CPPIGetOwner()) then continue end
            local inertia = ent:GetPhysicsObject():GetInertia()
            net.Start("PI::SendData")
            net.WriteFloat(inertia.x)
            net.WriteFloat(inertia.y)
            net.WriteFloat(inertia.z)
            net.WriteUInt(math.Round(ent:GetPhysicsObject():GetMass()), 16)
            local physprop = ent:GetPhysicsObject():GetMaterial()
            net.WriteString(physprop[1] == "$" and "Unknown" or physprop)
            net.Send(v)
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

    local inertia
    local mass
    local physprop

    net.Receive("PI::SendData", function()
        inertia = Vector(net.ReadFloat(), net.ReadFloat(), net.ReadFloat())

        if inertia:Length() > 4294967295 then
            inertia = nil
        end

        mass = net.ReadUInt(16)
        physprop = net.ReadString()
    end)

    local x, y = ScrW(), ScrH()

    timer.Simple(1, function()
        hook.Remove("HUDPaint", "NADMOD.HUDPaint") --Sorry NADmod!
    end)

    hook.Add("HUDPaint", "PI::PropInfo", function()
        surface.SetFont("ChatFont")
        local xPos = tonumber(GetConVar("propinfo_x"):GetString()) or 0.01
        local yPos = tonumber(GetConVar("propinfo_y"):GetString()) or 0.01
        local mode = GetConVar("propinfo_mode"):GetInt()
        local justify = GetConVar("propinfo_justify"):GetInt()
        if mode < 1 then return end
        local aimEntity = LocalPlayer():GetEyeTrace().Entity
        if not aimEntity:IsValid() then return end
        if not IsValid(aimEntity:CPPIGetOwner()) then return end
        local split = string.Split(aimEntity:GetModel(), "/")
        local modelStr = split[#split] .. " [" .. aimEntity:EntIndex() .. "]"
        local classStr = "Class: " .. aimEntity:GetClass()
        local ownerStr = "Owner: " .. aimEntity:CPPIGetOwner():Nick()
        local angleStr = "Angle: " .. matrixToString(aimEntity:GetAngles(), 3)
        local inertiaStr = "Inertia: " .. (inertia and matrixToString(inertia, 3) or "Unknown")
        local w0 = select(1, surface.GetTextSize(ownerStr))
        local w1 = select(1, surface.GetTextSize(modelStr))
        local w2 = mode > 1 and select(1, surface.GetTextSize(inertiaStr)) or 0
        local w3 = select(1, surface.GetTextSize(classStr))
        local w4 = mode > 1 and select(1, surface.GetTextSize(angleStr)) or 0
        local width = math.max(w0 + 8, w1 + 8, w2 + 8, w3 + 8, w4 + 8)

        if justify < 1 then
            draw.RoundedBox(5, x * xPos, y * yPos, width, 62 + (mode - 1) * 80, Color(0, 0, 0, 127))
        else
            draw.RoundedBox(5, (x * xPos) - width, y * yPos, width, 62 + (mode - 1) * 80, Color(0, 0, 0, 127))
        end

        draw.SimpleText(ownerStr, "ChatFont", x * (xPos + 0.002 - justify * 0.004), y * (yPos + 0.002), Color(255, 255, 255), justify * 2, 0)
        draw.SimpleText(modelStr, "ChatFont", x * (xPos + 0.002 - justify * 0.004), y * (yPos + 0.002) + 20, Color(255, 255, 255), justify * 2, 0)
        draw.SimpleText(classStr, "ChatFont", x * (xPos + 0.002 - justify * 0.004), y * (yPos + 0.002) + 40, Color(255, 255, 255), justify * 2, 0)

        if GetConVar("propinfo_mode"):GetInt() > 1 then
            draw.SimpleText(angleStr, "ChatFont", x * (xPos + 0.002 - justify * 0.004), y * (yPos + 0.002) + 60, Color(255, 255, 255), justify * 2, 0)
            draw.SimpleText(inertiaStr, "ChatFont", x * (xPos + 0.002 - justify * 0.004), y * (yPos + 0.002) + 80, Color(255, 255, 255), justify * 2, 0)
            draw.SimpleText("Mass: " .. (mass and (mass .. "kg") or "Unknown"), "ChatFont", x * (xPos + 0.002 - justify * 0.004), y * (yPos + 0.002) + 100, Color(255, 255, 255), justify * 2, 0)
            draw.SimpleText("Physprop: " .. (physprop and physprop or "Unknown"), "ChatFont", x * (xPos + 0.002 - justify * 0.004), y * (yPos + 0.002) + 120, Color(255, 255, 255), justify * 2, 0)
        end
    end)
end