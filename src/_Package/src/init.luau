--!strict

local Network = {}

local RunService = game:GetService("RunService")


local Node = require(script.Node)

local BIN
local EventObjects = {}

if RunService:IsServer() then
    BIN = Instance.new("Folder")
    BIN.Parent = game.ReplicatedStorage
    BIN.Name = "_Network"
else
    BIN = game.ReplicatedStorage:WaitForChild("_Network")
end

--[=[
    Flag for firing all clients. 

    Usage: Node:Tell(Neonet.AllClients, "Hello, Client!")

    @readonly
]=]
Network.AllClients = "AllClients"

--[=[
    Fetch a node the network. If one already exists, it will return said remote. If it doesn't it will try to instantiate one.

    @yeilds Up to 5 Seconds
    @returns Node
]=]
function Network:Fetch(Name: string) 
    local Search = BIN:WaitForChild(Name, 5)

    assert(Search ~= nil, `[Network} :Fetch() Could not find remote '{Name}'. Use Neonet.CreateNode({Name}) to create it.`)

    if EventObjects[Name] == nil then
        EventObjects[Name] = Node.new(BIN, Name)
    end

    return EventObjects[Name] :: Node.Interface
end

--[=[
    Create a new node and return it.

    @param Name Node Name
    @returns Node
]=]
function Network.CreateNode(Name: string) 
    assert(EventObjects[Name] == nil, `[Network] Node '{Name}' already exists. Use Neonet:Fetch({Name}) to grab it.`)
    EventObjects[Name] = Node.new(BIN, Name)
    return EventObjects[Name] :: Node.Interface
end

return Network