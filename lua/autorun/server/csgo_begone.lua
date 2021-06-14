--Keep cancerous trade sites out of here

local aids = {
	"hellcase",
	"csgoroll",
	"gift-drop",
	"csgogem",
	"cs%.money",
	"wildcase",
	"farmskins",
	"trade%.tf",
	"hypedrop",
	"opskin",
	"csgo%-skin",
	"gamdom",
	"%.gg",
	"%.tf",
	"%.deals",
	"%.trade",
	"pvpro",
	"skinhub",
	"%(%.%)gg",
	"%(%.%) gg",
	"%. gg",
	"%. g g",
	"%.g g",
	"dot gg",
	"dotgg",
	"twitch%.tv",
	"casedrop%.eu",
	"rustchance",
	"rustypot",
	"key-drop"
}

hook.Add("CheckPassword", "CancerRemover", function(_, _, _, _, name)
	for _, ad in pairs(aids) do
		if string.match(string.lower(name), ad) then
			return false, "Please remove " .. ad .. " from your name before joining."
		end
	end
end)