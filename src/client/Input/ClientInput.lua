local ClientInput = {}

-- Services
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Modules
local Signal = require(ReplicatedStorage.Packages.signal)
ClientInput.Signal = Signal

-- Variables
ClientInput.HasMouse = UserInputService.MouseEnabled
ClientInput.HasKeyboard = UserInputService.KeyboardEnabled
ClientInput.HasTouch = UserInputService.TouchEnabled
ClientInput.HasGamepad = UserInputService.GamepadEnabled

-- Mobile detection
-- TODO: Decide if it makes sense to add `and not UserInputService.MouseEnabled`
ClientInput.IsMobile = UserInputService.TouchEnabled -- and not UserInputService.MouseEnabled
ClientInput.HoverEnabled = not ClientInput.IsMobile

-- Events
ClientInput.InputStarted = Signal.new()
ClientInput.FilteredInputStarted = Signal.new()
ClientInput.InputEnded = Signal.new()
ClientInput.FilteredInputEnded = Signal.new()

-- Functions
function ClientInput.IsHoverEnabled()
	return ClientInput.HoverEnabled
end

local function setupInputModules()
	for _, inputModule in script.Parent.InputModules:GetChildren() do
		local module = require(inputModule)
		if module and module.Init then
			module.Init()
		end
	end
end

function ClientInput.Setup()
	UserInputService.InputBegan:Connect(function(inputObject: InputObject, gameProcessedEvent: boolean)
		ClientInput.InputStarted:Fire(inputObject)
		if not gameProcessedEvent then
			ClientInput.FilteredInputStarted:Fire(inputObject)
		end
	end)

	setupInputModules()
end

return ClientInput
