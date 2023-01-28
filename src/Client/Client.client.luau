
local Network = require(game.ReplicatedStorage.neonet)
Network('lint')

local NumberOfCoins = Network:Fetch("NumberOfCoins")
local Duplicate = Network.CreateNode("Duplicate")

NumberOfCoins:OnAsked(function()
    return 1
end)

