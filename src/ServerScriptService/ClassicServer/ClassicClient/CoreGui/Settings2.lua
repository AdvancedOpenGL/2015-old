--[[
		Filename: SettingNewControlsOnly.lua
		Written by: jmargh
		Description: Implements the in game settings menu with the new control schemes

		TODO:
			Remove SendNotification calls when notificaion script is updated.
--]]

--[[ Services ]]--
local CoreGui = game:GetService('CoreGui')
local GuiService = game:GetService('GuiService')
local Players = game:GetService('Players')
local UserInputService = game:GetService('UserInputService')
local ContextActionService = game:GetService('ContextActionService')
--
local Settings = UserSettings()
local GameSettings = Settings.GameSettings
local RbxGuiLibaray = _G.LoadLibrary(RbxGui)


--[[ Script Variables ]]--
while not Players.LocalPlayer do
	wait()
end
local LocalPlayer = Players.LocalPlayer
local RobloxGui = script.Parent.Parent.symlink.Value

--[[ Client Settings ]]--
local IsMacClient = false
local isMacSuccess, isMac = pcall(function() return not GuiService.IsWindows end)
IsMacClient = isMacSuccess and isMac

local IsTouchClient = false
local isTouchSuccess, isTouch = pcall(function() return UserInputService.TouchEnabled end)
IsTouchClient = isTouchSuccess and isTouch

local IsStudioMode = false

--[[ Fast Flags ]]--
local isNewNotificationSuccess, isNewNotificationEnabled = pcall(function() return settings():GetFFlag("NewNotificationsScript") end)
local isNewNotifications = isNewNotificationSuccess and isNewNotificationEnabled

--[[ Parent Frames ]]--
-- TODO: Remove all references to engine created gui
local ControlFrame = RobloxGui:WaitForChild('ControlFrame')
local TopLeftControl = ControlFrame:WaitForChild('TopLeftControl')		
local BottomLeftControl = ControlFrame:WaitForChild('BottomLeftControl')

--[[ Control Variables ]]--
local CurrentYOffset = 24
local IsShiftLockEnabled = LocalPlayer.DevEnableMouseLock and GameSettings.ControlMode == Enum.ControlMode.MouseLockSwitch
game.ReplicatedStorage.shiftlock.Value = IsShiftLockEnabled
local IsResumingGame = false
-- TODO: Change dev console script to parent this to somewhere other than an engine created gui
local MenuStack = {}
local IsHelpMenuOpen = false
local CurrentOpenedDropDownMenu = nil
local IsMenuClosing = false
local IsRecordingVideo = false
local IsSmallScreen = workspace.CurrentCamera.ViewportSize.Y <= 500

--[[ Debug Variables - PLEASE RESET BEFORE COMMIT ]]--
local isTestingReportAbuse = false

--[[ Constants ]]--
local GRAPHICS_QUALITY_LEVELS = 10
local BASE_Z_INDEX = 4
local BG_TRANSPARENCY = 0.4
local TWEEN_TIME = 0.2
local SHOW_MENU_POS = IsSmallScreen and UDim2.new(0, 0, 0, 0) or UDim2.new(0.5, -262, 0.5, -215)
local CLOSE_MENU_POS = IsSmallScreen and UDim2.new(0, 0, -1, 0) or UDim2.new(0.5, -262, -0.5, -215)
local CAMERA_MODE_DEFAULT_STRING = IsTouchClient and "Default (Follow)" or "Default (Classic)"
local MOVEMENT_MODE_DEFAULT_STRING = IsTouchClient and "Default (Thumbstick)" or "Default (Keyboard)"
local MENU_BTN_LRG = UDim2.new(0, 340, 0, 50)
local MENU_BTN_SML = UDim2.new(0, 168, 0, 50)
local STOP_RECORD_IMG = 'rbxasset://textures/ui/RecordStop.png'
local HELP_IMG = {
	CLASSIC_MOVE = 'http://www.roblox.com/Asset?id=45915798',
	SHIFT_LOCK = 'http://www.roblox.com/asset?id=54071825',
	MOVEMENT = 'http://www.roblox.com/Asset?id=45915811',
	GEAR = 'http://www.roblox.com/Asset?id=45917596',
	ZOOM = 'http://www.roblox.com/Asset?id=45915825'
}

local PC_CHANGED_PROPS = {
	DevComputerMovementMode = true,
	DevComputerCameraMode = true,
	DevEnableMouseLock = true,
}
local TOUCH_CHANGED_PROPS = {
	DevTouchMovementMode = true,
	DevTouchCameraMode = true,
}

local GRAPHICS_QUALITY_TO_INT = {
	["Enum.SavedQualitySetting.Automatic"] = 0,
	["Enum.SavedQualitySetting.QualityLevel1"] = 1,
	["Enum.SavedQualitySetting.QualityLevel2"] = 2,
	["Enum.SavedQualitySetting.QualityLevel3"] = 3,
	["Enum.SavedQualitySetting.QualityLevel4"] = 4,
	["Enum.SavedQualitySetting.QualityLevel5"] = 5,
	["Enum.SavedQualitySetting.QualityLevel6"] = 6,
	["Enum.SavedQualitySetting.QualityLevel7"] = 7,
	["Enum.SavedQualitySetting.QualityLevel8"] = 8,
	["Enum.SavedQualitySetting.QualityLevel9"] = 9,
	["Enum.SavedQualitySetting.QualityLevel10"] = 10,
}

local ABUSE_TYPES_PLAYER = {
	"Swearing",
	"Inapproiate Username",
	"Bullying",
	"Scamming",
	"Dating",
	"Cheating/Exploiting",
	"Personal Question",
	"Offsite Links",
}

local ABUSE_TYPES_GAME = {
	"Inapproiate Content",
	"Bad Model or Script",
	"Offsite Link",
}

--[[ Gui Creation Helper Functions ]]--
local function createTextButton(size, position, text, fontSize, style)
	local textButton = Instance.new('TextButton')
	textButton.Size = size
	textButton.Position = position
	textButton.Font = Enum.Font.SourceSansBold
	textButton.FontSize = fontSize
	textButton.Style = style
	textButton.TextColor3 = Color3.new(1, 1, 1)
	textButton.Text = text
	textButton.ZIndex = BASE_Z_INDEX + 4

	return textButton
end

local function createTextLabel(position, text, name)
	local textLabel = Instance.new('TextLabel')
	textLabel.Name = name
	textLabel.Size = UDim2.new(0, 0, 0, 0)
	textLabel.Position = position
	textLabel.BackgroundTransparency = 1
	textLabel.Font = Enum.Font.SourceSansBold
	textLabel.FontSize = Enum.FontSize.Size18
	textLabel.TextColor3 = Color3.new(1, 1, 1)
	textLabel.TextXAlignment = Enum.TextXAlignment.Right
	textLabel.ZIndex = BASE_Z_INDEX + 4
	textLabel.Text = text

	return textLabel
end

local function createMenuFrame(name, position)
	local frame = Instance.new('Frame')
	frame.Name = name
	frame.Size = UDim2.new(1, 0, 1, 0)
	frame.Position = position
	frame.BackgroundTransparency = 1
	frame.ZIndex = BASE_Z_INDEX + 4

	return frame
