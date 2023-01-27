--[=[
    CLIENT
]=]

local Network = require(game.ReplicatedStorage.neonet)

local Message = Network:Fetch("Message")


-- Give server a message from the client.
Message:Tell("I am from the client!")

-- Print the last message recieved
print(`Last Message: {Message:Ask()}`)

