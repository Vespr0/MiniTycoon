local Radio = {}

-- Services --
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

-- Folders --
local Shared = ReplicatedStorage.Shared
local Packages = ReplicatedStorage.Packages

-- Modules --
local Ui = require(script.Parent.Parent.UiUtility)
local AssetsDealer = require(Shared.AssetsDealer)
local ClientInput = require(script.Parent.Parent.Parent.Input.ClientInput)
-- TODO: peek SoundManager
-- local SoundManager = require(Shared.Sound.SoundManager)

-- Fusion --
local Fusion = require(Packages.fusion)
local peek = Fusion.peek

-- Gui elements --
local Gui = Ui.PlayerGui:WaitForChild("Radio")
local MainFrame = Gui:WaitForChild("MainFrame")
local Button = MainFrame:WaitForChild("Button")
local StatusLabel = MainFrame:WaitForChild("Status")
local ButtonIcon = Button:WaitForChild("Icon")

-- Constants --
local MUSIC_ENABLED_DEFAULT = true
local MUSIC_VOLUME = 0.2
local FADE_TIME = 5
local MAX_SWAY_ROTATION = 10
local MUSIC_TRACKS = {
	{
		directory = "Music/ChillFactor",
		displayName = "Chill Factor",
	},
	{
		directory = "Music/ArcadeMaze",
		displayName = "Arcade Maze",
	},
	{
		directory = "Music/Beachcomber",
		displayName = "Beachcomber",
	},
	{
		directory = "Music/EmotionalWilderness",
		displayName = "Emotional Wilderness",
	},
	{
		directory = "Music/Troposphere",
		displayName = "Troposphere",
	},
}
local BUTTON_COLOR_ON = Color3.fromRGB(255, 255, 255) -- White for on
local BUTTON_COLOR_OFF = Color3.fromRGB(224, 47, 47) -- Red for off
local STATUS_COLOR_ON = Color3.fromRGB(255, 255, 255) -- White for on
local STATUS_COLOR_OFF = Color3.fromRGB(224, 47, 47) -- Red for off

-- Variables --
local currentMusicSound = nil
local Random = Random.new(os.clock())
local scope = Fusion.scoped(Fusion)

-- State --
local musicEnabledState = scope:Value(MUSIC_ENABLED_DEFAULT)
local currentTrackIndexState = scope:Value(1)
local swayGoal = scope:Value(0) -- For the swaying animation

-- Computed values --
local buttonColor = scope:Computed(function(peek)
	return peek(musicEnabledState) and BUTTON_COLOR_ON or BUTTON_COLOR_OFF
end)

local statusText = scope:Computed(function(peek)
	local musicEnabled = peek(musicEnabledState)
	local currentTrackIndex = peek(currentTrackIndexState)

	if musicEnabled and MUSIC_TRACKS[currentTrackIndex] then
		return "♪ Playing: " .. MUSIC_TRACKS[currentTrackIndex].displayName .. " ♪"
	else
		return "♪ Off ♪"
	end
end)

local statusColor = scope:Computed(function(peek)
	return peek(musicEnabledState) and STATUS_COLOR_ON or STATUS_COLOR_OFF
end)

-- Swaying animation tween
local swayTween = scope:Tween(
	swayGoal,
	TweenInfo.new(
		1.5, -- Duration: 1.5 seconds for smooth sway
		Enum.EasingStyle.Sine, -- Smooth sine wave motion
		Enum.EasingDirection.InOut, -- Smooth start and end
		-1, -- Infinite repeats
		true -- Reverse (creates oscillation)
	)
)

