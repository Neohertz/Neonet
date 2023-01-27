--!strict

-- Another server script can ask and will recieve the state.

--[=[
    SERVER
]=]

local Network = require(game.ReplicatedStorage.neonet)
local Message = Network.CreateNode("Message")

local LastMsg = nil

-- Print the message to console
Message:OnTold(function(Player, Msg)
    LastMsg = Msg

    if Player then
        print (`{Player.Name} Says: {Msg}`)
    else
        print (`Server Says: {Msg}`)
    end
end)

-- Return the last recieved message
Message:OnAsked(function()
    return LastMsg
end)

-- Give server a message from the server.
Message:Tell("I am from the server!")

