
local Network = require(game.ReplicatedStorage.neonet)
Network("lint")

local NumberOfCoins = Network.CreateNode("NumberOfCoins")
local Duplicate = Network.CreateNode("Duplicate")

NumberOfCoins:OnTold(function(Player, Msg)
    print (Player, Msg)
end)

task.wait(5)

NumberOfCoins:Tell(game.Players.frriend, "hi")