end

local function createMenuTitleLabel(name, text, yOffset)
	local label = Instance.new('TextLabel')
	label.Name = name
	label.Size = UDim2.new(0, 0, 0, 0)
	label.Position = UDim2.new(0.5, 0, 0, yOffset)
	label.BackgroundTransparency = 1
	label.Font = Enum.Font.SourceSansBold
	label.FontSize = Enum.FontSize.Size36
	label.TextColor3 = Color3.new(1, 1, 1, 1)
	label.ZIndex = BASE_Z_INDEX + 4
	label.Text = text

	return label
end

local function closeCurrentDropDownMenu()
	if CurrentOpenedDropDownMenu then
		CurrentOpenedDropDownMenu.Close()
	end
	CurrentOpenedDropDownMenu = nil
end

--[[ Gui Creation ]]--
-- Main Container for everything in the settings menu
local SettingsMenuFrame = Instance.new('Frame')
SettingsMenuFrame.Name = "SettingsMenu"
SettingsMenuFrame.ZIndex = 100
SettingsMenuFrame.Size = UDim2.new(1, 0, 1, 0)
SettingsMenuFrame.BackgroundTransparency = 1

local SettingsButton = Instance.new('ImageButton')
SettingsButton.Name = "SettingsButton"
SettingsButton.Size = UDim2.new(0, 36, 0, 28)
SettingsButton.Position = IsTouchClient and UDim2.new(0, 2, 0, 5) or UDim2.new(0, 15, 1, -42)
SettingsButton.BackgroundTransparency = 1
SettingsButton.Image = 'rbxassetid://16081076383'--'rbxasset://textures/ui/homeButton.png'
SettingsButton.Parent = SettingsMenuFrame

local SettingsShield = Instance.new('Frame')
SettingsShield.Name = "SettingsShield"
SettingsShield.Size = UDim2.new(1, 0, 1, 0)
SettingsShield.BackgroundTransparency = BG_TRANSPARENCY
SettingsShield.BackgroundColor3 = Color3.new(51/255, 51/255, 51/255)
SettingsShield.BorderColor3 = Color3.new(27/255, 42/255, 53/255)
SettingsShield.Active = false
SettingsShield.Visible = false
SettingsShield.ZIndex = BASE_Z_INDEX + 2

	local SettingClipFrame = Instance.new('Frame')
	SettingClipFrame.Name = "SettingClipFrame"
	SettingClipFrame.Size = IsSmallScreen and UDim2.new(1, 0, 1, 0) or UDim2.new(0, 525, 0, 430)--IsTouchClient and UDim2.new(0, 500, 0, 340) or UDim2.new(0, 500, 0, 430)
	SettingClipFrame.Position = CLOSE_MENU_POS
	SettingClipFrame.Active = true
	SettingClipFrame.BackgroundTransparency = BG_TRANSPARENCY
	SettingClipFrame.BackgroundColor3 = Color3.new(51/255, 51/255, 51/255)
	SettingClipFrame.BorderSizePixel = 0
	SettingClipFrame.ZIndex = BASE_Z_INDEX + 3
	SettingClipFrame.ClipsDescendants = true
	SettingClipFrame.Parent = SettingsShield

--[[ Root Settings Menu ]]--
	CurrentYOffset = 24
	local RootMenuFrame = createMenuFrame("RootMenuFrame", UDim2.new(0, 0, 0, 0))
	RootMenuFrame.Parent = SettingClipFrame

		local RootMenuTitle = createMenuTitleLabel("RootMenuTitle", "Game Menu", CurrentYOffset)
		RootMenuTitle.Parent = RootMenuFrame
		CurrentYOffset = CurrentYOffset + 32

		local ResumeGameButton = createTextButton(MENU_BTN_LRG, UDim2.new(0.5, -170, 0, CurrentYOffset),
			"Resume Game", Enum.FontSize.Size24, Enum.ButtonStyle.RobloxRoundDefaultButton)
		ResumeGameButton.Name = "ResumeGameButton"
		ResumeGameButton.Modal = true
		ResumeGameButton.Parent = RootMenuFrame
		CurrentYOffset = CurrentYOffset + 51

		local ResetCharacterButton = createTextButton(MENU_BTN_LRG, UDim2.new(0.5, -170, 0, CurrentYOffset),
			"Reset Character", Enum.FontSize.Size24, Enum.ButtonStyle.RobloxRoundButton)
		ResetCharacterButton.Name = "ResetCharacterButton"
		ResetCharacterButton.Parent = RootMenuFrame
		CurrentYOffset = CurrentYOffset + 51

		local GameSettingsButton = createTextButton(MENU_BTN_LRG, UDim2.new(0.5, -170, 0, CurrentYOffset),
			"Game Settings", Enum.FontSize.Size24, Enum.ButtonStyle.RobloxRoundButton)
		GameSettingsButton.Name = "GameSettingsButton"
		GameSettingsButton.Parent = RootMenuFrame
		CurrentYOffset = CurrentYOffset + 51

		local HelpButton = nil
		if not IsTouchClient then
			HelpButton = createTextButton(MENU_BTN_SML, UDim2.new(0.5, -170, 0, CurrentYOffset),
				"Help", Enum.FontSize.Size24, Enum.ButtonStyle.RobloxRoundButton)
			HelpButton.Name = "HelpButton"
			if IsMacClient then HelpButton.Size = MENU_BTN_LRG end
			HelpButton.Parent = RootMenuFrame
		end

		local ScreenshotButton = nil
		if not IsMacClient and not IsTouchClient then
			ScreenshotButton = createTextButton(MENU_BTN_SML, UDim2.new(0.5, 2, 0, CurrentYOffset),
				"Screenshot", Enum.FontSize.Size24, Enum.ButtonStyle.RobloxRoundButton)
			ScreenshotButton.Name = "ScreenshotButton"
			ScreenshotButton.Parent = RootMenuFrame
		end
		if not IsTouchClient then CurrentYOffset = CurrentYOffset + 51 end

		local ReportAbuseButton = createTextButton(MENU_BTN_SML, UDim2.new(0.5, -170, 0, CurrentYOffset),
			"Report Abuse", Enum.FontSize.Size24, Enum.ButtonStyle.RobloxRoundButton)
		ReportAbuseButton.Name = "ReportAbuseButton"
		ReportAbuseButton.Parent = RootMenuFrame
		if IsMacClient or IsTouchClient then
			ReportAbuseButton.Size = MENU_BTN_LRG
		end
		ReportAbuseButton.Visible = game:FindService('NetworkClient')
		if isTestingReportAbuse then
			ReportAbuseButton.Visible = true
		end
		if not ReportAbuseButton.Visible then
			game.ChildAdded:Connect(function(child)
				if child:IsA('NetworkClient') then
					ReportAbuseButton.Visible = game:FindService('NetworkClient')
				end
			end)
		end

		local RecordVideoButton = nil
		local StopRecordingVideoButton = nil
		CurrentYOffset = CurrentYOffset + 51

		local LeaveGameButton = createTextButton(MENU_BTN_LRG, UDim2.new(0.5, -170, 0, CurrentYOffset),
			"Leave Game", Enum.FontSize.Size24, Enum.ButtonStyle.RobloxRoundButton)
		LeaveGameButton.Name = "LeaveGameButton"
		LeaveGameButton.Parent = RootMenuFrame

