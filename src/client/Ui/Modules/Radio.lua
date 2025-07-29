local Radio = {}

-- Services --
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

-- Folders --
local Shared = ReplicatedStorage.Shared

-- Modules --
local Ui = require(script.Parent.Parent.UiUtility)
local AssetsDealer = require(Shared.AssetsDealer)
local ClientInput = require(script.Parent.Parent.Parent.Input.ClientInput)
-- TODO: Use SoundManager
-- local SoundManager = require(Shared.Sound.SoundManager)

-- LocalPlayer --
local Player = Players.LocalPlayer
local PlayerGui = Player.PlayerGui

-- Gui elements --
local Gui = PlayerGui:WaitForChild("Radio")
local MainFrame = Gui:WaitForChild("MainFrame")
local Button = MainFrame:WaitForChild("Button")
local StatusLabel = MainFrame:WaitForChild("Status")

-- Constants --
local MUSIC_ENABLED_DEFAULT = true
local MUSIC_VOLUME = 0.2
local FADE_TIME = 5
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
}
local BUTTON_COLOR_ON = Color3.fromRGB(255, 255, 255) -- White for on
local BUTTON_COLOR_OFF = Color3.fromRGB(224, 47, 47) -- Red for off
local STATUS_COLOR_ON = Color3.fromRGB(255, 255, 255) -- White for on
local STATUS_COLOR_OFF = Color3.fromRGB(224, 47, 47) -- Red for off

-- Variables --
local musicEnabled = MUSIC_ENABLED_DEFAULT
local currentMusicSound = nil
local currentTrackIndex = 1
local Random = Random.new(os.clock())

-- Functions --
local function randomizeTrack()
	if #MUSIC_TRACKS > 1 then
		local newIndex = Random:NextInteger(1, #MUSIC_TRACKS)
		-- Ensure we don't pick the same track twice in a row
		while newIndex == currentTrackIndex do
			newIndex = Random:NextInteger(1, #MUSIC_TRACKS)
		end
		currentTrackIndex = newIndex
	end
end

local function updateButtonColor()
	Ui.UpdateToggleButtonColor(Button, musicEnabled, BUTTON_COLOR_ON, BUTTON_COLOR_OFF)
end

local function updateStatusLabel()
	if musicEnabled and MUSIC_TRACKS[currentTrackIndex] then
		StatusLabel.Text = "♪ Now Playing: " .. MUSIC_TRACKS[currentTrackIndex].displayName .. " ♪"
	else
		StatusLabel.Text = "♪ Music Off ♪"
	end

	-- Update status label color based on music state
	StatusLabel.TextColor3 = musicEnabled and STATUS_COLOR_ON or STATUS_COLOR_OFF
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
	if not musicEnabled then
		return
	end

	-- Stop any currently playing music with fade for smooth transitions
	stopCurrentMusicWithFade()

	-- Get the current track
	local currentTrack = MUSIC_TRACKS[currentTrackIndex]
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

		-- print("Now playing:", currentTrack.displayName)
		updateStatusLabel()
	else
		-- warn("Could not find music track:", currentTrack.directory)
	end
end

local function onButtonPressed()
	musicEnabled = not musicEnabled
	-- print("Music toggled:", musicEnabled and "ON" or "OFF")

	Ui.PlaySound("Click")
	updateButtonColor()
	updateStatusLabel()

	if musicEnabled then
		randomizeTrack() -- Randomize track when turning music back on
		playMusic()
	else
		stopCurrentMusicImmediately() -- No fade when turning off
	end
end

function Radio.Setup()
	-- Connect button press event
	Button.Activated:Connect(onButtonPressed)

	-- Set initial button color
	updateButtonColor()

	-- Hide status label on mobile devices
	StatusLabel.Visible = not ClientInput.IsMobile

	-- Randomize initial track selection
	randomizeTrack()

	-- Set initial status text
	updateStatusLabel()

	-- Set initial state and start music if enabled
	-- print("Radio module initialized. Music is", musicEnabled and "ON" or "OFF")

	if musicEnabled then
		playMusic()
	end
end

-- Public API --
function Radio.IsMusicEnabled()
	return musicEnabled
end

function Radio.SetMusicEnabled(enabled)
	if type(enabled) == "boolean" then
		musicEnabled = enabled
		-- print("Music set to:", musicEnabled and "ON" or "OFF")

		updateButtonColor()
		updateStatusLabel()

		if musicEnabled then
			randomizeTrack() -- Randomize track when turning music back on
			playMusic()
		else
			stopCurrentMusicImmediately() -- No fade when turning off
		end
	end
end

function Radio.ToggleMusic()
	onButtonPressed()
end

function Radio.NextTrack()
	if #MUSIC_TRACKS > 1 then
		currentTrackIndex = currentTrackIndex + 1
		if currentTrackIndex > #MUSIC_TRACKS then
			currentTrackIndex = 1
		end

		if musicEnabled then
			playMusic()
		else
			updateStatusLabel() -- Update status even if music is off
		end
	end
end

function Radio.PreviousTrack()
	if #MUSIC_TRACKS > 1 then
		currentTrackIndex = currentTrackIndex - 1
		if currentTrackIndex < 1 then
			currentTrackIndex = #MUSIC_TRACKS
		end

		if musicEnabled then
			playMusic()
		else
			updateStatusLabel() -- Update status even if music is off
		end
	end
end

function Radio.GetCurrentTrack()
	return MUSIC_TRACKS[currentTrackIndex]
end

function Radio.GetCurrentTrackName()
	return MUSIC_TRACKS[currentTrackIndex] and MUSIC_TRACKS[currentTrackIndex].displayName or "Unknown"
end

function Radio.SetVolume(volume)
	if type(volume) == "number" and volume >= 0 and volume <= 1 then
		if currentMusicSound then
			currentMusicSound.Volume = volume
		end
	end
end

return Radio
