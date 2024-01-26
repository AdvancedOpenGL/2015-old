-- Derived from code under the Mozilla Public License 2.0
-- https://github.com/MaximumADHD/Super-Nostalgia-Zone/blob/main/LICENSE

-- Modified from https://github.com/MaximumADHD/Super-Nostalgia-Zone/blob/main/Client/Sky/init.client.lua
local Lighting = game:GetService("Lighting")
local toneMap = Instance.new("ColorCorrectionEffect")
toneMap.TintColor = Color3.new(1.25, 1.25, 1.25)
toneMap.Name = "LegacyToneMap"
toneMap.Brightness = 0.03
toneMap.Saturation = 0.07
toneMap.Contrast = -0.15
toneMap.Parent = Lighting

game:GetService("RunService").RenderStepped:Connect(function()
	local sunDir = Lighting:GetSunDirection()
	local globalLight = math.clamp((sunDir.Y + .033) * 10, 0, 1)

	toneMap.Contrast = -0.15 * globalLight
	toneMap.Saturation = 0.07 * globalLight

	local black = Color3.new()
	Lighting.GlobalShadows = true
	Lighting.Ambient = black:Lerp(Lighting.OutdoorAmbient, 0.5)
end)

return ""