--[[ Reset Character Confirmation Menu ]]--
	CurrentYOffset = IsSmallScreen and 70 or 140
	local ResetCharacterFrame = createMenuFrame("ResetCharacterFrame", UDim2.new(1, 0, 0, 0))
	ResetCharacterFrame.Parent = SettingClipFrame

		local ResetCharacterText = Instance.new('TextLabel')
		ResetCharacterText.Name = "ResetCharacterText"
		ResetCharacterText.Size = UDim2.new(1, 0, 0, 80)
		ResetCharacterText.Position = UDim2.new(0, 0, 0, CurrentYOffset)
		ResetCharacterText.BackgroundTransparency = 1
		ResetCharacterText.Font = Enum.Font.SourceSansBold
		ResetCharacterText.FontSize = Enum.FontSize.Size36
		ResetCharacterText.TextColor3 = Color3.new(1, 1, 1)
		ResetCharacterText.TextWrap = true
		ResetCharacterText.ZIndex = BASE_Z_INDEX + 4
		ResetCharacterText.Text = "Are you sure you want to reset\nyour character?"
		ResetCharacterText.Parent = ResetCharacterFrame
		CurrentYOffset = CurrentYOffset + 90

		local ResetCharacterToolTipText = createTextLabel(UDim2.new(0.5, 0, 0, CurrentYOffset), "You will return to the spawn point", "ResetCharacterToolTipText")
		ResetCharacterToolTipText.TextXAlignment = Enum.TextXAlignment.Center
		ResetCharacterToolTipText.Parent = ResetCharacterFrame
		CurrentYOffset = CurrentYOffset + 32

		local ConfirmResetButton = createTextButton(MENU_BTN_SML, UDim2.new(0.5, 2, 0, CurrentYOffset),
			"Confirm", Enum.FontSize.Size24, Enum.ButtonStyle.RobloxRoundDefaultButton)
		ConfirmResetButton.Name = "ConfirmResetButton"
		ConfirmResetButton.Parent = ResetCharacterFrame

		local CancelResetButton = createTextButton(MENU_BTN_SML, UDim2.new(0.5, -170, 0, CurrentYOffset),
			"Cancel", Enum.FontSize.Size24, Enum.ButtonStyle.RobloxRoundButton)
		CancelResetButton.Name = "CancelResetButton"
		CancelResetButton.Parent = ResetCharacterFrame

--[[ Game Settings Menu ]]--
	CurrentYOffset = 24
	local GameSettingsMenuFrame = createMenuFrame("GameSettingsMenuFrame", UDim2.new(1, 0, 0, 0))
	GameSettingsMenuFrame.Parent = SettingClipFrame

		local GameSettingsMenuTitle = createMenuTitleLabel("GameSettingsMenuTitle", "Settings", CurrentYOffset)
		GameSettingsMenuTitle.Parent = GameSettingsMenuFrame
		CurrentYOffset = CurrentYOffset + 32
		if IsTouchClient then CurrentYOffset = CurrentYOffset + 10 end

		-- Shift Lock Controls
		local ShiftLockText, ShiftLockCheckBox, ShiftLockOverrideText = nil, nil, nil
		if not IsTouchClient and game.StarterPlayer.EnableMouseLockOption then
			ShiftLockText = createTextLabel(UDim2.new(0.5, -6, 0, CurrentYOffset), "Enable Shift Lock Switch:", "ShiftLockText")
			ShiftLockText.Parent = GameSettingsMenuFrame

			ShiftLockCheckBox = createTextButton(UDim2.new(0, 32, 0, 32), UDim2.new(0.5, 6, 0, CurrentYOffset - 18),
				IsShiftLockEnabled and "X" or "", Enum.FontSize.Size24, Enum.ButtonStyle.RobloxRoundButton)
			ShiftLockCheckBox.Name = "ShiftLockCheckBox"
			ShiftLockCheckBox.ZIndex = BASE_Z_INDEX + 4
			ShiftLockCheckBox.Visible = LocalPlayer.DevEnableMouseLock
			ShiftLockCheckBox.Parent = GameSettingsMenuFrame

			ShiftLockOverrideText = createTextLabel(UDim2.new(0.5, 6, 0, CurrentYOffset), "Set By Game", "ShiftLockOverrideText")
			ShiftLockOverrideText.TextXAlignment = Enum.TextXAlignment.Left
			ShiftLockOverrideText.TextColor3 = Color3.new(180/255, 180/255, 180/255)
			ShiftLockOverrideText.Visible = not LocalPlayer.DevEnableMouseLock
			ShiftLockOverrideText.Parent = GameSettingsMenuFrame

			CurrentYOffset = CurrentYOffset + 36
		end
		--[[ Fullscreen Mode ]]--
		if not IsTouchClient then
			local fullScreenText = createTextLabel(UDim2.new(0.5, -6, 0, CurrentYOffset), "Fullscreen:", "FullScreenText")
			fullScreenText.Parent = GameSettingsMenuFrame

			local fullScreenTextCheckBox = createTextButton(UDim2.new(0, 32, 0, 32), UDim2.new(0.5, 6, 0, CurrentYOffset - 18),
			GameSettings:InFullScreen() and "X" or "", Enum.FontSize.Size24, Enum.ButtonStyle.RobloxRoundButton)
			fullScreenTextCheckBox.Name = "FullScreenTextCheckBox"
			fullScreenTextCheckBox.ZIndex = BASE_Z_INDEX + 4
			fullScreenTextCheckBox.Parent = GameSettingsMenuFrame

			GameSettings.FullscreenChanged:Connect(function(isFullscreen)
				fullScreenTextCheckBox.Text = isFullscreen and "X" or ""
			end)
			CurrentYOffset = CurrentYOffset + 36
		end
		

		--[[ OK/Return button ]]--
		if IsTouchClient then CurrentYOffset = CurrentYOffset + 48 end
		local GameSettingsBackButton = createTextButton(MENU_BTN_SML, UDim2.new(0.5, -84, 0, CurrentYOffset),
			"Back", Enum.FontSize.Size24, Enum.ButtonStyle.RobloxRoundDefaultButton)
		GameSettingsBackButton.Name = "GameSettingsBackButton"
		GameSettingsBackButton.Parent = GameSettingsMenuFrame

