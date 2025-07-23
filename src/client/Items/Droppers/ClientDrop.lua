local ClientDrop = {}
ClientDrop.__index = ClientDrop

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local Shared = ReplicatedStorage.Shared
local Events = ReplicatedStorage.Events
local Packages = ReplicatedStorage.Packages

local AssetsDealer = require(Shared.AssetsDealer)
local ItemUtility = require(Shared.Items.ItemUtility)
local DropUtil = require(Shared.Items.Droppers.DropUtil)
local _SoundManager = require(Shared.Sound.SoundManager)
local FXManager = require(script.Parent.Parent.Parent.FX.FXManager)
local _Signal = require(Packages.signal)
local CashUtility = require(Shared.Utility.CashUtility)

function ClientDrop.new(properties,params)
    local drop = setmetatable({}, ClientDrop)
    -- Instance --
    drop.instance = params.instance
    --drop.instance.Transparency = 1
    drop.plot = params.plot
    drop.localID = params.localID
    drop.partID = params.partID
    drop.properties = properties

    -- Mesh --
    drop.mesh = AssetsDealer.GetMesh(properties.mesh)
    drop.mesh.Parent = workspace
    drop.mesh.Name = "Mesh"
    drop.mesh.Size = Vector3.one/100
    drop.mesh.Color = drop.instance.Color

    drop.mesh.CanCollide = false
    drop.mesh.CanQuery = false
    drop.mesh.CanTouch = false
    drop.mesh.Massless = true 
    drop.mesh.Anchored = true

    drop.tweenDelay = 0.1

    drop.mesh.CFrame = drop.instance.CFrame

    -- Client-side upgrader tracking
    drop.boosts = {}
    drop.steps = 0

    -- Debug cash display
    print(AssetsDealer,AssetsDealer.GetUi)
    drop.cashDisplay = AssetsDealer.GetUi("Misc/CashDisplay")
    drop.cashDisplay.Parent = drop.mesh
    drop:updateCashDisplay()
    print(drop.cashDisplay)

    drop:grow()
    drop.connection = RunService.RenderStepped:Connect(function()
        local partExists = drop.instance and drop.instance.Parent
        local meshExists = drop.mesh and drop.mesh.Parent
        if partExists and meshExists and not drop.instance.Anchored then
            drop.steps += 1
            drop:step()
        else
            drop:fade()
        end
    end)

    drop.soldConnection = Events.DropReplication.OnClientEvent:Connect(function(ownerID,localID,partID,sold,forgeName)
        if ownerID ~= drop.plot:GetAttribute("OwnerID") then return end

        if sold then
            if partID ~= drop.partID then return end

            drop:sell(forgeName)
            return
        end
    end)

    return drop
end

function ClientDrop:getValue()
    local value = self.properties.value 
    for _,boost in pairs(self.boosts) do
        value = DropUtil.CalculateBoost(value, boost.type, boost.value)
    end
    return value
end

function ClientDrop:updateCashDisplay()
    self.cashDisplay.Label.Text = CashUtility.Format(self:getValue())
end

function ClientDrop:sell(forgeName)
    local config = ItemUtility.GetItemConfig(forgeName)

    local size = self.mesh.Size
    local color = config.SmeltEffect.Color

    FXManager.Smelt({instance = self.mesh, size = size, color = color})
    task.wait(2.5)

    self:destroy()
end

function ClientDrop:fade()
    FXManager.Fade({Instance = self.mesh,Time = 2})
    task.wait(2)
    self:destroy()
end

function ClientDrop:destroy()
    self.connection:Disconnect()
    self.soldConnection:Disconnect()
    self.mesh:Destroy()
end

function ClientDrop:grow()
    TweenService:Create(self.mesh,TweenInfo.new(math.min(.6,self.instance.Size.Magnitude),Enum.EasingStyle.Sine),{
        Size = self.instance.Size
    }):Play()
end

function ClientDrop:getUpgrader()
    local newBoosts = DropUtil.ProcessUpgraders(self.instance, self.plot, self.boosts)
    
    -- Apply new boosts and trigger visual effects
    for localID, boost in pairs(newBoosts) do
        self.boosts[localID] = boost
        -- TODO: Add visual effects here based on boost
    end
    self:updateCashDisplay()
end

function ClientDrop:step()
    self.mesh.CFrame = self.instance.CFrame
    
    -- Check for upgraders every few steps (similar to server)
    if (self.steps % 2 == 0) then
        self:getUpgrader()
    end
    
    -- TweenService:Create(self.mesh,TweenInfo.new(self.tweenDelay,Enum.EasingStyle.Linear),{
    --     CFrame = self.instance.CFrame    
    -- }):Play()
end

return ClientDrop