--!strict

local Network = {}
Network.__index = Network

local RunService = game:GetService("RunService")


local Event = require(script.Event)

--> Types


--> Variables & Constants
local BIN
local EventObjects = {}


if RunService:IsServer() then
    BIN = Instance.new("Folder")
    BIN.Parent = game.ReplicatedStorage
    BIN.Name = "_Network"
else
    BIN = game.ReplicatedStorage:WaitForChild("_Network")
end

Network.AllClients = "AllClients"

--[=[
    Fetch a remote or bind the network. If one already exists, it will return said remote. If it doesn't it will try to instantiate one.
]=]
function Network:Fetch(Name: string)
    local Search = BIN:WaitForChild(Name, 5)
    assert(Search ~= nil, `[Network} :Fetch() Could not find remote '{Name}'. Did you create it?`)

    if EventObjects[Name] == nil then
        if Search:FindFirstChild("Event") then
            EventObjects[Name] = Event.new(BIN, Name, "Bind")
        else
            EventObjects[Name] = Event.new(BIN, Name, "Remote")
        end
    end

    return EventObjects[Name] :: Event.EventInterface
end

--[=[
    Create a new Bindable Event to use on the current host. (Client or Server)
]=]
function Network.CreateBind(BindName: string)
    assert(EventObjects[BindName] == nil, `[Network] Bind '{BindName}' already exists.`)

    EventObjects[BindName] = Event.new(BIN, BindName, "Bind")
    return EventObjects[BindName] :: Event.BindInterface
end

--[=[
    Create a new Event to be used for cross server communication.
]=]
function Network.CreateEvent(EventName: string)
    assert(RunService:IsServer(), `[Network] [{EventName}] Attempted to create a new event from the client.`)
    assert(EventObjects[EventName] == nil, `[Network] Event '{EventName}' already exists.`)

    EventObjects[EventName] = Event.new(BIN, EventName, "Remote")
    return EventObjects[EventName] :: Event.EventInterface
end

return Network