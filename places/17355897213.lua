--// SETUP \\--
local library = getgenv().Library

if not getgenv().xhub_loaded then
    getgenv().xhub_loaded = true
else
    library:Notify("[xHub] Already Loaded!")
    return
end

--// SERVICES \\--
local workspace = game:GetService("Workspace")
local lighting = game:GetService("Lighting")
local players = game:GetService("Players")
local repStorage = game:GetService("ReplicatedStorage")
local runService = game:GetService("RunService")
local userInputService = game:GetService("UserInputService")

local characters = workspace:WaitForChild("Characters")
local events = repStorage:WaitForChild("Events")
local blur = lighting:WaitForChild("Blur")
local depthOfField = lighting:WaitForChild("DepthOfField")

local themes = getgenv().ThemeManager
local saves = getgenv().SaveManager
local options = getgenv().Linoria.Options
local toggles = getgenv().Linoria.Toggles

local player = players.LocalPlayer

local currentRoom = Instance.new("ObjectValue")
currentRoom.Name = "CurrentRoom"
currentRoom.Parent = player

local fly = {
    enabled = false,
    flyBody = Instance.new("BodyVelocity"),
    flyGyro = Instance.new("BodyGyro")
}

fly.flyBody.Velocity = Vector3.zero
fly.flyBody.MaxForce = Vector3.one * 9e9

fly.flyGyro.P = 0
fly.flyGyro.MaxTorque = Vector3.one * 9e9

local camera = workspace.CurrentCamera

if not player.Character then player.CharacterAdded:Wait() end

local funcs = {}

funcs.getMoveVector = function()
    local x, z = 0, 0

    if userInputService:IsKeyDown(Enum.KeyCode.W) then z = z - 1 end
    if userInputService:IsKeyDown(Enum.KeyCode.A) then x = x - 1 end
    if userInputService:IsKeyDown(Enum.KeyCode.S) then z = z + 1 end
    if userInputService:IsKeyDown(Enum.KeyCode.D) then x = x + 1 end

    return Vector3.new(x, 0, z)
end

--// UI \\--
local window = library:CreateWindow({
    Title = "xHub - " .. player.DisplayName,
    Center = true,
    AutoShow = true
})

local tabs = {
    Main = window:AddTab("Main"),
    Visual = window:AddTab("Visual"),
    Entity = window:AddTab("Entity"),
    Settings = window:AddTab("Settings")
}

local main = {
    Movement = tabs.Main:AddLeftGroupbox("Movement"),
    Sound = tabs.Main:AddRightGroupbox("Sound"),
    Other = tabs.Main:AddRightGroupbox("Other")
}

main.Movement:AddSlider("SpeedBoost", {
    Text = "Speed Boost",
    Default = 0,
    Min = 0,
    Max = 50,
    Rounding = 0
})

main.Movement:AddSlider("JumpHeight", {
    Text = "Jump Power",
    Default = 0,
    Min = 0,
    Max = 25,
    Rounding = 0
})

main.Movement:AddToggle("AbsoluteMadness", {
    Text = "Absolute Madness",
    Callback = function(value)
        if value then
            options.SpeedBoost:SetMax(900)
            options.JumpHeight:SetMax(900)
            options.FlySpeed:SetMax(900)
        else
            options.SpeedBoost:SetMax(50)
            options.JumpHeight:SetMax(25)
            options.FlySpeed:SetMax(50)
        end
    end
})

main.Movement:AddDivider()

main.Movement:AddToggle("NoAccel", {
    Text = "No Acceleration",
    Callback = function(value)
        if not value then
            player.Character.PrimaryPart.CustomPhysicalProperties = nil
        end
    end
})

main.Movement:AddToggle("Noclip", {
    Text = "Noclip"
}):AddKeyPicker("NoclipKey", {
    Text = "Noclip",
    Default = "N",
    Mode = "Toggle"
})

main.Movement:AddDivider()

main.Movement:AddToggle("Fly", {
    Text = "Fly"
}):AddKeyPicker("FlyKey", {
    Text = "Fly",
    Default = "G",
    Mode = "Toggle",
    Callback = function(value)
        if toggles.Fly.Value then
            fly.enabled = value
            if value then
                fly.flyBody.Parent = player.Character.HumanoidRootPart
                fly.flyGyro.Parent = player.Character.HumanoidRootPart
            else
                fly.flyBody.Parent = nil
                fly.flyGyro.Parent = nil
            end
        end
    end
})

main.Movement:AddSlider("FlySpeed", {
    Text = "Fly Speed",
    Default = 0,
    Min = 0,
    Max = 50,
    Rounding = 0
})

main.Sound:AddToggle("NoAmbience", {
    Text = "Mute Ambience",
    Callback = function(value)
        if value then
            local ambience = workspace:WaitForChild("Ambience"):WaitForChild("FacilityAmbience")

            ambience.Volume = 0
        end
    end
})

main.Sound:AddToggle("NoFootsteps", { Text = "Mute Footsteps" })

main.Other:AddButton({
    Text = "Play Again",
    DoubleClick = true,
    Func = function()
        events.PlayAgain:FireServer()
        library:Notify("[xHub] Teleporting in 5 seconds")
    end
})

------------------------------------------------

local visual = {
    Camera = tabs.Visual:AddLeftGroupbox("Camera"),
    Lighting = tabs.Visual:AddRightGroupbox("Lighting")
}

visual.Camera:AddSlider("FieldOfView", {
    Text = "Field Of View",
    Default = 90,
    Min = 30,
    Max = 120,
    Rounding = 0,
    Callback = function(value) camera.FieldOfView = value end
})

