-- Ashly Hub Loader - Anime Vanguards
local original = string.char
if string.char ~= original then
    error("Environment tampered")
end

-- Define Global Configuration and State for the modules
getgenv().AVConfig = {
    AutoFarm = false,
    AutoPlace = false,
    AutoUpgrade = false,
    AutoSummon = false,
    SummonMode = 1,
    SummonDelay = 1,
    AutoReroll = false,
    TargetTrait = "Deadeye",
    AntiAFK = false,
    AutoCollect = false,
    AutoRetry = false,
    AutoNext = false,
    ESP = false,
    ESPBoxes = false,
    ESPHealth = false,
    ESPDistance = false,
    ESPName = false,
    WalkSpeed = 16,
    JumpPower = 50,
    Fly = false,
    SelectedSlots = {1, 2, 3, 4, 5, 6},
    PlacePositions = {},
}

getgenv().AVState = {
    Summoning = false,
    Farming = false,
    Placing = false,
    CurrentWave = 0,
    InGame = false,
    InLobby = false,
    FlyBodyGyro = nil,
    FlyBV = nil,
}

-- Safely load Rayfield without getting blocked
local rayfield_parts = {"https://", "sirius", ".menu", "/rayfield"}
local rayfield_url = table.concat(rayfield_parts)
local Rayfield = loadstring(game:HttpGet(rayfield_url))()
getgenv().AshlyRayfield = Rayfield

local Window = Rayfield:CreateWindow({
    Name = "Anime Vanguards Hub",
    LoadingTitle = "Anime Vanguards",
    LoadingSubtitle = "Authentication",
    ConfigurationSaving = {Enabled = false},
    KeySystem = false
})
getgenv().MainWindow = Window

local savedKeyFile = "Ashly_AnimeVanguards_Key.txt"
local KeyInput = ""

if isfile and isfile(savedKeyFile) then
    local s, res = pcall(function() return readfile(savedKeyFile) end)
    if s and type(res) == "string" then
        KeyInput = res:gsub("^%s*(.-)%s*$", "%1")
    end
end

local function validateKey(keyToTest)
    -- You can change this to your desired key
    if keyToTest == "Ashlythebest" then
        return true
    end
    return false
end

local function loadModules()
    local function loadRemoteModule(moduleName)
        local url_parts = {"https://raw.githubusercontent.com", "/Ashev27", "/Ashev2", "/main/", moduleName, ".lua"}
        local module_url = table.concat(url_parts)
        
        local s, res = pcall(function()
            return loadstring(game:HttpGet(module_url))()
        end)
        if not s then
            warn("Failed to load module: " .. moduleName .. " | Error: " .. tostring(res))
        end
    end

    loadRemoteModule("av_farm")
    loadRemoteModule("av_esp")
    loadRemoteModule("av_ui")
end

if KeyInput ~= "" and validateKey(KeyInput) then
    Rayfield:Notify({Title = "Auto-Login", Content = "Saved key used: '" .. KeyInput .. "'", Duration = 5})
    
    -- Directly load modules into the existing window
    loadModules()
else
    -- Invalid or no key saved, show Auth screen
    if isfile and isfile(savedKeyFile) and delfile then
        pcall(function() delfile(savedKeyFile) end)
    end
    KeyInput = ""

    local AuthTab = Window:CreateTab("Authentication", 4483362458)
    getgenv().AuthTab = AuthTab
    
    AuthTab:CreateInput({
        Name = "Enter Secret Key",
        PlaceholderText = "Key...",
        RemoveTextAfterFocusLost = false,
        Callback = function(Text)
            KeyInput = Text
        end,
    })

    AuthTab:CreateButton({
        Name = "Login",
        Callback = function()
            Rayfield:Notify({Title = "Authenticating", Content = "Checking key...", Duration = 2})
            
            local isValid = validateKey(KeyInput)

            if isValid then
                Rayfield:Notify({Title = "Success", Content = "Key valid! Loading features...", Duration = 2})
                if writefile then
                    writefile(savedKeyFile, KeyInput)
                end
                
                pcall(function()
                    for _, v in pairs(AuthTab:GetChildren()) do
                        pcall(function() v:Destroy() end)
                    end
                end)

                AuthTab:CreateParagraph({
                    Title = "Logged In",
                    Content = "Welcome! Use the tabs above."
                })

                task.wait(0.3)
                -- Load the real secret script
                -- Directly load modules into the existing window
                loadModules()
            else
                Rayfield:Notify({Title = "Denied", Content = "Invalid Key! Please try again.", Duration = 3})
            end
        end
    })
end
