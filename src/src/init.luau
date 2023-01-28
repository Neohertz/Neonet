--!strict

--[=[
    Entrypoint for Neonet
]=]
local RunService = game:GetService("RunService")

local Flags = {
    Lint = false
}

local Network = {}

setmetatable(Network, {
    __call = function(_, Flag)
        if Flag:lower() == "lint" then
            warn(`[Network] {RunService:IsClient() and "Client" or "Server"} Linting Enabled.`)
            Flags.Lint = true
        else
            warn(`[Network] Invalid Flag '{Flag}'`)
        end

        return Network
    end
})

--TODO: MOVE LINT MESSAGES TO THEIR OWN FILE

local Node = require(script.Node)
Node(Flags)

local BIN
local EventObjects: {[string]: Node.PublicInterface} = {} 

if RunService:IsServer() then
    BIN = Instance.new("Folder")
    BIN.Parent = game.ReplicatedStorage
    BIN.Name = "_Network"
else
    BIN = game.ReplicatedStorage:WaitForChild("_Network")
end

--FIX: Consider moving this to Node to contain linting.
local GlobalDoesModuleExist = Node.new(BIN, "__NEONET")

GlobalDoesModuleExist:OnAsked(function(_, Data)
    return EventObjects[Data] ~= nil
end)

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
    assert(BIN:WaitForChild(Name, 5) ~= nil, `[Network] Neonet:Fetch("{Name}") Coudln't find remote. Use Neonet.CreateNode("{Name}") to create it.`)

    if EventObjects[Name] == nil then
        EventObjects[Name] = Node.new(BIN, Name)
    end

    return EventObjects[Name] :: Node.PublicInterface
end

--[=[
    Create a new node and return it.

    @param Name Node Name
    @returns Node
]=]
function Network.CreateNode(Name: string) 
    assert(EventObjects[Name] == nil, `[Neonet] Node '{Name}' already exists. Use Neonet:Fetch("{Name}") to grab it.`)
    
    if Flags.Lint then
        local Find
        if RunService:IsServer() then
            Find = GlobalDoesModuleExist:Ask(game.Players:GetChildren()[1], Name)
        else
            Find = GlobalDoesModuleExist:Ask(Name)
        end

        if Find then
            warn(`[Neonet-Lint] [duplicate_node] {RunService:IsServer() and "SERVER" or "CLIENT"} found duplicate node '{Name}' found on {RunService:IsClient() and "SERVER" or "CLIENT"}. Consider calling Neonet:Fetch({Name}) or renaming it.`)
        end
    end
    
    EventObjects[Name] = Node.new(BIN, Name)
    return EventObjects[Name] :: Node.PublicInterface
end

return Network