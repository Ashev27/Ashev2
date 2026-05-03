local Config = getgenv().AVConfig
local State = getgenv().AVState

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local VirtualInputManager = game:GetService("VirtualInputManager")
local TweenService = game:GetService("TweenService")
local HttpService = game:GetService("HttpService")

local Player = Players.LocalPlayer
local Mouse = Player:GetMouse()

local function FindRemote(namePattern)
    for _, obj in ipairs(ReplicatedStorage:GetDescendants()) do
        if obj:IsA("RemoteEvent") or obj:IsA("RemoteFunction") then
            if obj.Name:match(namePattern) then return obj end
        end
    end
    return nil
end

local function FindAllRemotes()
    local remotes = {}
    for _, obj in ipairs(ReplicatedStorage:GetDescendants()) do
        if obj:IsA("RemoteEvent") or obj:IsA("RemoteFunction") then table.insert(remotes, obj) end
    end
    return remotes
end

local function GetCharacter()
    return Player.Character or Player.CharacterAdded:Wait()
end

local function GetHumanoidRootPart()
    local char = GetCharacter()
    return char:FindFirstChild("HumanoidRootPart") or char:WaitForChild("HumanoidRootPart")
end

local function TweenTo(pos)
    local hrp = GetHumanoidRootPart()
    local tweenInfo = TweenInfo.new((hrp.Position - pos).Magnitude / Config.WalkSpeed, Enum.EasingStyle.Linear)
    local tween = TweenService:Create(hrp, tweenInfo, {CFrame = CFrame.new(pos)})
    tween:Play()
    return tween
end

local function ClickButton(button)
    if not button then return end
    pcall(function()
        if typeof(firesignal) == "function" then
            firesignal(button.MouseButton1Click)
            firesignal(button.Activated)
        end
    end)
    pcall(function()
        local pos = button.AbsolutePosition + button.AbsoluteSize / 2
        VirtualInputManager:SendMouseButtonEvent(pos.X, pos.Y, 0, true, game, 0)
        task.wait(0.1)
        VirtualInputManager:SendMouseButtonEvent(pos.X, pos.Y, 0, false, game, 0)
    end)
end

local function FindButtonByText(parent, text)
    for _, v in ipairs(parent:GetDescendants()) do
        if (v:IsA("TextButton") or v:IsA("TextLabel")) and v.Text:lower():find(text:lower(), 1, true) then
            if v:IsA("TextButton") then return v end
            if v.Parent:IsA("TextButton") or v.Parent:IsA("ImageButton") then return v.Parent end
        end
    end
    return nil
end

local function GetGameState()
    local lobbyCheck = Player.PlayerGui:FindFirstChild("LobbyGUI") or workspace:FindFirstChild("Lobby") or workspace:FindFirstChild("Spawn")
    local matchCheck = workspace:FindFirstChild("Map") or workspace:FindFirstChildWhichIsA("Part", true)
    
    for _, gui in ipairs(Player.PlayerGui:GetDescendants()) do
        if gui.Name:match("Wave") or gui.Name:match("wave") then
            local text = gui:IsA("TextLabel") and gui.Text or ""
            local waveNum = tonumber(text:match("%d+"))
            if waveNum then State.CurrentWave = waveNum end
        end
    end
    
    State.InLobby = lobbyCheck ~= nil
    State.InGame = matchCheck ~= nil or not State.InLobby
end

local function AutoFarmLoop()
    while Config.AutoFarm do
        task.wait(0.5)
        pcall(function()
            GetGameState()
            if State.InGame then
                if Config.AutoPlace then
                    local unitsFolder = Player:FindFirstChild("Units") or workspace:FindFirstChild("Units") or workspace:FindFirstChild("Towers")
                    if unitsFolder then
                        local i = 1
                        for _, unit in ipairs(unitsFolder:GetChildren()) do
                            local isPlaced = unit:FindFirstChild("Placed") or (unit.PrimaryPart and unit.PrimaryPart.Parent == workspace)
                            
                            if not isPlaced and unit:FindFirstChild("Name") then
                                local placeRemote = FindRemote("Place") or FindRemote("Spawn") or FindRemote("Deploy")
                                if placeRemote then
                                    local pos = Config.PlacePositions[i] or Vector3.new(0, 0, 0)
                                    pcall(function() placeRemote:FireServer(unit, pos) end)
                                    pcall(function() placeRemote:FireServer(unit.Name, pos) end)
                                end
                            end
                            
                            if Config.AutoUpgrade and isPlaced then
                                local upgradeRemote = FindRemote("Upgrade") or FindRemote("Boost") or FindRemote("LevelUp")
                                if upgradeRemote then upgradeRemote:FireServer(unit) end
                            end
                            
                            i = i + 1
                            task.wait(0.3)
                        end
                    end
                end
            end
            
            local resultsGUI = nil
            for _, gui in ipairs(Player.PlayerGui:GetChildren()) do
                if gui.Name:match("Result") or gui.Name:match("Victory") or gui.Name:match("Defeat") or gui.Name:match("EndScreen") then
                    resultsGUI = gui
                    break
                end
            end
            
            if not resultsGUI then
                local nextLabel = FindButtonByText(Player.PlayerGui, "Next (") or FindButtonByText(Player.PlayerGui, "Return to Lobby")
                if nextLabel then resultsGUI = nextLabel.Parent end
            end
            
            if resultsGUI or FindButtonByText(Player.PlayerGui, "Next (") then
                if Config.AutoNext then
                    local nextBtn = FindButtonByText(Player.PlayerGui, "Next")
                    if nextBtn then ClickButton(nextBtn) end
                elseif Config.AutoRetry then
                    local retryBtn = FindButtonByText(Player.PlayerGui, "Replay") or FindButtonByText(Player.PlayerGui, "Retry") or FindButtonByText(Player.PlayerGui, "PlayAgain")
                    if retryBtn then ClickButton(retryBtn) end
                end
            end
            
            if Config.AutoCollect then
                local collectBtn = FindButtonByText(Player.PlayerGui, "Collect") or FindButtonByText(Player.PlayerGui, "Claim") or FindButtonByText(Player.PlayerGui, "Reward")
                if collectBtn then ClickButton(collectBtn) end
            end
        end)
    end
