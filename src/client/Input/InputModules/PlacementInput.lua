local PlacementInput = {}

local ClientInput = require(script.Parent.Parent.ClientInput)
local TappingInput = require(script.Parent.TappingInput)

PlacementInput.RotateEvent = ClientInput.Signal.new()
PlacementInput.CancelEvent = ClientInput.Signal.new()
PlacementInput.PlaceEvent = ClientInput.Signal.new()

function PlacementInput.Init()
    
    ClientInput.FilteredInputStarted:Connect(function(inputObject: InputObject)
        if ClientInput.HasKeyboard then
            if inputObject.KeyCode == Enum.KeyCode.R then
                PlacementInput.RotateEvent:Fire()
            elseif inputObject.KeyCode == Enum.KeyCode.Q then
                PlacementInput.CancelEvent:Fire()
            end
        end

        if ClientInput.HasGamepad then
            if inputObject.KeyCode == Enum.KeyCode.ButtonY then -- Right
                PlacementInput.RotateEvent:Fire()
            end
            if inputObject.KeyCode == Enum.KeyCode.ButtonB then -- Left
                PlacementInput.CancelEvent:Fire()
            end
            if inputObject.KeyCode == Enum.KeyCode.ButtonA then -- Bottom 
                PlacementInput.PlaceEvent:Fire()
            end
        end

        if ClientInput.HasTouch then
            TappingInput.DoubleTapEvent:Connect(function()
                PlacementInput.PlaceEvent:Fire()
            end)
        end
    end)
end

return PlacementInput