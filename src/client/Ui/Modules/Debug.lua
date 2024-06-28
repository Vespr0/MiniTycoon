local Debug = {}

-- Services --
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")

-- LocalPlayer --
local Player = Players.LocalPlayer
local PlayerGui = Player.PlayerGui

-- Gui elements --
local Gui = PlayerGui:WaitForChild("Debug")
local RefreshButton = Gui:WaitForChild("RefreshButton")
local MainFrame = Gui:WaitForChild("MainFrame")
local TemplateFrame = MainFrame:WaitForChild("TemplateFrame")
local TemplateLabel = TemplateFrame:WaitForChild("TemplateLabel")
local UIListLayout = MainFrame:WaitForChild("UIListLayout")
TemplateLabel.Parent = script
UIListLayout.Parent = script
TemplateFrame.Parent = script

-- Modules --
local ClientPlayerData = require(script.Parent.Parent.Parent.Data.ClientPlayerData)

-- Variables --
local labels = {}

-- Constants --
local TEMPLATE_LABEL_OFFSET = 30
local TEMPLATE_LABEL_BIAS = TEMPLATE_LABEL_OFFSET * 2
local TABLE_COLOR = Color3.fromRGB(47, 85, 47)

-- Functions --
local function maxWithOffset(value)
    return math.max(TEMPLATE_LABEL_OFFSET,value)
end

local function createGUI(data, parent)
    -- Clear previous UI elements from MainFrame except UIListLayout
    for _, v in pairs(MainFrame:GetChildren()) do
        v:Destroy()
    end

    -- Function to create GUI for nested data
    local function createNestedGUI(nestedData, parentElement)
        local nestedFrame
        local nestedLayout
        if parentElement == MainFrame then
            nestedFrame = TemplateFrame:Clone()
            nestedFrame.Size = UDim2.new(1, 0, 0, TEMPLATE_LABEL_OFFSET) -- Initially collapsed
            nestedFrame.Parent = parentElement

            nestedLayout = UIListLayout:Clone()
            nestedLayout.Parent = nestedFrame
        else
            nestedFrame = parentElement
            nestedLayout = parentElement:WaitForChild("UIListLayout")
        end

        for key, value in pairs(nestedData) do
            local isTable = type(value) == "table"

            local label = TemplateLabel:Clone()
            label.Parent = nestedFrame
            label.Text = isTable and tostring(key) or tostring(key).." : "..tostring(value)
            label.Name = label.Text
            label.Size = UDim2.new(1, 0, 0, TEMPLATE_LABEL_OFFSET)
            if parentElement ~= MainFrame then
                label.Visible = false
            end

            -- Check if value is a table (nested data)
            local toggleButton = label:WaitForChild("ToggleButton")
            if isTable then
                label.BackgroundTransparency = 0.5
                label.BackgroundColor3 = TABLE_COLOR
                toggleButton.Visible = true
                
                local nestedContentFrame = TemplateFrame:Clone()
                nestedContentFrame.Size = UDim2.new(1, 0, 0, 0) -- Initially collapsed
                nestedContentFrame.Parent = nestedFrame

                local nestedContentLayout = nestedLayout:Clone()
                nestedContentLayout.Parent = nestedContentFrame

                local isOpen = false
                local function switch(mode)
                    for _, v in pairs(nestedContentFrame:GetChildren()) do
                        if v:IsA("Frame") or v:IsA("TextLabel") then
                            v.Visible = mode
                        end
                    end
                    nestedContentFrame.Visible = mode
                    toggleButton.Text = mode and "-" or "+"
                    -- Adjust the size of the parent frame accordingly
                    nestedContentFrame.Size = UDim2.new(1, 0, 0, maxWithOffset(nestedContentLayout.AbsoluteContentSize.Y))
                    nestedFrame.Size = UDim2.new(1, 0, 0, maxWithOffset(nestedLayout.AbsoluteContentSize.Y))
                end

                toggleButton.MouseButton1Click:Connect(function()
                    isOpen = not isOpen
                    switch(isOpen)
                end)
                switch(isOpen)
                
                -- Create nested GUI recursively
                createNestedGUI(value, nestedContentFrame)
            else
                toggleButton.Visible = false
            end
        end

        nestedFrame.Size = UDim2.new(1, 0, 0, maxWithOffset(nestedLayout.AbsoluteContentSize.Y))
    end

    -- Create UI elements based on data
    if type(data) == "table" then
        createNestedGUI(data, MainFrame)
    else
        error("Invalid data type. Expected table (array or dictionary).")
    end

    -- Return the GUI instance if it was created
    if not parent then
        return MainFrame
    end
end


local function update()
    local clientData = ClientPlayerData.Get()

    createGUI(clientData)
end

function Debug.Setup()
    --RunService.Heartbeat:Connect(update)
    RefreshButton.MouseButton1Click:Connect(update)
    update()
end

return Debug