--[[ Help Menu ]]--
	CurrentYOffset = 24
	local HelpMenuFrame = createMenuFrame("HelpMenuFrame", UDim2.new(1, 0, 0, 0))
	HelpMenuFrame.Parent = SettingClipFrame

		local HelpMenuTitle = createMenuTitleLabel("HelpMenuTitle", "Keyboard & Mouse Controls", CurrentYOffset)
		HelpMenuTitle.Parent = HelpMenuFrame
		CurrentYOffset = CurrentYOffset + 32

		local HelpMenuButtonFrame = Instance.new('Frame')
		HelpMenuButtonFrame.Name = "HelpMenuButtonFrame"
		HelpMenuButtonFrame.Size = UDim2.new(0.9, 0, 0, 45)
		HelpMenuButtonFrame.Position = UDim2.new(0.05, 0, 0, CurrentYOffset)
		HelpMenuButtonFrame.BackgroundTransparency = 1
		HelpMenuButtonFrame.ZIndex = BASE_Z_INDEX + 4
		HelpMenuButtonFrame.Parent = HelpMenuFrame
		CurrentYOffset = CurrentYOffset + 60

			local CurrentHelpDialogButton = nil
			local HelpLookButton = createTextButton(UDim2.new(0.25, 0, 1, 0), UDim2.new(0, 0, 0, 0),
				"Look", Enum.FontSize.Size24, Enum.ButtonStyle.RobloxRoundDefaultButton)
			HelpLookButton.Name = "HelpLookButton"
			HelpLookButton.Parent = HelpMenuButtonFrame

			local HelpMoveButton = createTextButton(UDim2.new(0.25, 0, 1, 0), UDim2.new(0.25, 0, 0, 0),
				"Movement", Enum.FontSize.Size24, Enum.ButtonStyle.RobloxRoundButton)
			HelpMoveButton.Name = "HelpMoveButton"
			HelpMoveButton.Parent = HelpMenuButtonFrame

			local HelpGearButton = createTextButton(UDim2.new(0.25, 0, 1, 0), UDim2.new(0.5, 0, 0, 0),
				"Gear", Enum.FontSize.Size24, Enum.ButtonStyle.RobloxRoundButton)
			HelpGearButton.Name = "HelpGearButton"
			HelpGearButton.Parent = HelpMenuButtonFrame

			local HelpZoomButton = createTextButton(UDim2.new(0.25, 0, 1, 0), UDim2.new(0.75, 0, 0, 0),
				"Zoom", Enum.FontSize.Size24, Enum.ButtonStyle.RobloxRoundButton)
			HelpZoomButton.Name = "HelpZoomButton"
			HelpZoomButton.Parent = HelpMenuButtonFrame

			CurrentHelpDialogButton = HelpLookButton

		local HelpMenuImage = Instance.new('ImageLabel')
		HelpMenuImage.Name = "HelpMenuImage"
		HelpMenuImage.Size = UDim2.new(0.9, 0, 0.5, 0)
		HelpMenuImage.Position = UDim2.new(0.05, 0, 0, CurrentYOffset)
		HelpMenuImage.BackgroundTransparency = 1
		HelpMenuImage.Image = GameSettings.ControlMode == Enum.ControlMode.MouseLockSwitch and HELP_IMG.SHIFT_LOCK or HELP_IMG.CLASSIC_MOVE
		HelpMenuImage.ZIndex = BASE_Z_INDEX + 4
		HelpMenuImage.Parent = HelpMenuFrame
		CurrentYOffset = CurrentYOffset + 234

		local HelpConsoleButton = createTextButton(UDim2.new(0, 70, 0, 30), UDim2.new(1, -75, 0, CurrentYOffset + 20),
			"Log:", Enum.FontSize.Size18, Enum.ButtonStyle.RobloxRoundButton)
		HelpConsoleButton.Name = "HelpConsoleButton"
		HelpConsoleButton.TextXAlignment = Enum.TextXAlignment.Left
		HelpConsoleButton.Parent = HelpMenuFrame

			local HelpConsoleText = Instance.new('TextLabel')
			HelpConsoleText.Name = "HelpConsoleText"
			HelpConsoleText.Size = UDim2.new(0, 16, 0, 30)
			HelpConsoleText.Position = UDim2.new(1, -14, 0, -12)
			HelpConsoleText.BackgroundTransparency = 1
			HelpConsoleText.Font = Enum.Font.SourceSansBold
			HelpConsoleText.FontSize = Enum.FontSize.Size18
			HelpConsoleText.TextColor3 = Color3.new(0, 1, 0)
			HelpConsoleText.ZIndex = BASE_Z_INDEX + 4
			HelpConsoleText.Text = "F9"
			HelpConsoleText.Parent = HelpConsoleButton

		local HelpMenuBackButton = createTextButton(MENU_BTN_SML, UDim2.new(0.5, -84, 0, CurrentYOffset),
			"Back", Enum.FontSize.Size24, Enum.ButtonStyle.RobloxRoundDefaultButton)
		HelpMenuBackButton.Name = "HelpMenuBackButton"
		HelpMenuBackButton.Parent = HelpMenuFrame

