

--[=[
    @class Node Class
]=]
local Node = {} :: Interface
Node.__index = Node

local Flags = {
    Lint = false
}

setmetatable(Node, {
    __call = function(_, _Flags)
        Flags = _Flags
    end
})

local RunService = game:GetService("RunService")

type Interface = {
    Tell: (self: Interface, ...any) -> nil,
    OnTold: (self: Interface, Callback: (...any) -> any) -> nil,
    Ask: (self: Interface, ...any) -> nil,
    OnAsked: (self: Interface, Callback: (...any) -> any) -> nil,
    new: (BIN: Folder, Name: string) -> Interface,
    Name: string,
    Connections: {[number]: RBXScriptConnection},
    InvokeSet: boolean,
    CreatedOnServer: boolean,
    Container: any,
    BIN: any,

    Kill: (self: Interface) -> any,
    IsSameScope: (self: Interface) -> boolean,
    __index: Interface
}

export type PublicInterface = {
    Tell: (self: PublicInterface, ...any) -> nil,
    OnTold: (self: PublicInterface, Callback: (...any) -> any) -> nil,
    Ask: (self: PublicInterface, ...any) -> nil,
    OnAsked: (self: PublicInterface, Callback: (...any) -> any) -> nil,
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
function Node:IsSameScope() : boolean
    return self.CreatedOnServer == RunService:IsServer()
end

--[=[
    Listen for questions from the current host and across the boundary.

    Anything returned by said callback will be sent back the the script that asked.

    @param Callback (...any) -> any
    @returns nil
]=]
function Node:OnAsked(Callback:(...any) -> any)
    assert(self.Name ~= nil, `{self.Name}:OnAsked() should be invoked with a ':', not a '.'`)
    assert(not self.InvokeSet, `Attempted to set {self.Name}:OnAsked() callback more than once.`)
    assert(self.Container ~= nil, `{self.Name}:OnAsk() Couldn't Find Remote. Are you sure you used Neonet.CreateNode({self.Name})?`)

    local RemoteFunction = self.Container:FindFirstChild("RemoteFunction") :: RemoteFunction
    local BindableFunction = self.Container:FindFirstChild("Function") :: BindableFunction

    -- If there is a bindable function called, ensure that it is binded to the callback.
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

    return
end

--[=[
    Ask the node a question and await a response. 

    [Server] If the first argument is a Player, then it will invoke that client within a pcall. If this fails, the function will return nil. 
    
    @param Arg1 arg1 or player
    @param Arguments tuple 
    @yeilds
    @returns Result or nil
]=]
function Node:Ask(...: any) : any
    assert(self.Name ~= nil, `{self.Name}:Ask() should be invoked with a ':', not a '.'`)
    assert(self.Container ~= nil, `{self.Name}:Ask() Couldn't Find Remote. Are you sure you used Neonet.CreateNode("{self.Name}")?`)

    local Package = table.pack(...)
    local PlayerCheck = game.Players:FindFirstChild(tostring(Package[1]))
    local RemoteFunction = self.Container:FindFirstChild("RemoteFunction") :: RemoteFunction
    local BindableFunction = self.Container:FindFirstChild("Function") :: BindableFunction

    if PlayerCheck ~= nil then
        assert(RunService:IsServer(), `{self.Name}:Ask() called with Player '{PlayerCheck}' as first argument, but we are on the client.`)
    end

    -- If we are within the same scope with no player argument given, invoke the bindable and return its result.
    if self:IsSameScope() and PlayerCheck == nil then
        if RunService:IsServer() then
            return BindableFunction:Invoke(nil, table.unpack(Package))
        else
            return BindableFunction:Invoke(table.unpack(Package))
        end
    end

    -- Ensure player argument is present if we are invoking the client from the server.
    assert(not (RunService:IsServer() and PlayerCheck == nil), `Attempted to call {self.Name}:Ask() without a player as the first argument.`)

    -- If we are trying to invoke the client, do it in a pcall to prevent network issues.
    if PlayerCheck ~= nil then    
        if Flags.Lint then
            _warn(`[Neonet-Lint] [invoked-client] Invoking the client with {self.Name}:Ask({tostring(PlayerCheck)}) is inherently dangerous. Ensure that you aren't trusting the client with any information.`)
        end
        
        local Success, Result = pcall(function()
            return RemoteFunction:InvokeClient(table.unpack(Package))
        end)
        
        if Success then
            return Result
        else
            warn (`On call, {self.Name}:Ask() encountered an issue attempting to invoke the client. This method will return nil.`)
            warn(Result)
            return nil
        end
    else
        return RemoteFunction:InvokeServer(table.unpack(Package))
    end
end

--[=[
    Send a message throughout the node for any listener to recieve.

    [Server] To send to every client, use the Neonet.AllPlayers global.

    @param Reciever Player (Optional)
    @param Arguments tuple
]=]
function Node:Tell(...)
    assert(self.Name ~= nil, `{self.Name}:Tell() should be invoked with a ':', not a '.'`)
    assert(self.Container ~= nil, `{self.Name}:Tell() called, but node '{self.Name}' doesn't exist. Are you sure you used Neonet.CreateNode("{self.Name}")?`)

    local Bind = self.Container:FindFirstChild("Event") :: BindableEvent
    local RemoteEvent = self.Container:FindFirstChild("RemoteEvent") :: RemoteEvent
    local PlayerCheck = game.Players:FindFirstChild(tostring(table.pack(...)[1]))

    -- Ensure that we arent attempting to fire to player from the client.
    if PlayerCheck ~= nil then
        assert(RunService:IsServer(), `{self.Name}:Tell() called with Player '{PlayerCheck}' as first argument, but we are on the client.`)
    end

    -- If our scope is the same, and the first argument is not a player, fire the bindable event.
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

    return
end

--[=[
    Bind a callback to listen for ":Tell()" on this specific node.

    @param Callback (...any) -> any
    @returns nil
]=]
function Node:OnTold(Callback: (...any) -> any)
    assert(self.Name ~= nil, `{self.Name}:OnTold() should be invoked with a ':', not a '.'`)
    assert(self.Container ~= nil, `{self.Name}:OnTold() attempted, but node '{self.Name}' doesn't exist. Are you sure you used Neonet.CreateNode("{self.Name}")?`)

    local RemoteEvent = self.Container:FindFirstChild("RemoteEvent") :: RemoteEvent
    local BindableEvent = self.Container:FindFirstChild("Event") :: BindableEvent

    if RunService:IsServer() and RemoteEvent then
        table.insert(self.Connections, RemoteEvent.OnServerEvent:Connect(Callback))
    elseif RunService:IsClient() and RemoteEvent then
        table.insert(self.Connections, RemoteEvent.OnClientEvent:Connect(Callback))
    end

    table.insert(self.Connections, BindableEvent.Event:Connect(Callback))

    return
end

--[=[
    Create a new Event Instance.

    @returns EventObject
]=]
function Node.new(BIN: Folder, Name: string) 
    local Container = BIN:FindFirstChild(Name)
    local CreatedOnServer = true

    if not Container then
        CreatedOnServer = RunService:IsServer()
        local NewContainer = Instance.new("Folder")
        NewContainer.Parent = BIN
        NewContainer.Name = Name

        -- Remote Events and Functions are only accessable serverside.
        if RunService:IsServer() then
            Create("RemoteEvent", NewContainer)
            Create("RemoteFunction", NewContainer)
        end

        Create("BindableEvent", NewContainer)
        Create("BindableFunction", NewContainer)

        NewContainer:SetAttribute("Server", RunService:IsServer())
        Container = NewContainer
    end

    local Meta = setmetatable({
        Name = Name,
        Connections = {},
        InvokeSet = false,
        CreatedOnServer = CreatedOnServer,
        Container = Container,
        BIN = BIN
    }, Node) 
    
    return Meta :: Interface
end 

--[=[
    Purge the node for any reason. Disconnects all connections and removes the container.

    Due to the way nodes work, this will only remove the current host's instance. (server or client)

    This should only be used internally.

    @private
]=]
function Node:Kill()

    for _, Connection in ipairs(self.Connections) do
        Connection:Disconnect()
    end

    if self.Container then
        self.Container.Parent = nil
        self.Container:Destroy()
    end
    self.Name = "DEAD"

    return
end


return Node