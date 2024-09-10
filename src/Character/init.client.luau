local MaxSpeed = 300
local MinSpeed = 5
local RampStepness = 0.1
local GroundFriction = 0.995
local RampFriction = 0.98


local UserInput = game:GetService("UserInputService")

local Player = game.Players.LocalPlayer
local Character = Player.Character or Player.CharacterAdded:Wait()
local HumanRootPart = Character:WaitForChild("HumanoidRootPart")  --Self explanitory
local Human = Character:WaitForChild("Humanoid")
local Animation = Character:WaitForChild("Animate")

local animation = Character:WaitForChild("AnimSaves"):FindFirstChild("Slide")
local SlidesAnim = Human:LoadAnimation(animation)

local Stop = false
local Debounce = false
local HumanSpeed = Human.WalkSpeed
Animation.Enabled = false


--Inital logic
local ListOfExecptions = {}
for _, v in pairs(HumanRootPart.Parent:GetDescendants()) do
    table.insert(ListOfExecptions, v)
end

local params = RaycastParams.new()
params.FilterDescendantsInstances = ListOfExecptions
params.FilterType = Enum.RaycastFilterType.Exclude
--Inital logic


local function RayCastCheck()
    local Origin = Vector3.new(HumanRootPart.Position.X, HumanRootPart.Position.Y, HumanRootPart.Position.Z)
    local Direction = Vector3.new(0,-6,0)

    return workspace:Raycast(Origin, Direction, params)
end


local function SpeedModifier(Y)
    
    if Y > RampStepness and Y > 0 then
        return GroundFriction
    elseif Y < 0 and Y < RampStepness then
        local x = RampStepness / 8
        return 1 + x
    else
        return RampFriction
    end
end


local function StartSlide() 
    Human.WalkSpeed = 0
    SlidesAnim:Play()
    for _, v in pairs(HumanRootPart.Parent:GetDescendants()) do
        if (v:IsA("MeshPart") or v:IsA("MeshPart")) and v ~= HumanRootPart then
            v.CanCollide = false
        end
    end 
end
local function EndSlide() 
    Stop = true
    Debounce = false
    Human.WalkSpeed = HumanSpeed
    SlidesAnim:Stop()
end



local function Slide()

    StartSlide()
    local ControlVector = workspace.CurrentCamera.CFrame.RightVector
    print(HumanRootPart.Position)
    HumanRootPart.CFrame = CFrame.lookAt(HumanRootPart.Position, workspace.CurrentCamera.CFrame.LookVector * Vector3.new(1,0,1))
    local Speed = Character.PrimaryPart.AssemblyLinearVelocity.Magnitude
    local Attachment = Instance.new("Attachment") --sukuriam Suda
    Attachment.Parent = HumanRootPart

    local LinearVelocity = Instance.new("LinearVelocity") --sukuriam Suda
    LinearVelocity.Parent = HumanRootPart
    LinearVelocity.Attachment0 = Attachment
    LinearVelocity.RelativeTo = "World"
    LinearVelocity.MaxForce = math.huge


    Stop = false
    while Stop == false do 
        if MinSpeed < Speed then
            local RayCastResult = RayCastCheck()
            if RayCastResult ~= nil then

                local ForwardsVector = RayCastResult.Normal:Cross(ControlVector)
                LinearVelocity.VectorVelocity = Speed * ForwardsVector

                if Speed <= MaxSpeed then
                    Speed = Speed * SpeedModifier(ForwardsVector.Y)
                else 
                    Speed = Speed
                end

                print(Speed)

                wait(0.01)
            else
                wait(0.05)
                Stop = true
            end
        else
            Stop = true
        end
    end

    Attachment.Parent = nil -- cleaning up
    LinearVelocity.Parent = nil
    --Character.PrimaryPart.AssemblyLinearVelocity = HumanRootPart.CFrame.lookVector * Speed
    EndSlide() 
end



UserInput.InputBegan:Connect(function(input) -- Getting Input and checking if its LeftShift
    if input.KeyCode == Enum.KeyCode.LeftShift then
        print("Pressed")
        if Debounce == false and RayCastCheck() ~= nil then
            Slide()
        end
    end
    if input.KeyCode == Enum.KeyCode.Space then
        EndSlide()
    end
end)

UserInput.InputEnded:Connect(function(input) 
    if input.KeyCode == Enum.KeyCode.LeftShift then
        EndSlide()
    end
end)