--[[ Report Abuse Menu ]]--
	CurrentYOffset = 24
	local IsReportingPlayer = false
	local CurrentAbusingPlayer = nil
	local AbuseReason = nil

	local ReportAbuseFrame = createMenuFrame("ReportAbuseFrame", UDim2.new(1, 0, 0, 0))
	ReportAbuseFrame.Parent = SettingClipFrame

		local ReportAbuseTitle = createMenuTitleLabel("ReportAbuseTitle", "Report Abuse", CurrentYOffset)
		ReportAbuseTitle.Parent = ReportAbuseFrame
		CurrentYOffset = IsSmallScreen and (CurrentYOffset + 20) or (CurrentYOffset + 32)

		local ReportAbuseDescription = Instance.new('TextLabel')
		ReportAbuseDescription.Name = "ReportAbuseDescription"
		ReportAbuseDescription.Size = UDim2.new(1, -40, 0, 40)
		ReportAbuseDescription.Position = UDim2.new(0, 35, 0, CurrentYOffset)
		ReportAbuseDescription.BackgroundTransparency = 1
		ReportAbuseDescription.Font = Enum.Font.SourceSans
		ReportAbuseDescription.FontSize = Enum.FontSize.Size18
		ReportAbuseDescription.TextColor3 = Color3.new(1, 1, 1)
		ReportAbuseDescription.TextWrap = true
		ReportAbuseDescription.TextXAlignment = Enum.TextXAlignment.Left
		ReportAbuseDescription.TextYAlignment = Enum.TextYAlignment.Top
		ReportAbuseDescription.ZIndex = BASE_Z_INDEX + 4
		ReportAbuseDescription.Text = "This will send a complete report to a moderator. The moderator will review the chat log and take appropriate action."
		ReportAbuseDescription.Parent = ReportAbuseFrame
		CurrentYOffset = IsSmallScreen and (CurrentYOffset + 48) or (CurrentYOffset + 70)

		local ReportGameOrPlayerText = createTextLabel(UDim2.new(0.5, -6, 0, CurrentYOffset), "Game or Player:", "ReportGameOrPlayerText")
		ReportGameOrPlayerText.Parent = ReportAbuseFrame
		CurrentYOffset = CurrentYOffset + 40

		local ReportPlayerText = createTextLabel(UDim2.new(0.5, -6, 0, CurrentYOffset), "Which Player:", "ReportPlayerText")
		ReportPlayerText.Parent = ReportAbuseFrame
		CurrentYOffset = CurrentYOffset + 40

		local ReportTypeOfAbuseText = createTextLabel(UDim2.new(0.5, -6, 0, CurrentYOffset), "Type of Abuse:", "ReportTypeOfAbuseText")
		ReportTypeOfAbuseText.Parent = ReportAbuseFrame
		CurrentYOffset = IsSmallScreen and (CurrentYOffset + 10) or (CurrentYOffset + 40)

		local ReportDescriptionText = ReportAbuseDescription:Clone()
		ReportDescriptionText.Name = "ReportDescriptionText"
		ReportDescriptionText.Text = "Short Description: (optional)"
		ReportDescriptionText.Position = UDim2.new(0, 35, 0, CurrentYOffset)
		ReportDescriptionText.Parent = ReportAbuseFrame
		CurrentYOffset = CurrentYOffset + 28

		local ReportDescriptionTextBox = Instance.new('TextBox')
		ReportDescriptionTextBox.Name = "ReportDescriptionTextBox"
		ReportDescriptionTextBox.Size = UDim2.new(1, -70, 1, IsSmallScreen and (-CurrentYOffset - 60) or (-CurrentYOffset - 100))
		ReportDescriptionTextBox.Position = UDim2.new(0, 35, 0, CurrentYOffset)
		ReportDescriptionTextBox.BackgroundTransparency = 1
		ReportDescriptionTextBox.Font = Enum.Font.SourceSans
		ReportDescriptionTextBox.FontSize = Enum.FontSize.Size18
		ReportDescriptionTextBox.ClearTextOnFocus = false
		ReportDescriptionTextBox.TextColor3 = Color3.new(0, 0, 0)
		ReportDescriptionTextBox.TextXAlignment = Enum.TextXAlignment.Left
		ReportDescriptionTextBox.TextYAlignment = Enum.TextYAlignment.Top
		ReportDescriptionTextBox.Text = ""
		ReportDescriptionTextBox.TextWrap = true
		ReportDescriptionTextBox.ZIndex = BASE_Z_INDEX + 4
		ReportDescriptionTextBox.Visible = false
		ReportDescriptionTextBox.Parent = ReportAbuseFrame

		local ReportDescriptionTextBoxBg = Instance.new('TextButton')
		ReportDescriptionTextBoxBg.Name = "ReportDescriptionTextBoxBg"
		ReportDescriptionTextBoxBg.Size = UDim2.new(1, 16, 1, 16)
		ReportDescriptionTextBoxBg.Position = UDim2.new(0, -8, 0, -8)
		ReportDescriptionTextBoxBg.Text = ""
		ReportDescriptionTextBoxBg.Active = false
		ReportDescriptionTextBoxBg.AutoButtonColor = false
		ReportDescriptionTextBoxBg.Style = Enum.ButtonStyle.RobloxRoundDropdownButton
		ReportDescriptionTextBoxBg.ZIndex = BASE_Z_INDEX + 4
		ReportDescriptionTextBoxBg.Parent = ReportDescriptionTextBox
		CurrentYOffset = CurrentYOffset + ReportDescriptionTextBox.AbsoluteSize.y + 20

		local buttonPosition = IsSmallScreen and UDim2.new(0.5, 2, 1, -MENU_BTN_SML.Y.Offset - 4) or
			UDim2.new(0.5, 2, 0, CurrentYOffset)

		local ReportSubmitButton = createTextButton(MENU_BTN_SML, buttonPosition,
			"Submit", Enum.FontSize.Size24, Enum.ButtonStyle.RobloxRoundDefaultButton)
		ReportSubmitButton.Name = "ReportSubmitButton"
		ReportSubmitButton.ZIndex = BASE_Z_INDEX
		ReportSubmitButton.Active = false
		ReportSubmitButton.Parent = ReportAbuseFrame

		buttonPosition = IsSmallScreen and UDim2.new(0.5, -170, 1, -MENU_BTN_SML.Y.Offset - 4) or
			UDim2.new(0.5, -170, 0, CurrentYOffset)

		local ReportCancelButton = createTextButton(MENU_BTN_SML, buttonPosition,
			"Cancel", Enum.FontSize.Size24, Enum.ButtonStyle.RobloxRoundButton)
		ReportCancelButton.Name = "ReportSubmitButton"
		ReportCancelButton.Parent = ReportAbuseFrame

		local ReportPlayerDropDown = nil
		local ReportTypeOfAbuseDropDown = nil
		local ReportPlayerOrGameDropDown = nil

		local function cleanupReportAbuseMenu()
			ReportDescriptionTextBox.Visible = false
			ReportDescriptionTextBox.Text = ""
			ReportSubmitButton.ZIndex = BASE_Z_INDEX
			ReportSubmitButton.Active = false
			if ReportPlayerDropDown then
				ReportPlayerDropDown.Frame:Destroy()
				ReportPlayerDropDown = nil
			end
			if ReportTypeOfAbuseDropDown then
				ReportTypeOfAbuseDropDown.Frame:Destroy()
				ReportTypeOfAbuseDropDown = nil
			end
			if ReportPlayerOrGameDropDown then
				ReportPlayerOrGameDropDown.Frame:Destroy()
				ReportPlayerOrGameDropDown = nil
			end
		end

		local function createReportAbuseMenu()
			local playerNames = {}
			local nameToRbxPlayer = {}
			local players = Players:GetChildren()
			local index = 1
			for i = 1, #players do
				local player = players[i]
				if player:IsA('Player') and player ~= LocalPlayer then
					playerNames[index] = player.Name
					nameToRbxPlayer[player.Name] = player
					index = index + 1
				end
			end

			ReportTypeOfAbuseDropDown = RbxGuiLibaray.CreateScrollingDropDownMenu(
				function(text)
					AbuseReason = text
					ReportSubmitButton.ZIndex = BASE_Z_INDEX + 4
					ReportSubmitButton.Active = true
				end, UDim2.new(0, 200, 0, 32), UDim2.new(0.5, 6, 0, ReportTypeOfAbuseText.Position.Y.Offset - 16), BASE_Z_INDEX)
			ReportTypeOfAbuseDropDown.SetActive(false)
			ReportTypeOfAbuseDropDown.Frame.Parent = ReportAbuseFrame
			-- list will be set depending on which type of report it is (game or player)

			ReportPlayerDropDown = RbxGuiLibaray.CreateScrollingDropDownMenu(
				function(text)
					CurrentAbusingPlayer = nameToRbxPlayer[text] or LocalPlayer
					ReportTypeOfAbuseText.ZIndex = BASE_Z_INDEX + 4
					ReportTypeOfAbuseDropDown.CreateList(ABUSE_TYPES_PLAYER)
					ReportTypeOfAbuseDropDown.UpdateZIndex(BASE_Z_INDEX + 4)
					ReportTypeOfAbuseDropDown.SetActive(true)
				end, UDim2.new(0, 200, 0, 32), UDim2.new(0.5, 6, 0, ReportPlayerText.Position.Y.Offset - 16), BASE_Z_INDEX)
			ReportPlayerDropDown.SetActive(false)
			ReportPlayerDropDown.CreateList(playerNames)
			ReportPlayerDropDown.Frame.Parent = ReportAbuseFrame

			ReportPlayerOrGameDropDown = RbxGuiLibaray.CreateScrollingDropDownMenu(
				function(text)
					if text == "Player" then
						IsReportingPlayer = true
						ReportPlayerText.ZIndex = BASE_Z_INDEX + 4
						ReportPlayerDropDown.UpdateZIndex(BASE_Z_INDEX + 4)
						ReportPlayerDropDown.SetActive(true)
						--
						ReportTypeOfAbuseText.ZIndex = BASE_Z_INDEX
						ReportTypeOfAbuseDropDown.CreateList(ABUSE_TYPES_PLAYER)
						ReportTypeOfAbuseDropDown.UpdateZIndex(BASE_Z_INDEX)
						ReportTypeOfAbuseDropDown.SetActive(false)
					elseif text == "Game" then
						IsReportingPlayer = false
						if CurrentAbusingPlayer then
							CurrentAbusingPlayer = nil
						end
						ReportPlayerDropDown.SetSelectionText("Choose One")
						ReportPlayerText.ZIndex = BASE_Z_INDEX
						ReportPlayerDropDown.SetActive(false)
						ReportPlayerDropDown.UpdateZIndex(BASE_Z_INDEX)
						--
						ReportTypeOfAbuseText.ZIndex = BASE_Z_INDEX + 4
						ReportTypeOfAbuseDropDown.CreateList(ABUSE_TYPES_GAME)
						ReportTypeOfAbuseDropDown.UpdateZIndex(BASE_Z_INDEX + 4)
						ReportTypeOfAbuseDropDown.SetActive(true)
					else
						IsReportingPlayer = false
						ReportPlayerText.ZIndex = BASE_Z_INDEX
						ReportPlayerDropDown.SetActive(false)
						ReportPlayerDropDown.UpdateZIndex(BASE_Z_INDEX)
					end
					ReportSubmitButton.ZIndex = BASE_Z_INDEX
					ReportSubmitButton.Active = false
				end, UDim2.new(0, 200, 0, 32), UDim2.new(0.5, 6, 0, ReportGameOrPlayerText.Position.Y.Offset - 16), BASE_Z_INDEX + 4)
			ReportPlayerOrGameDropDown.Frame.Parent = ReportAbuseFrame
			ReportPlayerOrGameDropDown.CreateList({ "Game", "Player", })

			-- drop down menu connections
			ReportPlayerDropDown.CurrentSelectionButton.MouseButton1Click:Connect(function()
				if CurrentOpenedDropDownMenu ~= ReportPlayerDropDown then
					closeCurrentDropDownMenu()
					CurrentOpenedDropDownMenu = ReportPlayerDropDown
				end
			end)
			ReportTypeOfAbuseDropDown.CurrentSelectionButton.MouseButton1Click:Connect(function()
				if CurrentOpenedDropDownMenu ~= ReportTypeOfAbuseDropDown then
					closeCurrentDropDownMenu()
					CurrentOpenedDropDownMenu = ReportTypeOfAbuseDropDown
				end
			end)
			ReportPlayerOrGameDropDown.CurrentSelectionButton.MouseButton1Click:Connect(function()
				if CurrentOpenedDropDownMenu ~= ReportPlayerOrGameDropDown then
					closeCurrentDropDownMenu()
					CurrentOpenedDropDownMenu = ReportPlayerOrGameDropDown
				end
			end)
			ReportDescriptionTextBox.Visible = true
		end

	CurrentYOffset = IsSmallScreen and 70 or 140
	local ReportAbuseConfirmationFrame = createMenuFrame("ReportAbuseConfirmationFrame", UDim2.new(1, 0, 0, 0))
	ReportAbuseConfirmationFrame.Parent = SettingClipFrame

		local ReportAbuseConfirmationText = Instance.new('TextLabel')
		ReportAbuseConfirmationText.Name = "ReportAbuseConfirmationText"
		ReportAbuseConfirmationText.Size = UDim2.new(1, -20, 0, 80)
		ReportAbuseConfirmationText.Position = UDim2.new(0, 10, 0, CurrentYOffset)
		ReportAbuseConfirmationText.BackgroundTransparency = 1
		ReportAbuseConfirmationText.Font = Enum.Font.SourceSans
		ReportAbuseConfirmationText.FontSize = Enum.FontSize.Size24
		ReportAbuseConfirmationText.TextColor3 = Color3.new(1, 1, 1)
		ReportAbuseConfirmationText.TextWrap = true
		ReportAbuseConfirmationText.TextScaled = true
		ReportAbuseConfirmationText.ZIndex = BASE_Z_INDEX + 4
		ReportAbuseConfirmationText.Text = ""
		ReportAbuseConfirmationText.Parent = ReportAbuseConfirmationFrame
		CurrentYOffset = CurrentYOffset + 122

		local ReportAbuseConfirmationButton = createTextButton(MENU_BTN_SML, UDim2.new(0.5, -MENU_BTN_SML.X.Offset/2, 0, CurrentYOffset),
			"OK", Enum.FontSize.Size24, Enum.ButtonStyle.RobloxRoundDefaultButton)
		ReportAbuseConfirmationButton.Name = "ReportAbuseConfirmationButton"
		ReportAbuseConfirmationButton.Parent = ReportAbuseConfirmationFrame

