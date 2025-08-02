local ClientConch = {}

-- Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Modules
local conch = require(ReplicatedStorage.Packages.conch)
local ui = require(ReplicatedStorage.Packages["conch-ui"])

function ClientConch.Setup()
    conch.initiate_default_lifecycle()
    ui.bind_to(Enum.KeyCode.F4)
end

return ClientConch
