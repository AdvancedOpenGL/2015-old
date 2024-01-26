--Made by AdvancedOpenGL
pcall(function()
	if game:GetService("RunService"):IsStudio() then
		game:GetService("Players").LocalPlayer:WaitForChild("PlayerScripts"):Destroy()
	end
end)
game.ReplicatedFirst:RemoveDefaultLoadingScreen()
local StarterGui = game:GetService("StarterGui")
local finished
while not finished do
	finished, x = pcall(StarterGui.SetCoreGuiEnabled,StarterGui,Enum.CoreGuiType.All,false)
	task.wait()
end
local preloadService = game:GetService("ContentProvider")
--Creating Guis
local mainGui = Instance.new("ScreenGui")
local loadingFrame
mainGui.DisplayOrder = 999
mainGui.ResetOnSpawn = false
mainGui.IgnoreGuiInset = true
mainGui.Parent = game.Players.LocalPlayer.PlayerGui
function createLoadingScreen()
	local loadingFrame = Instance.new("Frame")
	loadingFrame.ZIndex = 1000
	loadingFrame.Size = UDim2.new(1,0,1,0)
	loadingFrame.BackgroundColor3 = Color3.fromRGB(math.random(1,255),math.random(1,255),math.random(1,255))
	loadingFrame.Name = "loadingFrame"
	loadingFrame.Parent = mainGui
	local textFrame = Instance.new("Frame")
	textFrame.Position = UDim2.new(0.3,0,0.3,0)
	textFrame.ZIndex = 1999
	textFrame.Style = Enum.FrameStyle.DropShadow
	textFrame.Size = UDim2.new(0.4,0,0.4,0)
	textFrame.Parent = mainGui
	local textLabel = Instance.new("TextLabel")
	textLabel.Text = ""
	textLabel.ZIndex = 2000
	textLabel.Font = Enum.Font.SourceSansItalic
	textLabel.Size = UDim2.new(1,0,1,0)
	textLabel.TextSize = 20
	textLabel.TextColor3 = Color3.new(1,1,1)
	textLabel.BackgroundTransparency = 1
	textLabel.Parent = textFrame
	return function(visible, text, mainVisible)
		loadingFrame.Visible = visible
		if text then
			textLabel.Text = text
		end
		if mainVisible ~= nil then
			textFrame.Visible = mainVisible
		end
	end
end
local loadScreen = createLoadingScreen()
loadScreen(true,"Waiting for game to load")
if not game:IsLoaded() then
	game.Loaded:Wait()
end
local client = require(game.ReplicatedStorage:WaitForChild("ClassicClient"))
loadScreen(false,"Setting up client")
client:startClient()

loadScreen(false,"Getting game data")
client:loadClientAssets(loadScreen)

loadScreen(false,"Requesting character...")
client:requestCharacter()
mainGui:Destroy()