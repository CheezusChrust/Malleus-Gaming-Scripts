--More prop info when aiming at entities
--Overrides the stock NADMod HUD

if SERVER then
    util.AddNetworkString("PI::PropData")

    local function getDiff(old, new)
        local diff = {}

        for k, v in pairs(new) do
            if old[k] ~= v then
                diff[k] = v
            end
        end

        return diff
    end

    local playerEntData = {}

    timer.Create("PI::PropData", 0.1, 0, function()
        for _, ply in ipairs(player.GetAll()) do
            if not playerEntData[ply] then
                playerEntData[ply] = {}
            end

            local aimEntity = ply:GetEyeTrace().Entity
            local physobj = IsValid(aimEntity) and aimEntity:GetPhysicsObject()

            if IsValid(aimEntity) and IsValid(physobj) then
                local curData = {
                    inertia = physobj:GetInertia(),
                    physprop = physobj:GetMaterial(),
                    mass = physobj:GetMass()
                }

                if table.Count(getDiff(playerEntData[ply], curData)) > 0 then
                    playerEntData[ply] = curData

                    net.Start("PI::PropData", true)
                    net.WriteFloat(curData.inertia.x)
                    net.WriteFloat(curData.inertia.y)
                    net.WriteFloat(curData.inertia.z)
                    net.WriteString(curData.physprop)
                    net.WriteFloat(curData.mass)
                    net.Send(ply)
                end
            end
        end
    end)
else
    local function matrixToString(m, decimals)
        decimals = decimals or 10

        return "[" .. math.Round(m[1], decimals) .. ", " .. math.Round(m[2], decimals) .. ", " .. math.Round(m[3], decimals) .. "]"
    end

    timer.Simple(1, function()
        hook.Remove("HUDPaint", "NADMOD.HUDPaint")
    end)

    local propData = {
        inertia = Vector(),
        physprop = "Unknown",
        mass = 0
    }

    net.Receive("PI::PropData", function()
        local inertia = Vector(net.ReadFloat(), net.ReadFloat(), net.ReadFloat())
        local physprop = net.ReadString()
        local mass = net.ReadFloat()

        propData.inertia = inertia
        propData.physprop = physprop
        propData.mass = mass
    end)

    local classesOwnedByWorld = {
        "prop_door",
        "prop_dynamic",
        "func_",
        "C_BaseEntity"
    }

    local function getOwnerName(ent)
        if not IsValid(ent) then return end

        if NADMOD and NADMOD.PropNames[ent:EntIndex()] then return NADMOD.PropNames[ent:EntIndex()] end

        local owner = CPPI and ent:CPPIGetOwner()

        if not owner then
            for _, v in ipairs(classesOwnedByWorld) do
                if string.find(ent:GetClass(), v) then return "World" end
            end

            return "N/A"
        end

        return owner:Nick()
    end

    hook.Add("HUDPaint", "PI::PropInfo", function()
        local scrW, scrH = ScrW(), ScrH()
        local ply = LocalPlayer()

        local aimEntity = ply:GetEyeTrace().Entity
        if not IsValid(aimEntity) then return end
        if aimEntity:GetClass() == "player" then return end

        local xPos = 0.99
        local yPos = 0.4

        local inertia = propData.inertia or Vector()
        if inertia:Length() > 4294967295 or inertia == Vector() then
            inertia = "Unknown"
        else
            inertia = matrixToString(inertia, 2)
        end

        local owner = getOwnerName(aimEntity)
        local model = aimEntity:GetModel():match("/?([^/]+)$") .. " [" .. aimEntity:EntIndex() .. "]"
        if model[1] == "*" then
            model = "N/A"
        end

        local class = aimEntity:GetClass()
        local mass = math.Round(propData.mass, 2) or 0
        local physprop = propData.physprop or "Unknown"
        if physprop[1] == "$" then
            physprop = "Unknown"
        end

        local angle = matrixToString(aimEntity:GetAngles(), 3)

        local text = "Owner: " .. owner .. "\n" ..
                    "Model: " .. model .. "\n" ..
                    "Class: " .. class

        if owner ~= "World" then
            text = text .. "\nMass: " .. mass .. "\n" ..
                        "Physprop: " .. physprop .. "\n" ..
                        "Inertia: " .. inertia .. "\n" ..
                        "Angle: " .. angle
        end

        surface.SetFont("ChatFont")
        local textWidth, textHeight = surface.GetTextSize(text)
        local textWidth = textWidth + 8
        local textHeight = textHeight + 8
        draw.RoundedBox(5, scrW * xPos - textWidth + 4, scrH * yPos - 4, textWidth, textHeight, Color(0, 0, 0, 127))
        draw.DrawText(text, "ChatFont", scrW * xPos, scrH * yPos, Color(255, 255, 255), 2)
    end)
end