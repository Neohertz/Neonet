--[=[
    @class Event Class
]=]
local Event = {}
Event.__index = Event

local RunService = game:GetService("RunService")

export type Interface = {
    Tell: (self: Interface, ...any) -> nil,
    OnTold: <Callback>(self: Interface, Callback: (...any) -> any) -> any,
    Ask: (self: Interface, ...any) -> nil,
    OnAsked: <Callback>(self: Interface, Callback: (...any) -> any) -> any,
} 

--[=[
    Internal Overrides
]=]
local _assert = assert
local _warn = warn
local function assert(Condition: boolean, Message: string)
    _assert(Condition, `[Neonet] ({RunService:IsClient() and "Client" or "Server"}) {Message}`)
end

local function warn(Message: string)
   _warn(`[Neonet] ({RunService:IsClient() and "Client" or "Server"}) {Message}`) 
end

--[=[
    Helper Functions
]=]
local function Create (Type: any, Parent: any)
    local Remote = Instance.new(Type)
    Remote.Parent = Parent
    return Remote
end

-- API --

--[=[
    Check to see if the node's host and the current host are the same.

    @private
    @returns boolean
]=]
function Event:IsSameScope() : boolean
    return self.CreatedOnServer == RunService:IsServer()
end

--[=[
    Listen for questions from the current host and across the boundary.

    Anything returned by this value will be sent back the the script that asked.

    @param Callback (...any) -> any
    @returns nil
]=]
function Event:OnAsked(Callback:(...any) -> any)
    assert(self ~= nil, "OnAsked() should be invoked with a ':', not a '.'")

    assert(not self.InvokeSet, `[Node: {self.Name}] Attempted to set :OnAsked() callback more than once.`)
    --assert(self.Type == "Remote", `[Node: {self.Name}] Attempted to set :OnAsked() callback on an Bind. Try changing this to a Event.`)
    assert(self.Container ~= nil, `[Node: {self.Name}] OnAsk() Couldn't Find Remote. Are you sure you used :Register()?`)
    local RemoteFunction = self.Container:FindFirstChild("RemoteFunction") :: RemoteFunction
    local BindableFunction = self.Container:FindFirstChild("Function") :: BindableFunction

    if BindableFunction then
        BindableFunction.OnInvoke = Callback
    end

    if RemoteFunction then
        if RunService:IsClient() then
            RemoteFunction.OnClientInvoke = Callback
        else
            RemoteFunction.OnServerInvoke = Callback
        end
    end

    self.InvokeSet = true
end

--[=[
    Ask the node a question and await a response. 

    [Server] If the first argument is a Player, then it will invoke that client within a pcall. If this fails, the function will return nil. 
    
    @param Arg1 arg1 or player
    @param Arguments tuple 
    @yeilds
    @returns Result or nil
]=]
function Event:Ask(...: any) : any
    assert(self ~= nil, "Ask() should be invoked with a ':', not a '.'")
    assert(self.Container ~= nil, `Ask() Couldn't Find '{self.Name}'. Are you sure you used :Register()?`)

    local Package = table.pack(...)
    local PlayerCheck = game.Players:FindFirstChild(tostring(Package[1]))
    local RemoteFunction = self.Container:FindFirstChild("RemoteFunction") :: RemoteFunction
    local BindableFunction = self.Container:FindFirstChild("Function") :: BindableFunction

    if PlayerCheck ~= nil then
        assert(RunService:IsServer(), `[Node: {self.Name}] :Ask() called with Player '{PlayerCheck}' as first argument, but we are on the client.`)
    end

    if self:IsSameScope() and PlayerCheck == nil then
        if RunService:IsServer() then
            return BindableFunction:Invoke(nil, table.unpack(Package))
        else
            return BindableFunction:Invoke(table.unpack(Package))
        end
    end

    assert(not (RunService:IsServer() and PlayerCheck == nil), `[Node: {self.Name}] Attempted to call :Ask() without a player as the first argument.`)

    if PlayerCheck ~= nil then        
        local Success, Result = pcall(function()
            return RemoteFunction:InvokeClient(table.unpack(Package))
        end)
        
        if Success then
            return Result
        else
            warn (`[Node: {self.Name}] On call, :Ask() encountered an issue attempting to invoke the client. This method will return nil.`)
            warn(Result)
            return nil
        end
    else
        return RemoteFunction:InvokeServer(table.unpack(Package))
    end