visual.Camera:AddDivider()

visual.Camera:AddToggle("ThirdPerson", {
    Text = "Third Person"
}):AddKeyPicker("ThirdPersonKey", {
    Text = "Third Person",
    Default = "V",
    Mode = "Toggle",
    Callback = function(value)
        if value then
            player.Character.Head.Transparency = 0
        else
            player.Character.Head.Transparency = 1
        end
    end
})

visual.Lighting:AddToggle("Fullbright", {
    Text = "Fullbright",
    Callback = function(value)
        if value then
            lighting.Ambient = Color3.fromRGB(255, 255, 255)
        else
            lighting.Ambient = Color3.fromRGB(40, 53, 65)
        end
    end
})

visual.Lighting:AddToggle("NoFog", {
    Text = "No Underwater Fog",
    Callback = function(value)
        if value then
            blur.Size = 0
            depthOfField.FarIntensity = 0
        else
            blur.Size = 4
            depthOfField.FarIntensity = 0.25
        end
    end
})

visual.Lighting:AddToggle("XRayVision", {
    Text = "X-ray effect",
    Tooltip = "Not X-ray vision haha",
    Callback = function(value)
        lighting:WaitForChild("Test").Enabled = value
    end
})

------------------------------------------------

local entity = {
    Exploits = tabs.Entity:AddLeftGroupbox("Exploits")
}

entity.Exploits:AddToggle("AntiBouncer", { Text = "Anti Bouncer", Risky = true })
entity.Exploits:AddToggle("AntiSkelepede", { Text = "Anti Skelepede", Risky = true })
entity.Exploits:AddToggle("AntiCandlelighters", { Text = "Anti Candlelighters", Risky = true })

library:GiveSignal(runService.RenderStepped:Connect(function()
    if toggles.NoAmbience.Value then
        local part = workspace:FindFirstChild("AmbiencePart")

        if part then
            local sound = part:FindFirstChildWhichIsA("Sound")

            if sound then sound:Destroy() end
        end
    end

    if toggles.NoFootsteps.Value then
        for _, char in pairs(characters:GetChildren()) do
            for _, sound in pairs(char.LowerTorso:GetChildren()) do
                if sound:IsA("Sound") then
                    sound:Destroy()
                end
            end
        end
    end

    if player.Character.Parent == characters then
        if toggles.ThirdPerson.Value and options.ThirdPersonKey:GetState() then
            camera.CFrame = camera.CFrame * CFrame.new(1.5, -0.5, 6.5)
        end

        if toggles.Noclip.Value and options.NoclipKey:GetState() then
            for _, part in pairs(player.Character:GetChildren()) do
                if part:IsA("BasePart") or part:IsA("MeshPart") then
                    part.CanCollide = false
                end
            end
        end

        if fly.enabled then
            local velocity = Vector3.zero
            local moveVector = funcs.getMoveVector()
            velocity = -((camera.CFrame.LookVector * moveVector.Z) - (camera.CFrame.RightVector * moveVector.X))

            if userInputService:IsKeyDown(Enum.KeyCode.Space) then velocity = velocity + camera.CFrame.UpVector end
            if userInputService:IsKeyDown(Enum.KeyCode.LeftShift) then velocity = velocity - camera.CFrame.UpVector end

            fly.flyBody.Velocity = velocity * options.FlySpeed.Value
            fly.flyGyro.CFrame = camera.CFrame
        end

        camera.FieldOfView = options.FieldOfView.Value
    end

    player.Character.Humanoid.WalkSpeed = 16 + options.SpeedBoost.Value

    player.Character.Humanoid.JumpHeight = options.JumpHeight.Value

    if player.Character.PrimaryPart.Massless then
        player.Character.PrimaryPart.CustomPhysicalProperties = nil
    elseif toggles.NoAccel.Value then
        player.Character.PrimaryPart.CustomPhysicalProperties = PhysicalProperties.new(100, 0.5, 0.3, 1, 1)
    end
end))

------------------------------------------------

local settings = {
    Menu = tabs.Settings:AddLeftGroupbox("Menu"),
    Credits = tabs.Settings:AddRightGroupbox("Credits")
}

settings.Menu:AddToggle("KeybindMenu", {
    Text = "Open Keybind Menu",
    Callback = function(value) library.KeybindFrame.Visible = value end
})

settings.Menu:AddToggle("CustomCursor", {
    Text = "Show Custom Cursor",
    Default = true,
    Callback = function(value) library.ShowCustomCursor = value end
})

settings.Menu:AddDivider()

settings.Menu:AddLabel("Menu Keybind"):AddKeyPicker("MenuKeybind", {
    Text = "Menu Keybind",
    NoUI = true,
    Default = "RightShift"
})

settings.Menu:AddButton("Unload", library.Unload)

settings.Credits:AddLabel("xBackpack - Creator & Scripter")

library.ToggleKeybind = options.MenuKeybind

library:OnUnload(function()
    currentRoom:Destroy()
    getgenv().Alert = nil
    getgenv().xhub_loaded = nil
end)

themes:SetLibrary(library)
saves:SetLibrary(library)

saves:IgnoreThemeSettings()

saves:SetIgnoreIndexes({ "MenuKeybind" })

themes:SetFolder("xHub")
saves:SetFolder("xHub/Pressure")

themes:ApplyToTab(tabs.Settings)
saves:BuildConfigSection(tabs.Settings)

saves:LoadAutoloadConfig()
