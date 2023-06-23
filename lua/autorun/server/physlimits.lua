hook.Add("InitPostEntity", "PhysLimits::Init", function()
    local tbl = physenv.GetPerformanceSettings()
        tbl.MaxAngularVelocity = 48000
        tbl.MaxVelocity = 13200
    physenv.SetPerformanceSettings(tbl)
end)