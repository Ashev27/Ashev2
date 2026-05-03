local Config = getgenv().AVConfig
local State = getgenv().AVState

local Players = game:GetService("Players")
local Player = Players.LocalPlayer

local ESPObjects = {}

local function GetCharacter()
    return Player.Character or Player.CharacterAdded:Wait()
end

local function GetHumanoidRootPart()
    local char = GetCharacter()
    return char:FindFirstChild("HumanoidRootPart") or char:WaitForChild("HumanoidRootPart")
end

local function CreateESP(instance, color)
    if not instance or ESPObjects[instance] then return end
    
    local esp = {
        Instance = instance,
        Highlight = nil,
        Billboard = nil,
        Color = color or Color3.fromRGB(255, 50, 50),
    }
    
    local highlight = Instance.new("Highlight")
    highlight.Adornee = instance
    highlight.FillColor = esp.Color
    highlight.FillTransparency = 0.5
    highlight.OutlineColor = esp.Color
    highlight.OutlineTransparency = 0
    highlight.Parent = instance
    esp.Highlight = highlight
    
    local billboard = Instance.new("BillboardGui")
    billboard.Adornee = instance.PrimaryPart or instance:FindFirstChildWhichIsA("BasePart") or instance:FindFirstChild("HumanoidRootPart")
    billboard.Size = UDim2.new(0, 200, 0, 50)
    billboard.StudsOffset = Vector3.new(0, 3, 0)
    billboard.AlwaysOnTop = true
    billboard.Parent = instance
    
    local textLabel = Instance.new("TextLabel")
    textLabel.Size = UDim2.new(1, 0, 1, 0)
    textLabel.BackgroundTransparency = 1
    textLabel.TextColor3 = esp.Color
    textLabel.TextStrokeTransparency = 0
    textLabel.TextStrokeColor3 = Color3.new(0, 0, 0)
    textLabel.Font = Enum.Font.GothamBold
    textLabel.TextSize = 14
    textLabel.Text = instance.Name
    textLabel.Parent = billboard
    
    esp.Billboard = billboard
    esp.TextLabel = textLabel
    ESPObjects[instance] = esp
    
    return esp
end

local function UpdateESP()
    for _, esp in pairs(ESPObjects) do
        if not esp.Instance or not esp.Instance.Parent then
            if esp.Highlight then esp.Highlight:Destroy() end
            if esp.Billboard then esp.Billboard:Destroy() end
            ESPObjects[_] = nil
        else
            if esp.Instance:IsA("Model") then
                local primary = esp.Instance.PrimaryPart or esp.Instance:FindFirstChildWhichIsA("BasePart")
                if primary and esp.Billboard then
                    esp.Billboard.Adornee = primary
                end
            end
            
            if esp.TextLabel and Config.ESPName then
                local dist = ""
                if Config.ESPDistance then
                    local hrp = pcall(function() return GetHumanoidRootPart() end)
                    if hrp and esp.Billboard and esp.Billboard.Adornee then
                        dist = " [" .. math.floor((esp.Billboard.Adornee.Position - GetHumanoidRootPart().Position).Magnitude) .. "m]"
                    end
                end
                esp.TextLabel.Text = esp.Instance.Name .. dist
            end
            
            if esp.Highlight then
                esp.Highlight.Enabled = Config.ESP
            end
            if esp.Billboard then
                esp.Billboard.Enabled = Config.ESP and Config.ESPName
            end
        end
    end
end

local function ScanForESP()
    if not Config.ESP then return end
    for _, v in ipairs(workspace:GetDescendants()) do
        if v:IsA("Model") and v:FindFirstChild("Humanoid") then
            if not ESPObjects[v] then
                local color = Color3.fromRGB(255, 50, 50)
                if v:FindFirstChild("HumanoidRootPart") then
                    if v:FindFirstChildOfClass("Model") then
                        color = Color3.fromRGB(50, 255, 50)
                    end
                end
                CreateESP(v, color)
            end
        end
    end
end

coroutine.wrap(function()
    while true do
        task.wait(1)
        if Config.ESP then
            pcall(function()
                ScanForESP()
                UpdateESP()
            end)
        else
            -- If ESP is toggled off, make sure we clean up the visuals
            pcall(function()
                for _, esp in pairs(ESPObjects) do
                    if esp.Highlight then esp.Highlight.Enabled = false end
                    if esp.Billboard then esp.Billboard.Enabled = false end
                end
            end)
        end
    end
end)()
