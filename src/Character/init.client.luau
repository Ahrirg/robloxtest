local MaxSpeed = 300
local MinSpeed = 5
local RampStepness = 0.1
local GroundFriction = 0.98
local RampFriction = 0.97
local TimeTick = 0.001
local SpeedUp = 15

local UserInput = game:GetService("UserInputService")

local Player = game.Players.LocalPlayer
local PlayerModule = require(Player.PlayerScripts:WaitForChild("PlayerModule"))
local Controls = PlayerModule:GetControls();

Controls:Disable()
Controls:Enable()

local Character = Player.Character or Player.CharacterAdded:Wait()
local HumanRootPart = Character:WaitForChild("HumanoidRootPart")  --Self explanitory
local Human = Character:WaitForChild("Humanoid")
local Animation = Character:WaitForChild("Animate")

local  animation = Character:WaitForChild("AnimSaves"):FindFirstChild("Slide")
local  SlidesAnim = Human:LoadAnimation(animation)

local Stop = false
local Debounce = false

--Inital logic
local ListOfExecptions = {}
for _, v in pairs(HumanRootPart.Parent:GetDescendants()) do
    table.insert(ListOfExecptions, v)
end

local params = RaycastParams.new()
params.FilterDescendantsInstances = ListOfExecptions
params.FilterType = Enum.RaycastFilterType.Exclude
--Inital logic


local function RayCastCheck(Vector)
    local Origin = Vector3.new(HumanRootPart.Position.X, HumanRootPart.Position.Y, HumanRootPart.Position.Z)
    local Direction = Vector

    return workspace:Raycast(Origin, Direction, params)
end

local function SpeedModifier(Y)
    
    if Y > RampStepness and Y > 0 then
        return RampFriction
    elseif Y < 0 and Y < RampStepness then
        local x = -Y / SpeedUp
        return 1 + x
    else
        return GroundFriction
    end
end

local function StartSlide() 
    Debounce = true
    Animation.Enabled = false
    Human.AutoRotate = false
    Controls:Disable()
    SlidesAnim:Play()   

    for _, v in pairs(HumanRootPart.Parent:GetDescendants()) do --Disable all cooligions
        if (v:IsA("MeshPart") or v:IsA("Part")) and v ~= HumanRootPart then
            v.CanCollide = false
            v.Massless = true
        end
    end 
    Human:SetStateEnabled(Enum.HumanoidStateType.FallingDown, false)
    Human:SetStateEnabled(Enum.HumanoidStateType.Ragdoll, false)
    --Human:SetStateEnabled(Enum.HumanoidStateType.Physics, false)

end
local function EndSlide() 
    Animation.Enabled = true
    Controls:Enable()
    Stop = true
    Debounce = false
    SlidesAnim:Stop()
    Human.AutoRotate = true
end

local function Slide(SlideVector)
    StartSlide()

    local Attachment = Instance.new("Attachment") --sFor Player Speed
    Attachment.Parent = HumanRootPart

    local LinearVelocity = Instance.new("LinearVelocity") --For Player Speed
    LinearVelocity.Parent = HumanRootPart
    LinearVelocity.Attachment0 = Attachment
    LinearVelocity.RelativeTo = "World"
    LinearVelocity.MaxForce = math.huge

    local RotationPart = Instance.new("Part") --for player Rotation when sliding
    RotationPart.Transparency = 1
    RotationPart.CanCollide = false
    RotationPart.Parent = HumanRootPart
    
    local Attachment1 = Instance.new("Attachment") --for player Rotation when sliding
    Attachment1.Parent = RotationPart
    Attachment1.Name = "Attachment1"
    Attachment1.Position = HumanRootPart.CFrame.Position

    local AlignOrientation = Instance.new("AlignOrientation") --for player Rotation when sliding
    AlignOrientation.Parent = HumanRootPart
    AlignOrientation.Attachment0 = Attachment
    AlignOrientation.Attachment1 = Attachment1
    AlignOrientation.Responsiveness = 200

    
    RotationPart.CFrame = CFrame.lookAt(RotationPart.CFrame.Position, RotationPart.CFrame.Position + SlideVector * Vector3.new(1,0,1)) -- getting initial Vector
    local Speed = Character.PrimaryPart.AssemblyLinearVelocity.Magnitude + 1 -- Getting inital Speed
    wait(TimeTick)

    Stop = false
    while Stop == false do 
        Human.AutoRotate = false -- test delete after putting into input handler
        if MinSpeed < Speed and RayCastCheck(HumanRootPart.CFrame.LookVector * Vector3.new(1,0,1)) == nil then
            local RayCastResult = RayCastCheck(Vector3.new(0,-4,0))
            if RayCastResult ~= nil then

                local ForwardsVector = RayCastResult.Normal:Cross(HumanRootPart.CFrame.RightVector)
                LinearVelocity.VectorVelocity = (Speed * ForwardsVector)

                if RayCastCheck(HumanRootPart.CFrame.UpVector * -3) ~= nil then
                    LinearVelocity.VectorVelocity = LinearVelocity.VectorVelocity + HumanRootPart.CFrame.UpVector*3
                end

                RotationPart.CFrame = CFrame.lookAt(RotationPart.CFrame.Position, RotationPart.CFrame.Position + ForwardsVector)

                if Speed <= MaxSpeed then
                    Speed = Speed * SpeedModifier(ForwardsVector.Y)
                else 
                    Speed = Speed
                end
            else 
                LinearVelocity.VectorVelocity = LinearVelocity.VectorVelocity + Vector3.new(0,-6,0)
            end
            wait(TimeTick)
        else
            Stop = true
        end
    end

    Attachment.Parent = nil -- cleaning up
    LinearVelocity.Parent = nil
    Attachment1.Parent = nil
    AlignOrientation.Parent = nil
    RotationPart.Parent = nil
    --Character.PrimaryPart.AssemblyLinearVelocity = HumanRootPart.CFrame.lookVector * Speed
    EndSlide() 
end



UserInput.InputBegan:Connect(function(input) -- Getting Input and checking if its LeftControl
    if input.KeyCode == Enum.KeyCode.LeftControl and Debounce == false then
        while UserInput:IsKeyDown(Enum.KeyCode.LeftControl) do
            wait(0.00001)
            if RayCastCheck(Vector3.new(0,-6,0)) ~= nil then
                local SlideVector = Vector3.zero
                if UserInput:IsKeyDown(Enum.KeyCode.W) then
                    SlideVector = SlideVector + workspace.CurrentCamera.CFrame.LookVector
                end
                if UserInput:IsKeyDown(Enum.KeyCode.A) then
                    SlideVector = SlideVector + workspace.CurrentCamera.CFrame.RightVector * -1
                end
                if UserInput:IsKeyDown(Enum.KeyCode.D) then
                    SlideVector = SlideVector + workspace.CurrentCamera.CFrame.RightVector
                end
                if UserInput:IsKeyDown(Enum.KeyCode.S) then
                    SlideVector = SlideVector + workspace.CurrentCamera.CFrame.LookVector * -1
                end
                if SlideVector ~= Vector3.zero then
                    Slide(SlideVector)
                    return 0
                else
                    Slide(workspace.CurrentCamera.CFrame.LookVector)
                end
            end
        end
    end
    if input.KeyCode == Enum.KeyCode.Space then
        EndSlide()
    end
end)

UserInput.InputEnded:Connect(function(input) 
    if input.KeyCode == Enum.KeyCode.LeftControl then
        EndSlide()
        Controls:Disable()
        Controls:Enable()
    end
end)

Human.Died:Connect(function()
    Controls:Disable()
    Controls:Enable()
end)