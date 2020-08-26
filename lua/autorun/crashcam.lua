--A basic spectator camera for when the server crashes

if SERVER then
    util.AddNetworkString("CrashCam::SendPing")

    timer.Create("CrashCam::Ping", 1, 0, function()
        net.Start("CrashCam::SendPing")
        net.Send(player.GetAll())
    end)
else
    local lastPingTime = SysTime()
    local fspeed = 0 --Forward speed
    local sspeed = 0 --Sideways speed
    local uspeed = 0 --Vertical speed
    local lastTime = SysTime()
    local offset = Vector()

    hook.Add("InitPostEntity", "CrashCam::Init", function()
        MsgC(Color(255, 0, 0), "CrashCam Initialized\n")
        lastPingTime = SysTime()
    end)

    net.Receive("CrashCam::SendPing", function()
        lastPingTime = SysTime()
        offset = Vector()
    end)

    local function keyDown(key)
        return input.IsKeyDown(key) and 1 or 0
    end

    hook.Add("CalcView", "CrashCam::CalcView", function(_, pos, angles, fov)
        if (SysTime() - lastPingTime) > 4 then
            local dT = (SysTime() - lastTime) * 150
            local w, s, a, d, up = KEY_W, KEY_S, KEY_A, KEY_D, KEY_SPACE
            fspeed = math.Approach(fspeed, keyDown(w) - keyDown(s), 0.05 * dT)
            sspeed = math.Approach(sspeed, keyDown(d) - keyDown(a), 0.05 * dT)
            uspeed = math.Approach(uspeed, keyDown(up), 0.05 * dT)
            offset = offset + (angles:Forward() * fspeed + angles:Right() * sspeed + angles:Up() * uspeed) * (1 - keyDown(KEY_LCONTROL) / 1.5) * (keyDown(KEY_LSHIFT) + 1) * 5 * dT
            lastTime = SysTime()

            local view = {
                origin = pos + offset,
                angles = angles,
                fov = fov,
                drawviewer = true
            }

            return view
        end

        lastTime = SysTime()
    end)

    hook.Add("HUDPaint", "CrashCam::HUD", function()
        local t = SysTime() - lastPingTime

        if t > 4 then
            local w = ScrW()
            surface.SetDrawColor(Color(0, 0, 0, 200))
            surface.DrawRect(0, 0, w, 32)
            draw.SimpleTextOutlined("Lost connection to server, freecam enabled (no data for " .. string.format("%.1f", math.Round(t, 1)) .. "s)", "DermaLarge", 0, 0, Color(255, 0, 0), 0, 0, 1, Color(0, 0, 0))
        end
    end)
end