end

--[=[
    Send a message throughout the node for any listener to recieve.

    [Server] If the first argument is a Player, then it will invoke that client within a pcall. If this fails, the function will return nil. 

    @param Reciever Player (Optional)
    @param Arguments tuple
]=]
function Event:Tell(...)
    assert(self ~= nil, "Tell() should be invoked with a ':', not a '.'")
    assert(self.Container ~= nil, `Tell() called, but node '{self.Name}' doesn't exist. Are you sure you used Neonet.CreateNode("{self.Name}")?`)

    local Bind = self.Container:FindFirstChild("Event") :: BindableEvent
    local RemoteEvent = self.Container:FindFirstChild("RemoteEvent") :: RemoteEvent
    local PlayerCheck = game.Players:FindFirstChild(tostring(table.pack(...)[1]))

    if PlayerCheck ~= nil then
        assert(RunService:IsServer(), `[Node: {self.Name}] :Tell() called with Player '{PlayerCheck}' as first argument, but we are on the client.`)
    end

    if self:IsSameScope() and PlayerCheck == nil then
        if RunService:IsServer() then
            Bind:Fire(nil, ...)
        else
            Bind:Fire(...)
        end
        return
    end

    -- If our request contains a player, then shoot it at the client as well.
    if table.pack(...)[1] == "AllClients" then
        RemoteEvent:FireAllClients(select(2, ...))
    elseif PlayerCheck then
        RemoteEvent:FireClient(PlayerCheck, select(2, ...))
    else
        RemoteEvent:FireServer(...)
    end
end

--[=[
    Bind a callback to listen for ":Tell()" on this specific node.

    @param Callback (...any) -> any
    @returns nil
]=]
function Event:OnTold(Callback: (...any) -> any)
    assert(self ~= nil, "OnTold() should be invoked with a ':', not a '.'")
    assert(self.Container ~= nil, `OnTold() attempted, but node '{self.Name}' doesn't exist. Are you sure you used Neonet.CreateNode("{self.Name}")?`)

    local RemoteEvent = self.Container:FindFirstChild("RemoteEvent") :: RemoteEvent
    local BindableEvent = self.Container:FindFirstChild("Event") :: BindableEvent

    if RunService:IsServer() and RemoteEvent then
        table.insert(self.Connections, RemoteEvent.OnServerEvent:Connect(Callback))
    elseif RunService:IsClient() and RemoteEvent then
        table.insert(self.Connections, RemoteEvent.OnClientEvent:Connect(Callback))
    end

    table.insert(self.Connections, BindableEvent.Event:Connect(Callback))
end

--[=[
    Create a new Event Instance.

    @returns EventObject
]=]
function Event.new(BIN: Folder, Name: string)
    local Container = BIN:FindFirstChild(Name)
    local CreatedOnServer = true

    if not Container then
        CreatedOnServer = RunService:IsServer()
        Container = Instance.new("Folder")
        Container.Parent = BIN
        Container.Name = Name

        if RunService:IsServer() then
            Create("RemoteEvent", Container)
            Create("RemoteFunction", Container)
        end

        Create("BindableEvent", Container)
        Create("BindableFunction", Container)
    end

    return setmetatable({
        Name = Name,
        Connections = {},
        InvokeSet = false,
        CreatedOnServer = CreatedOnServer,
        Container = Container,
        BIN = BIN
    }, Event)
end

return Event 