--[[ Leave Game Confirmation Menu ]]--
	CurrentYOffset = IsSmallScreen and 70 or 140
	local LeaveGameMenuFrame = createMenuFrame("LeaveGameMenuFrame", UDim2.new(1, 0, 0, 0))
	LeaveGameMenuFrame.Parent = SettingClipFrame

		local LeaveGameText = Instance.new('TextLabel')
		LeaveGameText.Name = "LeaveGameText"
		LeaveGameText.Size = UDim2.new(1, 0, 0, 80)
		LeaveGameText.Position = UDim2.new(0, 0, 0, CurrentYOffset)
		LeaveGameText.BackgroundTransparency = 1
		LeaveGameText.Font = Enum.Font.SourceSansBold
		LeaveGameText.FontSize = Enum.FontSize.Size36
		LeaveGameText.TextColor3 = Color3.new(1, 1, 1)
		LeaveGameText.TextWrap = true
		LeaveGameText.ZIndex = BASE_Z_INDEX + 4
		LeaveGameText.Text = "Are you sure you want to leave this game?"
		LeaveGameText.Parent = LeaveGameMenuFrame
		CurrentYOffset = CurrentYOffset + 122

		local LeaveConfirmButton = createTextButton(MENU_BTN_SML, UDim2.new(0.5, 2, 0, CurrentYOffset),
			"Confirm", Enum.FontSize.Size24, Enum.ButtonStyle.RobloxRoundDefaultButton)
		LeaveConfirmButton.Name = "LeaveConfirmButton"
		LeaveConfirmButton.Parent = LeaveGameMenuFrame
		LeaveConfirmButton.MouseButton1Click:Connect(function()
			game.Players.LocalPlayer:Kick("Left game")
		end)

		local LeaveCancelButton = createTextButton(MENU_BTN_SML, UDim2.new(0.5, -170, 0, CurrentYOffset),
			"Cancel", Enum.FontSize.Size24, Enum.ButtonStyle.RobloxRoundButton)
		LeaveCancelButton.Name = "LeaveCancelButton"
		LeaveCancelButton.Parent = LeaveGameMenuFrame

