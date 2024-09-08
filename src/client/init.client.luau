local UserInput = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")

local Player = game.Players.LocalPlayer
local Character = Player.Character or Player.CharacterAdded:Wait()
local HumanRootPart = Character:WaitForChild("HumanoidRootPart")  --Self explanitory

local SlidingTime = 4
local InitialForce = 15000


local ListOfExecptions = {}
for _, v in pairs(HumanRootPart.Parent:GetDescendants()) do
    table.insert(ListOfExecptions, v)
end

local params = RaycastParams.new()
params.FilterDescendantsInstances = ListOfExecptions
params.FilterType = Enum.RaycastFilterType.Exclude

print(ListOfExecptions)


local function SlidingSpeedMath(t, InitialForce)

    local f = math.exp(-0.1*t)

    if f >= 0 then
        return InitialForce * f
    else
        return 0
    end
end

local function RayCastCheck()
    local Origin = Vector3.new(HumanRootPart.Position.X, HumanRootPart.Position.Y, HumanRootPart.Position.Z)
    local Direction = Vector3.new(0,-3,0)

    return workspace:Raycast(Origin, Direction, params)
end

local function Slide()
    local Attachment = Instance.new("Attachment") --Creating attachment
    Attachment.Parent = HumanRootPart

    local VectorForce = Instance.new("VectorForce") --Creating VectorForce
    VectorForce.Parent = HumanRootPart
    VectorForce.Attachment0 = Attachment
    VectorForce.RelativeTo = "World"

    local LookVector = Workspace.CurrentCamera.CFrame.LookVector
    LookVector = LookVector * Vector3.new(1,0,1)

    VectorForce.Force = LookVector * InitialForce --Adding vector/force to VectorForce

    for t = 0, SlidingTime, 1 do
        if RayCastCheck() ~= nil then
            VectorForce.Force = LookVector * SlidingSpeedMath(t, InitialForce)
        else
            VectorForce.Force = Vector3.new(0,0,0)
        end
        wait(0.1)
    end

    VectorForce.Parent = nil --Cleaning up
    Attachment.Parent = nil
end


UserInput.InputBegan:Connect(function(input) -- Getting Input and checking if its LeftShift
    if input.KeyCode == Enum.KeyCode.LeftShift then
        print("Pressed")
        Slide()
   end
end)