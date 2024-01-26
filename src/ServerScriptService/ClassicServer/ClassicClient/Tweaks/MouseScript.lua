--Made by AdvancedOpenGL
local uis = game:GetService("UserInputService")
if game:GetService("RunService"):IsStudio() and not (uis.MouseEnabled and uis.TouchEnabled) and false then
	local mouseIcon = Instance.new("ImageLabel",script.Parent.Parent.symlink.Value)
	local mouse = game.Players.LocalPlayer:GetMouse()
	mouseIcon.Image = "rbxassetid://16072047154"
	mouseIcon.Name = "Mouse"
	mouseIcon.BackgroundTransparency = 1
	mouseIcon.Size = UDim2.fromOffset(64,64)
	mouseIcon.ZIndex = 99999
	local uis = game:GetService("UserInputService")
	local lastMouseIcon = uis.MouseIcon
	game:GetService("RunService").RenderStepped:Connect(function()
		mouseIcon.Position = UDim2.fromOffset(mouse.X-33,mouse.Y+26)
		if mouseIcon ~= lastMouseIcon then
			if mouse.Icon ~= "" or uis.MouseIcon ~= "" then
				mouseIcon.Visible = false
				uis.MouseIconEnabled = true
			else
				uis.MouseIconEnabled = false
				mouseIcon.Visible = true
			end
			lastMouseIcon = uis.MouseIcon
		end
	end)
end


return ""