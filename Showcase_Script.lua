-- The script I was using in the showcase to test the drawing library.


local Custom_drawing_library = false
local Drawing_Library_Name = ""

--// Uncomment below this to test My Modify Drawing Library  
--local YellowGreg_Drawing_Library = loadstring(game:HttpGet("https://raw.githubusercontent.com/YellowGregs/Drawing_library/main/Drawing.lua"))()

if YellowGreg_Drawing_Library then
    Custom_drawing_library = true
    Drawing_Library_Name = "YellowGreg Drawing Library"
else
    Drawing_Library_Name = "Solara Executor Drawing Library"
end

print("Using:", Drawing_Library_Name)

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera

local eo = {}

local function box(player)
    if player == LocalPlayer then return end

    local Boxs = YellowGreg_Drawing_Library.new("Square")
    Boxs.Size = Vector2.new(100, 100) 
    Boxs.Thickness = 2
    Boxs.Color = Color3.new(1, 0, 0)
    Boxs.Visible = false
    Boxs.Filled = false
    Boxs.Parent = game.CoreGui

    local Names = YellowGreg_Drawing_Library.new("Text")
    Names.Text = player.Name
    Names.Color = Color3.new(1, 1, 1)
    Names.Size = 20
    Names.Center = true
    Names.Visible = false
    Names.Parent = game.CoreGui

    eo[player] = { Box = Boxs, Name = Names }
end

local function updates()
    for player, objects in pairs(eo) do
        local character = player.Character
        if character and character:FindFirstChild("HumanoidRootPart") then
            local rootPart = character.HumanoidRootPart
            local head = character:FindFirstChild("Head")

            if rootPart and head then
                local vector, onScreen = Camera:WorldToViewportPoint(rootPart.Position)

                if onScreen then
                    local headPosition = Camera:WorldToViewportPoint(head.Position)
                    local torsoPosition = Camera:WorldToViewportPoint(rootPart.Position)
                    local legPosition = Camera:WorldToViewportPoint(rootPart.Position - Vector3.new(0, 3, 0))

                    local height = math.abs(headPosition.Y - legPosition.Y)
                    local width = height / 2

                    objects.Box.Size = Vector2.new(width, height)
                    objects.Box.Position = Vector2.new(torsoPosition.X - width / 2, torsoPosition.Y - height / 2)
                    objects.Box.Visible = true

                    objects.Name.Position = Vector2.new(torsoPosition.X, torsoPosition.Y - height / 2 - 20)
                    objects.Name.Visible = true
                else
                    objects.Box.Visible = false
                    objects.Name.Visible = false
                end
            else
                objects.Box.Visible = false
                objects.Name.Visible = false
            end
        else
            objects.Box.Visible = false
            objects.Name.Visible = false
        end
    end
end

Players.PlayerAdded:Connect(box)
Players.PlayerRemoving:Connect(function(player)
    if eo[player] then
        eo[player].Box:Remove()
        eo[player].Name:Remove()
        eo[player] = nil
    end
end)

for _, player in ipairs(Players:GetPlayers()) do
    box(player)
end

RunService.RenderStepped:Connect(updates)