end

local function AutoSummonLoop()
    while Config.AutoSummon do
        task.wait(Config.SummonDelay)
        pcall(function()
            local summonRemote = FindRemote("Summon") or FindRemote("SummonEvent") or FindRemote("Roll") or FindRemote("Gacha")
            if summonRemote then
                -- Try known patterns based on game version
                pcall(function() summonRemote:FireServer("summon", Config.SummonMode) end)
                pcall(function() summonRemote:FireServer(Config.SummonMode) end)
                State.Summoning = true
            else
                local summonGUI = Player.PlayerGui:FindFirstChild("Summon") or Player.PlayerGui:FindFirstChild("Gacha") or Player.PlayerGui:FindFirstChild("Banner")
                if summonGUI then
                    local summonButton = summonGUI:FindFirstChild("Summon1", true) or summonGUI:FindFirstChild("Summon", true) or summonGUI:FindFirstChild("Roll", true)
                    if summonButton then ClickButton(summonButton) end
                end
            end
        end)
    end
    State.Summoning = false
end

local function AutoRerollLoop()
    while Config.AutoReroll do
        task.wait(2)
        pcall(function()
            local traitGUI = Player.PlayerGui:FindFirstChild("Trait") or Player.PlayerGui:FindFirstChild("Reroll") or Player.PlayerGui:FindFirstChild("Stats")
            if traitGUI then
                local rerollButton = traitGUI:FindFirstChild("Reroll", true) or traitGUI:FindFirstChild("RollTrait", true) or traitGUI:FindFirstChild("Change", true)
                if rerollButton then
                    local hasTarget = false
                    for _, label in ipairs(traitGUI:GetDescendants()) do
                        if label:IsA("TextLabel") and label.Text:find(Config.TargetTrait) then
                            hasTarget = true
                            break
                        end
                    end
                    if not hasTarget then ClickButton(rerollButton) end
                end
            end
        end)
    end
end

local function AntiAFKLoop()
    while Config.AntiAFK do
        task.wait(60)
        pcall(function()
            local hrp = GetHumanoidRootPart()
            if hrp then hrp.CFrame = hrp.CFrame * CFrame.new(0, 0, 0.5) end
            VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.Space, false, game)
            task.wait(0.05)
            VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.Space, false, game)
        end)
    end
end

local function ToggleFly()
    Config.Fly = not Config.Fly
    local char = GetCharacter()
    local hrp = GetHumanoidRootPart()
    
    if Config.Fly then
        local hum = char:FindFirstChild("Humanoid")
        if hum then hum.PlatformStand = true end
        if not State.FlyBodyGyro then
            State.FlyBodyGyro = Instance.new("BodyGyro")
            State.FlyBodyGyro.P = 9e4
            State.FlyBodyGyro.MaxTorque = Vector3.new(9e4, 9e4, 9e4)
            State.FlyBodyGyro.CFrame = hrp.CFrame
            State.FlyBodyGyro.Parent = hrp
        end
        if not State.FlyBV then
            State.FlyBV = Instance.new("BodyVelocity")
            State.FlyBV.Velocity = Vector3.new(0, 0, 0)
            State.FlyBV.MaxForce = Vector3.new(9e4, 9e4, 9e4)
            State.FlyBV.Parent = hrp
        end
    else
        local hum = char:FindFirstChild("Humanoid")
        if hum then hum.PlatformStand = false end
        if State.FlyBodyGyro then State.FlyBodyGyro:Destroy(); State.FlyBodyGyro = nil end
        if State.FlyBV then State.FlyBV:Destroy(); State.FlyBV = nil end
    end
end

coroutine.wrap(function()
    while task.wait() do
        if Config.Fly and State.FlyBV then
            local success, hrp = pcall(GetHumanoidRootPart)
            if not success or not hrp then continue end
            
            local moveDir = Vector3.new()
            if UserInputService:IsKeyDown(Enum.KeyCode.W) then moveDir = moveDir + workspace.CurrentCamera.CFrame.LookVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.S) then moveDir = moveDir - workspace.CurrentCamera.CFrame.LookVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.A) then moveDir = moveDir - workspace.CurrentCamera.CFrame.RightVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.D) then moveDir = moveDir + workspace.CurrentCamera.CFrame.RightVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.Space) then moveDir = moveDir + Vector3.new(0, 1, 0) end
            if UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) then moveDir = moveDir + Vector3.new(0, -1, 0) end
            
            if moveDir.Magnitude > 0 then moveDir = moveDir.Unit * Config.WalkSpeed end
            State.FlyBV.Velocity = moveDir
            if State.FlyBodyGyro then State.FlyBodyGyro.CFrame = workspace.CurrentCamera.CFrame end
        end
    end
end)()

getgenv().AVFarmUtils = {
    GetGameState = GetGameState,
    AutoFarmLoop = AutoFarmLoop,
    AutoSummonLoop = AutoSummonLoop,
    AutoRerollLoop = AutoRerollLoop,
    AntiAFKLoop = AntiAFKLoop,
    ToggleFly = ToggleFly,
    FindRemote = FindRemote,
    FindAllRemotes = FindAllRemotes,
    TweenTo = TweenTo,
    GetCharacter = GetCharacter
}
