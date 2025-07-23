local PlacementInput = {}

local ClientInput = require(script.Parent.Parent.ClientInput)
local TappingInput = require(script.Parent.TappingInput)

PlacementInput.SelectEvent = ClientInput.Signal.new()
PlacementInput.MoveEvent = ClientInput.Signal.new()
PlacementInput.StoreEvent = ClientInput.Signal.new()

function PlacementInput.Init()
    
    ClientInput.FilteredInputStarted:Connect(function(inputObject: InputObject)
        if ClientInput.HasKeyboard then
            if inputObject.KeyCode == Enum.KeyCode.V then
                PlacementInput.MoveEvent:Fire()
            elseif inputObject.KeyCode == Enum.KeyCode.B then
                PlacementInput.StoreEvent:Fire()
            end
        end

        if ClientInput.HasGamepad then
            if inputObject.KeyCode == Enum.KeyCode.ButtonY then -- Right
                PlacementInput.MoveEvent:Fire()
            end
            if inputObject.KeyCode == Enum.KeyCode.ButtonB then -- Left
                PlacementInput.StoreEvent:Fire()
            end
            if inputObject.KeyCode == Enum.KeyCode.ButtonA then -- Bottom 
                PlacementInput.SelectEvent:Fire()
            end
        end

        if ClientInput.HasMouse then
            if inputObject.UserInputType == Enum.UserInputType.MouseButton1 then
                PlacementInput.SelectEvent:Fire()
            end
        end
    end)

    TappingInput.DoubleTapEvent:Connect(function()
        PlacementInput.SelectEvent:Fire()
    end)
end

return PlacementInput