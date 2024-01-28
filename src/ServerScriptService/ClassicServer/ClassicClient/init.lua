local replicated = game:GetService("ReplicatedStorage")
local spawnPlayer = replicated:WaitForChild("requestCharacter")
local players = game:GetService("Players")
local localplayer = players.LocalPlayer

local module = {}

local function respawn(isAlive)
	if not isAlive then
		wait(players.RespawnTime)
	end
	spawnPlayer:InvokeServer()
	while not localplayer.Character do
		task.wait()
	end
	localplayer.Character:WaitForChild("Humanoid").Died:Connect(respawn)
end
function module:requestCharacter()
	respawn(true)
end
function module:loadClientAssets(status)
	local gameData = replicated:WaitForChild("getGameData"):InvokeServer()
	local success,response = pcall(function()
		local gameData = replicated:WaitForChild("getGameData"):InvokeServer()
		local assetLoad = 0
		status(true,"Preloading required assets")
		game:GetService("ContentProvider"):PreloadAsync(gameData,function(...)
			assetLoad+=1
			status(true,"Preloading required assets ("..assetLoad.." out of "..#gameData..")")
		end)
	end)
	if not success then
		status(false,response)
		warn(response)
		return response
	end
	return
end

--some setup functions
local function createValues()
	local CoreGuiEnabled = Instance.new("Folder",replicated)
	CoreGuiEnabled.Name = "CoreGuiEnabled"

	local coregui_backpack = Instance.new("BoolValue",CoreGuiEnabled)
	coregui_backpack.Value = true
	coregui_backpack.Name = "backpack"

	local coregui_chat = Instance.new("BoolValue",CoreGuiEnabled)
	coregui_chat.Value = true
	coregui_chat.Name = "chat"
	local bubblechat = Instance.new("BoolValue",CoreGuiEnabled)
	bubblechat.Value = true
	bubblechat.Name = "bubblechat"

	local coregui_health = Instance.new("BoolValue",CoreGuiEnabled)
	coregui_health.Value = true
	coregui_health.Name = "health"

	local coregui_playerlist = Instance.new("BoolValue",CoreGuiEnabled)
	coregui_playerlist.Value = true
	coregui_playerlist.Name = "playerlist"

	local shiftlock = Instance.new("BoolValue",replicated)
	shiftlock.Value = true
	shiftlock.Name = "shiftlock"
end
local function createContainer()
	local CoreGui = Instance.new("ScreenGui",localplayer.PlayerGui)
	CoreGui.Name = "CoreGui"
	CoreGui.ResetOnSpawn = false
	CoreGui.DisplayOrder = 76782567826
	CoreGui.IgnoreGuiInset = true

	local RobloxGui = Instance.new("Frame",CoreGui)
	RobloxGui.Name = "RobloxGui"
	RobloxGui.Size = UDim2.fromScale(1,1)
	RobloxGui.BackgroundTransparency = 1

	local ControlFrame = Instance.new("Frame",RobloxGui)
	ControlFrame.Name = "ControlFrame"
	ControlFrame.Size = UDim2.fromScale(1,1)
	ControlFrame.BackgroundTransparency = 1

	local TopLeftControl = Instance.new("Frame",ControlFrame)
	TopLeftControl.Name = "TopLeftControl"
	TopLeftControl.Size = UDim2.fromOffset(130,46)
	TopLeftControl.BackgroundTransparency = 1

	local BottomLeftControl = Instance.new("Frame",ControlFrame)
	BottomLeftControl.Name = "BottomLeftControl"
	BottomLeftControl.Size = UDim2.fromOffset(130,46)
	BottomLeftControl.BackgroundTransparency = 1
	BottomLeftControl.Position = UDim2.new(0, 0, 1, -46)

	local symlink = Instance.new("ObjectValue",script)
	symlink.Name = "symlink"
	symlink.Value = RobloxGui
end

function module:startClient()

	createContainer()
	createValues()
	for i,v in pairs(script.Tweaks:GetChildren()) do
		task.spawn(require,v)
	end
	for i,v in pairs(script.CoreGui:GetChildren()) do
		task.spawn(require,v)
	end
	for i,v in pairs(script.PlayerScripts:GetChildren()) do
		task.spawn(require,v)
	end
	for i,v in pairs(replicated:WaitForChild("ClientPlugins"):GetChildren()) do
		task.spawn(require(v))
	end
end

return module
