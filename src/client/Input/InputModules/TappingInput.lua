local TappingInput = {}

local ClientInput = require(script.Parent.Parent.ClientInput)

TappingInput.DoubleTapEvent = ClientInput.Signal.new()

local lastTapTime = 0
local doubleTapThreshold = 0.3 -- seconds

function TappingInput.Init()
    ClientInput.FilteredInputStarted:Connect(function(inputObject: InputObject)
        if inputObject.UserInputType == Enum.UserInputType.Touch then
            local currentTime = os.clock()
            if currentTime - lastTapTime <= doubleTapThreshold then
                warn("double tap!")
                TappingInput.DoubleTapEvent:Fire(inputObject.Position)
            end
            lastTapTime = currentTime
        end
    end)
end

return TappingInput