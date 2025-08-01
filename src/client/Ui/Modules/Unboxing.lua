local Unboxing = {}

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local Shared = ReplicatedStorage.Shared

local AssetsDealer = require(Shared.AssetsDealer)

-- Modules
local Ui = require(script.Parent.Parent.UiUtility)
local BoxClass = require(script.Parent.Util.BoxClass)

-- Ui Elements 
local Gui = Ui.UnboxingGui
local MainFrame = Gui:WaitForChild("MainFrame") :: Frame
local FrontViewport = MainFrame:WaitForChild("FrontViewport") :: ViewportFrame
local BackViewport = MainFrame:WaitForChild("BackViewport") :: ViewportFrame
local Starburst = MainFrame:WaitForChild("Starburst") :: ImageLabel
local itemPreview = MainFrame:WaitForChild("ItemPreview") :: ImageLabel
itemPreview.Visible = true
itemPreview.Parent = script

function Unboxing.OpenLootbox(name)
    local ui = {MainFrame = MainFrame, FrontViewport = FrontViewport, BackViewport = BackViewport, Starburst = Starburst, itemPreview = itemPreview}
    local box = BoxClass.new(name,{},ui)

    
    task.spawn(function()
        task.wait(6)

        for i = 1,3 do
            box:pop()
            task.wait(2)
		end
		
		box:close()
    end)
end

function Unboxing.Setup()
    --Unboxing.OpenLootbox("RookieBox")
end

return Unboxing