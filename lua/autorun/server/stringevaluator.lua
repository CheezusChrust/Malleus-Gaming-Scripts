--Evaluates a mathematical expression with !eval and prints the answer in chat
--Requires basicmessaging.lua

local function isStringSafe(str)
    return not string.match(str, "[^%d%(%)%^%/%*%+%-%%%.%s]")
end

local function eval(str)
    if not isStringSafe(str) then return "Invalid expression" end

    local result = CompileString("return " .. str, "String Evaluator", false)

    if isfunction(result) then
        return result()
    else
        return "Invalid expression"
    end
end

hook.Add("PlayerSay", "StringEvaluator", function(_, text)
    if string.sub(text, 1, 5) ~= "!eval" then return end

    timer.Simple(0.1, function()
        BroadcastMsg(Color(100, 255, 100), "Result: ", Color(255, 255, 255), tostring(eval(string.sub(text, 7, #text))))
    end)
end)