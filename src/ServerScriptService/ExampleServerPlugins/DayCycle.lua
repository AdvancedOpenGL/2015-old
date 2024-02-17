return function()
	local Lighting = game:GetService("Lighting")
	while true do
		Lighting.ClockTime += 1/60
		task.wait(5/60)
	end
end