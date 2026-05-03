local Config = getgenv().AVConfig
local State = getgenv().AVState
local Rayfield = getgenv().AshlyRayfield

local FarmUtils = getgenv().AVFarmUtils
local ESPUtils = getgenv().AVESPUtils

local Players = game:GetService("Players")
local Player = Players.LocalPlayer
local Mouse = Player:GetMouse()
local HttpService = game:GetService("HttpService")

local function notify(title, content, duration)
    Rayfield:Notify({Title = title, Content = content, Duration = duration or 5})
end

-- Create the main window layout using the existing Rayfield instance
local Window = Rayfield:CreateWindow({
    Name = "Anime Vanguards",
    LoadingTitle = "Anime Vanguards Script",
    LoadingSubtitle = "by HackerAI",
    Theme = "Default",
    ToggleUIKeybind = "K",
    ConfigurationSaving = {Enabled = false},
    KeySystem = false
})

-- Main Tab
local MainTab = Window:CreateTab("Main", "sword")
local FarmSection = MainTab:CreateSection("Farming")

FarmSection:CreateToggle({
    Name = "Auto Farm",
    CurrentValue = false,
    Flag = "AutoFarm",
    Callback = function(v)
        Config.AutoFarm = v
        if v then coroutine.wrap(FarmUtils.AutoFarmLoop)() end
    end
})

FarmSection:CreateToggle({Name = "Auto Place Units", CurrentValue = false, Flag = "AutoPlace", Callback = function(v) Config.AutoPlace = v end})
FarmSection:CreateToggle({Name = "Auto Upgrade", CurrentValue = false, Flag = "AutoUpgrade", Callback = function(v) Config.AutoUpgrade = v end})
FarmSection:CreateToggle({Name = "Auto Retry", CurrentValue = false, Flag = "AutoRetry", Callback = function(v) Config.AutoRetry = v end})
FarmSection:CreateToggle({Name = "Auto Next Stage", CurrentValue = false, Flag = "AutoNext", Callback = function(v) Config.AutoNext = v end})
FarmSection:CreateToggle({Name = "Auto Collect Rewards", CurrentValue = false, Flag = "AutoCollect", Callback = function(v) Config.AutoCollect = v end})

FarmSection:CreateToggle({
    Name = "Anti AFK",
    CurrentValue = false,
    Flag = "AntiAFK",
    Callback = function(v)
        Config.AntiAFK = v
        if v then coroutine.wrap(FarmUtils.AntiAFKLoop)() end
    end
})

MainTab:CreateSection("Position Settings")