local function randomizeTrack()
	if #MUSIC_TRACKS > 1 then
		local currentTrackIndex = peek(currentTrackIndexState)
		local newIndex = Random:NextInteger(1, #MUSIC_TRACKS)
		-- Ensure we don't pick the same track twice in a row
		while newIndex == currentTrackIndex do
			newIndex = Random:NextInteger(1, #MUSIC_TRACKS)
		end
		currentTrackIndexState:set(newIndex)
	end
end

local function stopCurrentMusicImmediately()
	if currentMusicSound then
		currentMusicSound:Stop()
		currentMusicSound:Destroy()
		currentMusicSound = nil
	end
end

local function stopCurrentMusicWithFade()
	if currentMusicSound then
		-- Fade out the current music for smooth transitions
		local fadeOut = TweenService:Create(currentMusicSound, TweenInfo.new(FADE_TIME, Enum.EasingStyle.Sine), {
			Volume = 0,
		})
		fadeOut:Play()

		fadeOut.Completed:Connect(function()
			if currentMusicSound then
				currentMusicSound:Stop()
				currentMusicSound:Destroy()
				currentMusicSound = nil
			end
		end)
	end
end

local function playMusic()
	if not peek(musicEnabledState) then
		return
	end

	-- Stop any currently playing music with fade for smooth transitions
	stopCurrentMusicWithFade()

	-- Get the current track
	local currentTrack = MUSIC_TRACKS[peek(currentTrackIndexState)]
	local musicAsset = AssetsDealer.GetSound(currentTrack.directory)

	if musicAsset then
		-- Clone the sound and set it up for background music
		currentMusicSound = musicAsset:Clone()
		currentMusicSound.Volume = 0 -- Start at 0 for fade in
		currentMusicSound.Looped = true
		currentMusicSound.Parent = workspace.Nodes and workspace.Nodes.Sounds or workspace

		-- Start playing and fade in
		currentMusicSound:Play()
		local fadeIn = TweenService:Create(currentMusicSound, TweenInfo.new(FADE_TIME, Enum.EasingStyle.Sine), {
			Volume = MUSIC_VOLUME,
		})
		fadeIn:Play()
	else
		warn("Could not find music track:", currentTrack.directory)
	end
end

local function onButtonPressed()
	local newMusicEnabled = not peek(musicEnabledState)
	musicEnabledState:set(newMusicEnabled)

	Ui.PlaySound("Click")

	if newMusicEnabled then
		randomizeTrack() -- Randomize track when turning music back on
		playMusic()
	else
		stopCurrentMusicImmediately() -- No fade when turning off
	end
end

function Radio.Setup()
	-- Connect button press event
	Button.Activated:Connect(onButtonPressed)

	-- Set up reactive observers for existing GUI elements
	scope:Observer(buttonColor):onChange(function()
		Ui.UpdateToggleButtonColor(ButtonIcon, peek(musicEnabledState), BUTTON_COLOR_ON, BUTTON_COLOR_OFF)
	end)

	scope:Observer(statusText):onChange(function()
		StatusLabel.Text = peek(statusText)
	end)

	scope:Observer(statusColor):onChange(function()
		StatusLabel.TextColor3 = peek(statusColor)
	end)

	-- Apply swaying rotation to the button
	scope:Observer(swayTween):onChange(function()
		local rotation = peek(swayTween)
		if peek(musicEnabledState) then
			ButtonIcon.Rotation = rotation-MAX_SWAY_ROTATION/2
		else	
			ButtonIcon.Rotation = 0
		end
	end)

	-- TODO: Decide on this
	-- Hide status label on mobile devices
	-- StatusLabel.Visible = not ClientInput.IsMobile

	-- Randomize initial track selection
	randomizeTrack()

	-- Trigger observers to set initial values
	peek(buttonColor) -- Triggers the buttonColor observer
	peek(statusText) -- Triggers the statusText observer
	peek(statusColor) -- Triggers the statusColor observer
	peek(swayTween) -- Triggers the swayTween observer

	swayGoal:set(MAX_SWAY_ROTATION)

	-- Set initial state and start music if enabled
	-- print("Radio module initialized. Music is", peek(musicEnabledState) and "ON" or "OFF")

	if peek(musicEnabledState) then
		playMusic()
	end
end

return Radio