--[[ Menu Functions ]]--
local function pushMenu(nextMenu)
	if IsMenuClosing then return end
	local prevMenu = MenuStack[#MenuStack]
	MenuStack[#MenuStack + 1] = nextMenu
	--
	if prevMenu then
		prevMenu:TweenPosition(UDim2.new(-1, 0, 0, 0), Enum.EasingDirection.InOut, Enum.EasingStyle.Sine, TWEEN_TIME, true)
	end
	if #MenuStack > 1 then
		nextMenu:TweenPosition(UDim2.new(0, 0, 0, 0), Enum.EasingDirection.InOut, Enum.EasingStyle.Sine, TWEEN_TIME, true)
	end
end

local function popMenu()
	if #MenuStack == 0 then return end
	--
	local currentMenu = MenuStack[#MenuStack]
	MenuStack[#MenuStack] = nil
	local prevMenu = MenuStack[#MenuStack]
	--
	if #MenuStack > 0 then
		currentMenu:TweenPosition(UDim2.new(1, 0, 0, 0), Enum.EasingDirection.InOut, Enum.EasingStyle.Sine, TWEEN_TIME, true)
		-- special case to close drop down menus on game settings menu when it goes out of focus
		closeCurrentDropDownMenu()
	end
	if prevMenu then
		prevMenu:TweenPosition(UDim2.new(0, 0, 0, 0), Enum.EasingDirection.InOut, Enum.EasingStyle.Sine, TWEEN_TIME, true)
	end
end

local function emptyMenuStack()
	for k,v in pairs(MenuStack) do
		if k ~= 1 then
			v.Position = UDim2.new(1, 0, 0, 0)
		else
			v.Position = UDim2.new(0, 0, 0, 0)
		end
		MenuStack[k] = nil
	end
end

local function showSettingsRootMenu()
	SettingsButton.Active = false
	pushMenu(RootMenuFrame)
	pcall(function() UserInputService.OverrideMouseIconEnabled = true end)
	--
	SettingsShield.Visible = true
	SettingsShield.Active = true
	--
	SettingClipFrame:TweenPosition(SHOW_MENU_POS, Enum.EasingDirection.InOut, Enum.EasingStyle.Sine, TWEEN_TIME, true)
end

local function closeSettingsMenu()
	IsMenuClosing = true
	SettingClipFrame:TweenPosition(CLOSE_MENU_POS, Enum.EasingDirection.InOut, Enum.EasingStyle.Sine, TWEEN_TIME, true,
	function()
		SettingsShield.Active = false
		SettingsShield.Visible = false
		SettingsButton.Active = true
		--
		emptyMenuStack()
		IsMenuClosing = false
		pcall(function() game:GetService("UserInputService").OverrideMouseIconEnabled = false end)
		-- NOTE: This is a hacky way to raise an event when the menu closes. This is being used by the new
		-- lua controls to correctly set the state of the mouse and shift lock mode when leaving the settings menu.
		if UserSettings().GameSettings.ControlMode == Enum.ControlMode.MouseLockSwitch then
			UserSettings().GameSettings.ControlMode = Enum.ControlMode.Classic
			UserSettings().GameSettings.ControlMode = Enum.ControlMode.MouseLockSwitch
		end
	end)
end

local function showHelpMenu()
	SettingClipFrame:TweenPosition(CLOSE_MENU_POS, Enum.EasingDirection.InOut, Enum.EasingStyle.Sine, TWEEN_TIME, true,
	function()
		SettingClipFrame.Visible = false
	end)
	HelpMenuFrame.Visible = true
	HelpMenuFrame:TweenPosition(UDim2.new(0.2, 0, 0.2, 0), Enum.EasingDirection.InOut, Enum.EasingStyle.Sine, TWEEN_TIME, true)
end

local function hideHelpMenu()
	HelpMenuFrame:TweenPosition(UDim2.new(0.2, 0, 1, 0), Enum.EasingDirection.InOut, Enum.EasingStyle.Sine, TWEEN_TIME, true,
	function()
		HelpMenuFrame.Visible = false
	end)
	SettingClipFrame.Visible = true
	SettingClipFrame:TweenPosition(SHOW_MENU_POS, Enum.EasingDirection.InOut, Enum.EasingStyle.Sine, TWEEN_TIME, true)
end

local function changeHelpDialog(button, img)
	if CurrentHelpDialogButton == button then return end
	--
	CurrentHelpDialogButton.Style = Enum.ButtonStyle.RobloxRoundButton
	CurrentHelpDialogButton = button
	CurrentHelpDialogButton.Style = Enum.ButtonStyle.RobloxRoundDefaultButton
	HelpMenuImage.Image = img
end

local function resetLocalCharacter()
	-- NOTE: This should be fixed at some point to not find humanoid by name.
	-- Devs can rename the players humanoid and bypass this. I am leaving it this way
	-- as to not break any games that currently do this. We need to come up with
	-- a better solution to allow devs to disable character reset
	local player = Players.LocalPlayer
	if player then
		local character = player.Character
		if character then
			local humanoid = character:FindFirstChild('Humanoid')
			if humanoid then
				humanoid.Health = 0
			end
		end
	end
end

local function onRecordVideoToggle()
	IsRecordingVideo = not IsRecordingVideo
	if IsRecordingVideo then
		StopRecordingVideoButton.Visible = true
		RecordVideoButton.Text = "Stop Recording"
	else
		StopRecordingVideoButton.Visible = false
		RecordVideoButton.Text = "Record Video"
	end
end

local function onReportSubmitted()
	if not ReportSubmitButton.Active then return end
	--
	if IsReportingPlayer then
		if CurrentAbusingPlayer and AbuseReason then
			Players:ReportAbuse(CurrentAbusingPlayer, AbuseReason, ReportDescriptionTextBox.Text)
		end
	else
		if AbuseReason then
			Players:ReportAbuse(nil, AbuseReason, ReportDescriptionTextBox.Text)
		end
	end
	if AbuseReason == 'Cheating/Exploiting' then
		ReportAbuseConfirmationText.Text = "Thanks for your report!\n We've recorded your report for evaluation."
	elseif AbuseReason == 'Bullying' or AbuseReason == 'Swearing' then
		ReportAbuseConfirmationText.Text = "Thanks for your report! Our moderators will review the chat logs and determine what happened. The other user is probably just trying to make you mad. If anyone used swear words, inappropriate language, or threatened you in real life, please report them for Bad Words or Threats"
	else
		ReportAbuseConfirmationText.Text = "Thanks for your report! Our moderators will review the chat logs and determine what happened."
	end
	pushMenu(ReportAbuseConfirmationFrame)
	cleanupReportAbuseMenu()
end



local function updateUserSettingsMenu(property)
	if property == "DevEnableMouseLock" then
		ShiftLockCheckBox.Visible = LocalPlayer.DevEnableMouseLock
		ShiftLockOverrideText.Visible = not LocalPlayer.DevEnableMouseLock
		IsShiftLockEnabled = LocalPlayer.DevEnableMouseLock and GameSettings.ControlMode == Enum.ControlMode.MouseLockSwitch
		ShiftLockCheckBox.Text = IsShiftLockEnabled and "X" or ""
	elseif property == "DevComputerCameraMode" then
		local isUserChoice = LocalPlayer.DevComputerCameraMode == Enum.DevComputerCameraMovementMode.UserChoice
		CameraModeDropDown.Visible = isUserChoice
		CameraModeOverrideText.Visible = not isUserChoice
	elseif property == "DevComputerMovementMode" then
		local isUserChoice = LocalPlayer.DevComputerMovementMode == Enum.DevComputerMovementMode.UserChoice
		MovementModeDropDown.Visible = isUserChoice
		MovementModeOverrideText.Visible = not isUserChoice
	-- TOUCH
	elseif property == "DevTouchMovementMode" then
		local isUserChoice = LocalPlayer.DevTouchMovementMode == Enum.DevTouchMovementMode.UserChoice
		MovementModeDropDown.Visible = isUserChoice
		MovementModeOverrideText.Visible = not isUserChoice
	elseif property == "DevTouchCameraMode" then
		local isUserChoice = LocalPlayer.DevTouchCameraMode == Enum.DevTouchCameraMode.UserChoice
		CameraModeDropDown.Visible = isUserChoice
		CameraModeOverrideText.Visible = not isUserChoice
	end
end

--[[ Input Actions ]]--
do
	local escapePressedCn = nil
	SettingsShield.Parent = SettingsMenuFrame
	--
	if IsTouchClient then
		SettingsButton.TouchTap:Connect(showSettingsRootMenu)
		-- Root Menu Connections
		ResumeGameButton.TouchTap:Connect(closeSettingsMenu)
		ResetCharacterButton.TouchTap:Connect(function() pushMenu(ResetCharacterFrame) end)
		GameSettingsButton.TouchTap:Connect(function() pushMenu(GameSettingsMenuFrame) end)
		ReportAbuseButton.TouchTap:Connect(function()
			createReportAbuseMenu()
			pushMenu(ReportAbuseFrame)
		end)
		LeaveGameButton.TouchTap:Connect(function() pushMenu(LeaveGameMenuFrame) end)

		-- Reset Character Menu Connections
		ConfirmResetButton.TouchTap:Connect(function()
			resetLocalCharacter()
			closeSettingsMenu()
		end)
		CancelResetButton.TouchTap:Connect(popMenu)

		-- Game Settings Menu Connections
		GameSettingsBackButton.TouchTap:Connect(popMenu)

		-- Report Abuse Menu Connections
		ReportCancelButton.TouchTap:Connect(function()
			popMenu()
			cleanupReportAbuseMenu()
		end)
		ReportSubmitButton.TouchTap:Connect(onReportSubmitted)
		ReportAbuseConfirmationButton.TouchTap:Connect(closeSettingsMenu)

		-- Leave Game Menu
		LeaveCancelButton.TouchTap:Connect(popMenu)
	else
		SettingsButton.MouseButton1Click:Connect(showSettingsRootMenu)
		UserInputService.InputBegan:Connect(function(input,processed)
			if input.KeyCode == Enum.KeyCode.Escape then
				if UserInputService:GetFocusedTextBox() then return end
				if not SettingsShield.Visible then
					showSettingsRootMenu()
				else
					closeSettingsMenu()
				end
			end
		end)
		-- Root Menu Connections
		ResumeGameButton.MouseButton1Click:Connect(closeSettingsMenu)
		ResetCharacterButton.MouseButton1Click:Connect(function() pushMenu(ResetCharacterFrame) end)
		GameSettingsButton.MouseButton1Click:Connect(function() pushMenu(GameSettingsMenuFrame) end)
		HelpButton.MouseButton1Click:Connect(function() pushMenu(HelpMenuFrame) end)
		ReportAbuseButton.MouseButton1Click:Connect(function()
			createReportAbuseMenu()
			pushMenu(ReportAbuseFrame)
		end)
		LeaveGameButton.MouseButton1Click:Connect(function() pushMenu(LeaveGameMenuFrame) end)

		--[[ Video Recording ]]--
		if RecordVideoButton and StopRecordingVideoButton then
			RecordVideoButton.MouseButton1Click:Connect(function()
				onRecordVideoToggle()
				closeSettingsMenu()
			end)
			StopRecordingVideoButton.MouseButton1Click:Connect(onRecordVideoToggle)
			-- Stop recording on screen resize
			RobloxGui.Changed:Connect(function(property)
				if IsRecordingVideo and property == 'AbsoluteSize' then
					onRecordVideoToggle()
				end
			end)
		end

		-- Reset Character Menu Connections
		ConfirmResetButton.MouseButton1Click:Connect(function()
			resetLocalCharacter()
			closeSettingsMenu()
		end)
		CancelResetButton.MouseButton1Click:Connect(popMenu)

		-- Game Settings Menu Connections
		if ShiftLockCheckBox then
			ShiftLockCheckBox.MouseButton1Click:Connect(function()
				IsShiftLockEnabled = not IsShiftLockEnabled
				ShiftLockCheckBox.Text = IsShiftLockEnabled and "X" or ""
				game.ReplicatedStorage.shiftlock.Value = IsShiftLockEnabled
			end)
		end
		GameSettingsBackButton.MouseButton1Click:Connect(popMenu)

		-- Help Menu Connections
		HelpMenuBackButton.MouseButton1Click:Connect(popMenu)
		HelpLookButton.MouseButton1Click:Connect(function()
			changeHelpDialog(HelpLookButton, GameSettings.ControlMode == Enum.ControlMode.MouseLockSwitch and HELP_IMG.SHIFT_LOCK or HELP_IMG.CLASSIC_MOVE)
		end)
		HelpMoveButton.MouseButton1Click:Connect(function()
			changeHelpDialog(HelpMoveButton, HELP_IMG.MOVEMENT)
		end)
		HelpGearButton.MouseButton1Click:Connect(function()
			changeHelpDialog(HelpGearButton, HELP_IMG.GEAR)
		end)
		HelpZoomButton.MouseButton1Click:Connect(function()
			changeHelpDialog(HelpZoomButton, HELP_IMG.ZOOM)
		end)

		-- Report Abuse Connections
		ReportCancelButton.MouseButton1Click:Connect(function()
			popMenu()
			cleanupReportAbuseMenu()
		end)
		ReportSubmitButton.MouseButton1Click:Connect(onReportSubmitted)
		ReportAbuseConfirmationButton.MouseButton1Click:Connect(closeSettingsMenu)

		-- Leave Game Menu
		LeaveCancelButton.MouseButton1Click:Connect(popMenu)

		-- Dev Console Connections
	end

	LocalPlayer.Changed:Connect(function(property)
		if IsTouchClient then
			if TOUCH_CHANGED_PROPS[property] then
				updateUserSettingsMenu(property)
			end
		else
			if PC_CHANGED_PROPS[property] then
				updateUserSettingsMenu(property)
			end
		end
	end)

	-- Remove old gui buttons
	-- TODO: Gut this from the engine code
	local oldLeaveGameButton = TopLeftControl:FindFirstChild('Exit')
	if oldLeaveGameButton then
		oldLeaveGameButton:Destroy()
	else
		oldLeaveGameButton = BottomLeftControl:FindFirstChild('Exit')
		if oldLeaveGameButton then oldLeaveGameButton:Destroy() end
	end

	SettingsMenuFrame.Parent = RobloxGui
end

return ""
