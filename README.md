## Neonet
A simplified networking solution for roblox game development.

---
## Usage

> Server Script 1
```lua
    local Neonet = require(path.to.neonet)

    local SayMessage = Neonet.CreateEvent("SayMessage")
    local GetCoins = Neonet.CreateEvent("GetCoins")
    local ServerMessage = Newonet.CreateBind("ServerMessage")

    local Coins = 10

    --> Listen for client ':Tell()' (Remote Events)
    SayMessage:OnTold():Connect(function(Player, Message)
        print `{Player} Says: {Message}`
    end)

    --> Listen for client questions (Remote Functions)
    GetCoins:OnAsk() = function(Player)
        return Coins
    end

    --> Listen for server ':Tell()' (Bindable Event)
    SayMessage:OnTold():Connect(function(Message)
        print `Script 2 Says: {Message}`
    end)
```
> Server Script 2
```lua
    local Neonet = require(path.to.neonet)

    --> Fetch ServerMessage
    local ServerMessage = Newonet:Fetch("ServerMessage")

    --> Tell Server1 Hello    
    ServerMessage:Tell("Hello!")
    
```
> Client
```lua
    local Neonet = require(path.to.neonet)

    --> Fetch GetCoins and SayMessage
    local SayMessage = Neonet:Fetch("SayMessage")
    local GetCoins = Neonet:Fetch("GetCoins")

    --> Tell the server hello
    SayMessage:Tell("Hello from the client!")
    
    --> Ask the server how many coins there are
    local Coins = GetCoins:Ask()
    print (`There are {Coins} Coins!`)
```
