--AdvancedOpenGL
local replicated = game:GetService("ReplicatedStorage")
local spawnPlayer = replicated:WaitForChild("requestCharacter")
local player = game.Players.LocalPlayer
local chat = game:GetService("TextChatService")
return function()
    chat.MessageReceived:Connect(function(msg)
        if msg.TextSource and msg.TextSource.UserId == player.UserId then
            local msg = msg.Text
            if msg == ";die" then
                if player.Character then
                    player.Character.Humanoid.Health = 0
                end
            elseif msg == ";respawn" then
                spawnPlayer:InvokeServer()
            end
        end
    end)
end