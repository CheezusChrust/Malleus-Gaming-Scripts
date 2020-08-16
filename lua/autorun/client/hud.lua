--Basic HL2 HUD replacement
--By Wizard (https://steamcommunity.com/profiles/76561197998272665)

CreateClientConVar("wizhud_enabled", "1", true, false)
local isEnabled = 1

timer.Simple(60, function()
    chat.AddText(Color(127, 159, 255), "You can disable our custom hud by doing 'wizhud_enabled 0' in your console.")
    LocalPlayer():ConCommand("hud_quickinfo 0")
end)

surface.CreateFont("HUDfont", {
    font = "Ebrima",
    extended = false,
    size = 26,
    weight = 500,
    blursize = 0,
    scanlines = 1,
    antialias = true,
    underline = false,
    italic = false,
    strikeout = false,
    symbol = false,
    rotary = false,
    shadow = false,
    additive = true,
    outline = true
})

timer.Create("wh_CheckConVar", 0.1, 0, function()
    isEnabled = GetConVar("wizhud_enabled"):GetInt()
end)

--print(isEnabled)
local averaging = false
local avg_resolution = 25
local avgT = {}

for i = 1, avg_resolution do
    avgT[i] = 0
end

local avg_resolution_fps = 120
local avgFPS = {}

for i = 1, avg_resolution_fps do
    avgFPS[i] = 0
end

local function pushGetAvg(num)
    table.remove(avgT, 1)
    avgT[#avgT + 1] = num
    local n = 0

    for i = 1, #avgT do
        n = n + avgT[i]
    end

    return n / #avgT
end

local function pushGetAvgFPS(num)
    table.remove(avgFPS, 1)
    avgFPS[#avgFPS + 1] = num
    local n = 0

    for i = 1, #avgFPS do
        n = n + avgFPS[i]
    end

    return n / #avgFPS
end

local function rootParent(ent)
    if not ent:IsValid() then return end

    if ent:GetParent():IsValid() then
        return rootParent(ent:GetParent())
    else
        return ent
    end
end

local spavg = 0

hook.Add("Tick", "averaging", function()
    if averaging then
        spavg = pushGetAvg(rootParent(LocalPlayer():GetVehicle()):GetVelocity():Length() / 17.6)
    end
end)

function hud()
    local ColorH = Color(215, 120, 120)
    local ColorA = Color(120, 120, 215, 100)
    local health = math.Clamp(LocalPlayer():Health(), 0, 100)
    local healthnum = LocalPlayer():Health()
    local armor = math.Clamp(LocalPlayer():Armor(), 0, 100)
    local width = 300
    local height = 25
    local heightarmor = 25
    averaging = LocalPlayer():InVehicle()
    local speed = LocalPlayer():InVehicle() and spavg or (LocalPlayer():GetVelocity():Length() / 17.6)
    speed = math.Clamp(math.Round(speed), 0, 999)
    local fps = pushGetAvgFPS(1 / RealFrameTime())

    --[[
    if !LocalPlayer():InVehicle() then
        speed = LocalPlayer():GetVelocity():Length() / 17.6
        averaging = false
    else
        averaging = true
        speed = spavg
    end
    speed = math.Clamp(math.Round(speed),0,999)
    --]]
    --Bar
    if health >= 1 then
        --bounding box
        draw.RoundedBox(5, 15, ScrH() - 85, width + 10, height + 40, Color(28, 28, 28, 220))
        --health
        draw.RoundedBox(0, 18, ScrH() - 82, width + 4, height + 4, Color(28, 28, 28, 220))
        draw.RoundedBox(2, 20, ScrH() - 80, health * width / 100, height, ColorH)

        if armor >= 1 then
            draw.RoundedBox(2, 20, ScrH() - 80, armor * width / 100, heightarmor, ColorA)
        end

        draw.SimpleText("HP: " .. healthnum, "HUDfont", height, ScrH() - 68, Color(255, 255, 255, 255), 0, 1)
        draw.SimpleText("MPH: " .. speed, "HUDfont", height, ScrH() - 38, Color(255, 255, 255, 255), 0, 1)
        draw.SimpleText("FPS: " .. math.floor(fps), "HUDfont", height + 104, ScrH() - 38, Color(255, 255, 255, 255), 0, 1)
        draw.SimpleText("PING: " .. LocalPlayer():Ping(), "HUDfont", height + 206, ScrH() - 38, Color(255, 255, 255, 255), 0, 1)
    end
end

hook.Add("HUDPaint", "WizHud", function()
    if isEnabled == 1 then
        hud()
    end
end)

--hide gmod hud
hook.Add("HUDShouldDraw", "wh_disableHUD", function(name)
    if isEnabled == 1 then
        for k, v in pairs({"CHudHealth", "CHudBattery"}) do
            if name == v then return false end
        end
    else
        for k, v in pairs({"CHudHealth", "CHudBattery"}) do
            if name == v then return true end
        end
    end
end)