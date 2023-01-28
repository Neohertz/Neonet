--!strict

-- Another server script can ask and will recieve the state.

--[=[
    SERVER
]=]

local Network = require(game.ReplicatedStorage.neonet)
Network("lint")

local NumberOfCoins = Network.CreateNode("NumberOfCoins")
local Duplicate = Network.CreateNode("Duplicate")

game.Players.PlayerAdded:Connect(function(Player)
    print(NumberOfCoins:Ask(Player))
end)