for i = 1, 6 do
    MainTab:CreateButton({
        Name = "Set Position for Slot " .. i,
        Callback = function()
            notify("Position " .. i, "Click on the ground to set place position for Slot " .. i, 3)
            local con
            con = Mouse.Button1Down:Connect(function()
                if not Config.PlacePositions then Config.PlacePositions = {} end
                Config.PlacePositions[i] = Mouse.Hit.p
                notify("Position " .. i .. " Set", "Slot " .. i .. " position saved: " .. tostring(Config.PlacePositions[i]), 3)
                con:Disconnect()
            end)
        end
    end)
end

-- Summon Tab
local SummonTab = Window:CreateTab("Summon", "package")
SummonTab:CreateSection("Auto Summon")

SummonTab:CreateDropdown({
    Name = "Summon Mode",
    Options = {"1x Summon", "10x Summon"},
    CurrentOption = "1x Summon",
    Flag = "SummonMode",
    Callback = function(v) Config.SummonMode = (v == "1x Summon") and 1 or 10 end
})

SummonTab:CreateSlider({
    Name = "Summon Delay (seconds)",
    Range = {0.5, 30},
    Increment = 0.5,
    Suffix = "s",
    CurrentValue = 1,
    Flag = "SummonDelay",
    Callback = function(v) Config.SummonDelay = v end
})

SummonTab:CreateToggle({
    Name = "Auto Summon",
    CurrentValue = false,
    Flag = "AutoSummon",
    Callback = function(v)
        Config.AutoSummon = v
        if v then coroutine.wrap(FarmUtils.AutoSummonLoop)() end
    end
})

SummonTab:CreateButton({
    Name = "Summon 1x",
    Callback = function()
        pcall(function()
            local remote = FarmUtils.FindRemote("Summon") or FarmUtils.FindRemote("SummonEvent")
            if remote then remote:FireServer(1); notify("Summon", "1x Summon fired", 2) else notify("Error", "Summon remote not found", 3) end
        end)
    end
})

SummonTab:CreateButton({
    Name = "Summon 10x",
    Callback = function()
        pcall(function()
            local remote = FarmUtils.FindRemote("Summon") or FarmUtils.FindRemote("SummonEvent")
            if remote then remote:FireServer(10); notify("Summon", "10x Summon fired", 2) else notify("Error", "Summon remote not found", 3) end
        end)
    end
})

-- Traits Tab
local TraitTab = Window:CreateTab("Traits", "sparkles")
TraitTab:CreateSection("Trait Rerolling")

TraitTab:CreateDropdown({
    Name = "Target Trait",
    Options = {"Deadeye", "Solar", "Blitz", "Fortune", "Marksman", "Scholar", "Vigor"},
    CurrentOption = "Deadeye",
    Flag = "TargetTrait",
    Callback = function(v) Config.TargetTrait = v end
})

TraitTab:CreateToggle({
    Name = "Auto Reroll Traits",
    CurrentValue = false,
    Flag = "AutoReroll",
    Callback = function(v)
        Config.AutoReroll = v
        if v then coroutine.wrap(FarmUtils.AutoRerollLoop)() end
    end
})

-- ESP Tab
local ESPTab = Window:CreateTab("ESP", "eye")
ESPTab:CreateSection("Visuals")

ESPTab:CreateToggle({
    Name = "Enable ESP",
    CurrentValue = false,
    Flag = "ESPEnabled",
    Callback = function(v)
        Config.ESP = v
        for _, esp in pairs(ESPUtils.ESPObjects) do
            if esp.Highlight then esp.Highlight.Enabled = v end
            if esp.Billboard then esp.Billboard.Enabled = v and Config.ESPName end
        end
    end
})

ESPTab:CreateToggle({Name = "Show Names", CurrentValue = true, Flag = "ESPNames", Callback = function(v) Config.ESPName = v end})
ESPTab:CreateToggle({Name = "Show Health", CurrentValue = false, Flag = "ESPHealth", Callback = function(v) Config.ESPHealth = v end})
ESPTab:CreateToggle({Name = "Show Distance", CurrentValue = false, Flag = "ESPDist", Callback = function(v) Config.ESPDistance = v end})

ESPTab:CreateToggle({
    Name = "Show Boxes (Highlight)",
    CurrentValue = true,
    Flag = "ESPBoxes",
    Callback = function(v)
        Config.ESPBoxes = v
        for _, esp in pairs(ESPUtils.ESPObjects) do
            if esp.Highlight then esp.Highlight.Enabled = v end
        end
    end
})

ESPTab:CreateButton({
    Name = "Refresh ESP",
    Callback = function()
        for _, esp in pairs(ESPUtils.ESPObjects) do
            if esp.Highlight then pcall(function() esp.Highlight:Destroy() end) end
            if esp.Billboard then pcall(function() esp.Billboard:Destroy() end) end
        end
        table.clear(ESPUtils.ESPObjects)
        ESPUtils.ScanForESP()
        notify("ESP", "ESP refreshed", 2)
    end
})

-- Player Tab
local PlayerTab = Window:CreateTab("Player", "user")
PlayerTab:CreateSection("Movement")

PlayerTab:CreateSlider({
    Name = "Walk Speed",
    Range = {16, 200},
    Increment = 1,
    Suffix = "s",
    CurrentValue = 16,
    Flag = "WalkSpeed",
    Callback = function(v)
        Config.WalkSpeed = v
        local char = FarmUtils.GetCharacter()
        local hum = char:FindFirstChild("Humanoid")
        if hum then hum.WalkSpeed = v end
    end
})

PlayerTab:CreateSlider({
    Name = "Jump Power",
    Range = {50, 300},
    Increment = 1,
    Suffix = "j",
    CurrentValue = 50,
    Flag = "JumpPower",
    Callback = function(v)
        Config.JumpPower = v
        local char = FarmUtils.GetCharacter()
        local hum = char:FindFirstChild("Humanoid")
        if hum then hum.JumpPower = v end
    end
})

PlayerTab:CreateToggle({Name = "Fly (Toggle)", CurrentValue = false, Flag = "Fly", Callback = function() FarmUtils.ToggleFly() end})

PlayerTab:CreateSection("Utility")

PlayerTab:CreateButton({
    Name = "Rejoin Server",
    Callback = function() game:GetService("TeleportService"):Teleport(game.PlaceId, Player) end
})

PlayerTab:CreateButton({
    Name = "Server Hop",
    Callback = function() game:GetService("TeleportService"):Teleport(game.PlaceId, Player) end
})

-- Status Tab
local StatusTab = Window:CreateTab("Status", "info")
StatusTab:CreateParagraph({
    Title = "Player Info",
    Content = "Player: " .. Player.Name .. "\nDisplay: " .. Player.DisplayName .. "\nUser ID: " .. Player.UserId .. "\nPlace ID: " .. game.PlaceId
})

StatusTab:CreateButton({
    Name = "Refresh Game State",
    Callback = function()
        FarmUtils.GetGameState()
        local waveText = State.CurrentWave > 0 and "Wave " .. State.CurrentWave or "N/A"
        local inGameText = State.InGame and "Yes" or "No"
        local inLobbyText = State.InLobby and "Yes" or "No"
        notify("Game State", "In Match: " .. inGameText .. "\nIn Lobby: " .. inLobbyText .. "\nCurrent Wave: " .. waveText, 5)
    end
})

-- Handle character spawning for WalkSpeed
Player.CharacterAdded:Connect(function(char)
    task.wait(1)
    if Config.WalkSpeed then
        local hum = char:WaitForChild("Humanoid")
        hum.WalkSpeed = Config.WalkSpeed
        hum.JumpPower = Config.JumpPower
    end
end)

coroutine.wrap(function()
    while task.wait(3) do
        pcall(function()
            if Player.Character and Config.WalkSpeed ~= 16 then
                local hum = Player.Character:FindFirstChild("Humanoid")
                if hum and hum.WalkSpeed ~= Config.WalkSpeed then
                    hum.WalkSpeed = Config.WalkSpeed
                    hum.JumpPower = Config.JumpPower
                end
            end
        end)
    end
end)()
