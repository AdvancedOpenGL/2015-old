local players = game:GetService("Players")
local badgeService = game:GetService("BadgeService")
return function()
	players.PlayerAdded:Connect(function(player)
        pcall(badgeService.AwardBadge,badgeService,player.UserId,1864786770307152)
    end)
end