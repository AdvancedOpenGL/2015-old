--Made by AdvancedOpenGL
local frame = script.Parent.Parent.symlink.Value.ControlFrame.TopLeftControl
local GuiService = game:GetService("GuiService")
local inset = GuiService.TopbarInset
frame.Position = UDim2.new(0, inset.Min.X, 0, 0)
GuiService:GetPropertyChangedSignal("TopbarInset"):Connect(function()
	inset = GuiService.TopbarInset
	frame.Position = UDim2.new(0, inset.Min.X, 0, 0)
end)


return ""