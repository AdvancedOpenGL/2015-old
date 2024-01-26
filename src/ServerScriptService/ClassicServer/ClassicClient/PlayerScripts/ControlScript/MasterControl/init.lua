--[[
	// FileName: MasterControl
	// Version 1.0
	// Written by: jeditkacheff
	// Description: All character control scripts go thru this script, this script makes sure all actions are performed
--]]

--[[ Local Variables ]]--
local MasterControl = {}

local Players = game:GetService('Players')
local RunService = game:GetService('RunService')

while not Players.LocalPlayer do
	wait()
end
local LocalPlayer = Players.LocalPlayer
local CachedHumanoid = nil
local RenderSteppedCon = nil
local moveFunc = LocalPlayer.Move

local isJumping = false
local moveValue = Vector3.new(0,0,0)


--[[ Local Functions ]]--
local function getHumanoid()
	local character = LocalPlayer and LocalPlayer.Character
	if character then
		if CachedHumanoid and CachedHumanoid.Parent == character then
			return CachedHumanoid
		else
			CachedHumanoid = nil
			for _,child in pairs(character:GetChildren()) do
				if child:IsA('Humanoid') then
					CachedHumanoid = child
					return CachedHumanoid
				end
			end
		end
	end
end



--[[ Public API ]]--
function MasterControl:Init()
	if RenderSteppedCon then return end
	
	RenderSteppedCon = RunService.RenderStepped:connect(function()
		if LocalPlayer and LocalPlayer.Character then
			local humanoid = getHumanoid()
			if not humanoid then return end
			
			if humanoid and not humanoid.PlatformStand and isJumping then
				humanoid.Jump = isJumping
				isJumping = false
			end
			if humanoid and humanoid.SeatPart and humanoid.SeatPart:IsA("VehicleSeat") then
				humanoid.SeatPart.Throttle = -moveValue.Z
				humanoid.SeatPart.Steer = moveValue.X
			end
			-- support games that have a scripted camera
			local isCameraRelative = game.Workspace.CurrentCamera.CameraType ~= Enum.CameraType.Scriptable
			moveFunc(LocalPlayer, moveValue, isCameraRelative)
		end
	end)
end

function MasterControl:Disable()
	if RenderSteppedCon then
		RenderSteppedCon:disconnect()
		RenderSteppedCon = nil
		
		moveValue = Vector3.new(0,0,0)
		isJumping = false
	end
end

function MasterControl:AddToPlayerMovement(playerMoveVector)
	moveValue = Vector3.new(moveValue.X + playerMoveVector.X, moveValue.Y + playerMoveVector.Y, moveValue.Z + playerMoveVector.Z)
	
end

function MasterControl:RequestJump()
	isJumping = true
end

return MasterControl
