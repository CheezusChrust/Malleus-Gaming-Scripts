CreateConVar("avtohud_unit", "km/h", {FCVAR_ARCHIVE}, "Speed unit for HUD, default is km/h")
CreateConVar("avtohud_textcolor", "255,255,255", {FCVAR_ARCHIVE}, "Color of the text, in the format R,G,B")
CreateConVar("avtohud_enabled", "1", {FCVAR_ARCHIVE}, "Revert to the default HUD by setting this to 0", 0, 1)

local units = {
    ["mph"] = 17.6,
    ["km/h"] = 10.9361,
    ["m/s"] = 39.3701,
    ["u/s"] = 1,
    ["kts"] = 20.2537
}

--Revert to km/h if unit set on script load is invalid
if not units[GetConVar("avtohud_unit"):GetString()] then
    GetConVar("avtohud_unit"):SetString("km/h")
end

hook.Add("InitPostEntity", "avtohud_info", function()
    timer.Simple(1, function()
        chat.AddText(Color(115, 236, 115), "[AvtoHUD] ", Color(255, 255, 255), "You can edit the HUD by typing ", Color(255, 0, 0), "avtohud_", Color(255, 255, 255), " in your console.")
        chat.AddText(Color(115, 236, 115), "[AvtoHUD] ", Color(255, 255, 255), "Supported units for speed are ", Color(255, 0, 0), table.concat(table.GetKeys(units), ", "), Color(255, 255, 255), ".")
    end)
end)

local function stringToColor(str)
    local r, g, b = str:match("^(%d?%d?%d),(%d?%d?%d),(%d?%d?%d)$")

    if not r or not g or not b then
        print("[AvtoHUD] Invalid color")

        return
    end

    r = tonumber(r)
    g = tonumber(g)
    b = tonumber(b)

    if r > 255 or g > 255 or b > 255 then
        print("[AvtoHUD] Invalid color")

        return
    end

    return Color(r, g, b)
end

local textColor

--You will not break my convars
if not stringToColor(GetConVar("avtohud_textcolor"):GetString()) then
    textColor = Color(255, 255, 255)

    GetConVar("avtohud_textcolor"):SetString("255,255,255")
else
    textColor = stringToColor(GetConVar("avtohud_textcolor"):GetString())
end

cvars.RemoveChangeCallback("avtohud_unit", "avtohud_unit_callback")
cvars.AddChangeCallback("avtohud_unit", function(_, oldValue, newValue)
    if not units[newValue] then
        print("[AvtoHUD] Invalid unit specified - valid units are " .. table.concat(table.GetKeys(units), ", "))
        GetConVar("avtohud_unit"):SetString(oldValue)
    end
end, "avtohud_unit_callback")

cvars.RemoveChangeCallback("avtohud_textcolor", "avtohud_textcolor_callback")
cvars.AddChangeCallback("avtohud_textcolor", function(_, oldValue, newValue)
    textColor = stringToColor(newValue)

    if not textColor then
        textColor = stringToColor(oldValue)

        GetConVar("avtohud_textcolor"):SetString(oldValue)
    end
end, "avtohud_textcolor_callback")

surface.CreateFont("AvtoHud", {
    font = "ChatFont",
    size = 22
})

local function pushGetAvg(tbl, count, val)
    if #tbl > count then
        table.remove(tbl, 1)
    end

    tbl[#tbl + 1] = val
    local avg = 0

    for _, v in ipairs(tbl) do
        avg = avg + v
    end

    return avg / #tbl
end

local function rootParent(ent)
    if ent:GetParent():IsValid() then
        return rootParent(ent:GetParent())
    else
        return ent
    end
end


local fpsAvg = {}
local velAvg = {}

hook.Add("HUDPaint", "AvtoHud", function()
    if not GetConVar("avtohud_enabled"):GetBool() then return end

    local me = LocalPlayer()
    local w = ScrW()

    local entCount = me:GetNWInt("SUI::HoloCount", 0) + me:GetNWInt("SUI::EntCount") + me:GetCount("props")
    local constraintCount = me:GetNWInt("SUI::ConstraintCount")

    --TODO: Move entity and constraint count calculations out of scoreboard and into a dedicated script
    draw.TextShadow({
        text = "Health: " .. me:Health() .. " l " ..
        (me:Armor() > 0 and ("Armor: " .. me:Armor() .. " l ") or "") ..
        "Entities: " .. entCount .. " l " ..
        "Constraints: " .. constraintCount
    , font = "AvtoHud", pos = {3, 11}, color = textColor, xalign = TEXT_ALIGN_LEFT, yalign = TEXT_ALIGN_CENTER}, 1, 255)

    local vel = me:InVehicle() and pushGetAvg(velAvg, 30, rootParent(me:GetVehicle()):GetVelocity():Length()) or me:GetVelocity():Length()
    local unit = GetConVar("avtohud_unit"):GetString()

    draw.TextShadow({
        text = "Velocity: " .. math.Round(vel / units[unit]) .. " " .. unit
    , font = "AvtoHud", pos = {w / 2, 11}, color = textColor, xalign = TEXT_ALIGN_CENTER, yalign = TEXT_ALIGN_CENTER}, 1, 255)

    local time = string.FormattedTime(CurTime())
    draw.TextShadow({
        text = "FPS: " .. math.Round(pushGetAvg(fpsAvg, 30, 1 / FrameTime())) .. " l " ..
        ((ScrW() > 1300 and "Server Uptime: " .. string.format("%02i:%02i:%02i", time.h, time.m, time.s) .. " l ") or "") ..
        "Local Time: " .. os.date("%H:%M:%S")
    , font = "AvtoHud", pos = {w - 3, 11}, color = textColor, xalign = TEXT_ALIGN_RIGHT, yalign = TEXT_ALIGN_CENTER}, 1, 255)
end)

hook.Add("HUDShouldDraw", "AvtoHud_HideDefault", function(name)
    if not GetConVar("avtohud_enabled"):GetBool() then return end

    for _, v in pairs({"CHudHealth", "CHudBattery"}) do
        if name == v then return false end
    end
end)