--[=[
    @class Event Class
]=]
local Event = {} :: BindInterface & EventInterface
Event.__index = Event

local RunService = game:GetService("RunService")

export type BindInterface = {
    Tell: (self: BindInterface, ...any) -> any,
    OnTold: (self: BindInterface, ...any) -> RBXScriptSignal,
} 

export type EventInterface = {
    Tell: (self: BindInterface, ...any) -> any,
    OnTold: (self: BindInterface, ...any) -> RBXScriptSignal,
    Ask: (self: EventInterface, ...any) -> any,
    OnAsked: (self: EventInterface, Callback: (any) -> any) -> any
} 

--[=[
    Set a callback function to the 
]=]
function Event:OnAsked(Callback:(...any) -> any)
    assert(not self.InvokeSet, `[Network] [Name: {self.Name}] Attempted to set :OnAsked() callback more than once.`)
    assert(self.Type == "Remote", `[Network] [Name: {self.Name}] Attempted to set :OnAsked() callback on an Bind. Try changing this to a Event.`)
    assert(self.Container ~= nil, `[Network] [Name: {self.Name}] OnAsk() Couldn't Find Remote. Are you sure you used :Register()?`)
    local RemoteFunction = self.Container:FindFirstChild("RemoteFunction") :: RemoteFunction

    if RunService:IsClient() then
        RemoteFunction.OnClientInvoke = Callback
    else
        RemoteFunction.OnServerInvoke = Callback
    end

    self.InvokeSet = true
end

--[=[
    Ask the server a question and await a response. 

    If the first argument is a Player, then it will invoke that client within a pcall. If this fails, the function will return nil. 
    
    @param Arg1 arg1 or player
    @param Arguments tuple 
    @yeilds
    @returns Result or nil
]=]
function Event:Ask(...: any) : any
    assert(self.Type == "Remote", `[Network] [Name: {self.Name}] Attempted to call :Ask() on an Bind.`)
    assert(self.Container ~= nil, `[Network] Ask() Couldn't Find '{self.Name}'. Are you sure you used :Register()?`)

    local Package = (...)
    local PlayerCheck = game.Players:FindFirstChild(tostring(table.pack(Package)[1]))
    local RemoteFunction = self.Container:FindFirstChild("RemoteFunction") :: RemoteFunction

    assert(not (RunService:IsServer() and PlayerCheck == nil), `[Network] [Name: {self.Name}] Attempted to call :Ask() without a player as the first argument.`)

    if game.Players:FindFirstChild(tostring(PlayerCheck)) then
        local Success, Result = pcall(function()
            return RemoteFunction:InvokeClient(Package)
        end)
        
        if Success then
            return Result
        else
            warn (`[Network] [Name: {self.Name}] On call, :Ask() encountered an issue attempting to invoke the client. This method will return nil.`)
            return nil
        end
    else
        return RemoteFunction:InvokeServer(...)
    end
end

--[=[
    Tell a message to every listener throughout the network. If the remote is a bind, only the current host will recieve the signal.

    @param Reciever Player (Optional)
    @param Arguments tuple
]=]
function Event:Tell(...)
    assert(self.Container ~= nil, `[Network] [Name: {self.Name}] Tell() Couldn't Find Remote. Are you sure you used :Register()?`)

    local Bind = self.Container:FindFirstChild("Event") :: BindableEvent
    local RemoteEvent = self.Container:FindFirstChild("RemoteEvent") :: RemoteEvent

    if Bind then
        Bind:Fire(...)

        if self.Container:FindFirstChild("RemoteEvent") then
            RemoteEvent:FireServer()
        end
    else
        -- If our request contains a player, then shoot it at the client as well.

        local PlayerCheck = table.pack(...)[1]
        if PlayerCheck == "AllClients" then
            RemoteEvent:FireAllClients(select(2, ...))
        elseif game.Players:FindFirstChild(tostring(PlayerCheck[1])) then
            RemoteEvent:FireClient(PlayerCheck[1], select(2, ...))
        else
            RemoteEvent:FireServer(...)
        end
    end
end

--[=[
    Return the RBXScriptSignal of the remote event or bind.

    @returns RBXScriptSignal
]=]
function Event:OnTold() : RBXScriptSignal
    assert(self.Container ~= nil, `[Network] [Name: {self.Name}] OnTold() Couldn't Find remote or bind. Are you sure you created it?`)

    local RemoteEvent = self.Container:FindFirstChild("RemoteEvent") :: RemoteEvent
    local Bindable = self.Container:FindFirstChild("Event") :: BindableEvent

    return RemoteEvent 
        and (RunService:IsServer() and RemoteEvent.OnServerEvent or RemoteEvent.OnClientEvent) 
        or Bindable and Bindable.Event
end

local function Create (Type: any, Parent: any)
    local Remote = Instance.new(Type)
    Remote.Parent = Parent
    return Remote
end

--[=[
    Create a new Event Instance.

    @returns EventObject
]=]
function Event.new(BIN: Folder, Name: string, Type: string)
    local Container = BIN:FindFirstChild(Name)

    if not Container then
        Container = Instance.new("Folder")
        Container.Parent = BIN
        Container.Name = Name

        if RunService:IsClient() or Type == "Bind" then
            Create("BindableEvent", Container)
        elseif Type == "Remote" then
            Create("RemoteEvent", Container)
            Create("RemoteFunction", Container)
        end
    end

    return setmetatable({
        Name = Name,
        InvokeSet = false,
        Container = Container,
        Type = Type,
        BIN = BIN
    }, Event)
end

return Event 