--Made by AdvancedOpenGL
local replicated = game.ReplicatedStorage
script.ClassicClient.Parent = replicated

local calledGui = {}

--create remotes
local gameData = Instance.new("RemoteFunction",replicated)
local character = Instance.new("RemoteFunction",replicated)
---------
local preloadData = {
	--Base Assets
	"rbxassetid://10584651299",
	"rbxassetid://10584659375",
	"rbxassetid://34854607",
	"rbxassetid://45915798",
	"rbxassetid://54071825",
	"rbxassetid://45915811",
	"rbxassetid://45917596",
	"rbxassetid://45915825",
	"rbxassetid://16072047238",
	"rbxassetid://16072047154",
	"rbxassetid://16080947161",
	"rbxassetid://16080946662",
	"rbxassetid://16080946863",
	"rbxassetid://16080947019",
	"rbxassetid://16080947285",
	"rbxassetid://16080965955",
	"rbxassetid://16080965800",
	"rbxassetid://16080966080",
	"rbxassetid://16081009921",
	"rbxassetid://16081010097",
	"rbxassetid://16081010326",
	"rbxassetid://16081010554",
	"rbxassetid://16081010723",
	"rbxassetid://16081010874",
	"rbxassetid://16081011012",
	"rbxassetid://16081053972",
	"rbxassetid://16081076383",
	"rbxassetid://16081079772",
	"rbxassetid://16081080023",
	"rbxassetid://16081130701",
	"rbxassetid://16081130915",
	"rbxassetid://16081131049",
	"rbxassetid://16081139134",
	"rbxassetid://16081139292",
}
gameData.OnServerInvoke = function(p)
	return preloadData
end
character.OnServerInvoke = function(p)
	if p.Character then
		p.Character:Destroy()
		p.Character = nil
	end
	p:LoadCharacter()
	while not p.Character do
		task.wait()
	end
	p.Character.Humanoid.HealthDisplayType = Enum.HumanoidHealthDisplayType.AlwaysOn
end
character.Name = "requestCharacter"
gameData.Name = "getGameData"

if game.ServerScriptService:FindFirstChild("ServerPlugins") then
	for i,v in pairs(game.ServerScriptService.ServerPlugins:GetChildren()) do
		task.spawn(require(v))
	end
end
for i,v in pairs(game.ServerScriptService.ServerPlugins:GetChildren()) do
	task.spawn(require(v))
end