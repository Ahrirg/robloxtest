local MaxSpeed = 300 -- hyperparams
local MinSpeed = 5
local RampStepness = 0.1
local GroundFriction = 0.98
local RampFriction = 0.97
local TimeTick = 0.001
local SpeedUp = 15

local UserInput = game:GetService("UserInputService")--Self explanitory

local Player = game.Players.LocalPlayer--Self explanitory--Self explanitory
local PlayerModule = require(Player.PlayerScripts:WaitForChild("PlayerModule"))--Self explanitory
local Controls = PlayerModule:GetControls();--Self explanitory

Controls:Disable() -- cuz if i dont do this PLAYER CONTROLS CAN/WILL GLITCH OUT like wtf
Controls:Enable()

local Character = Player.Character or Player.CharacterAdded:Wait() --Self explanitory
local HumanRootPart = Character:WaitForChild("HumanoidRootPart")  --Self explanitory
local Human = Character:WaitForChild("Humanoid")--Self explanitory--Self explanitory--Self explanitory
local Animation = Character:WaitForChild("Animate")--Self explanitory--Self explanitory
--Self explanitory--Self explanitory
local  animation = Character:WaitForChild("AnimSaves"):FindFirstChild("Slide")--Self explanitory
local  SlidesAnim = Human:LoadAnimation(animation)--Self explanitory--Self explanitory

local Stop = false--Self explanitory
local Debounce = false--Self explanitory--Self explanitory--Self explanitory--Self explanitory (if you dont know why we need this is better to watch some youtube tutorials idk.)

--Inital logic
local ListOfExecptions = {} -- more raycast params
for _, v in pairs(HumanRootPart.Parent:GetDescendants()) do
    table.insert(ListOfExecptions, v)
end

local params = RaycastParams.new() -- raycast params
params.FilterDescendantsInstances = ListOfExecptions
params.FilterType = Enum.RaycastFilterType.Exclude
--Inital logic


local function RayCastCheck(Vector) -- raycast, need anything more ?
    local Origin = Vector3.new(HumanRootPart.Position.X, HumanRootPart.Position.Y, HumanRootPart.Position.Z)
    local Direction = Vector

    return workspace:Raycast(Origin, Direction, params)
end

local function SpeedModifier(Y) -- speed modifier math, uuuuu scarry math
    
    if Y > RampStepness and Y > 0 then
        return RampFriction
    elseif Y < 0 and Y < RampStepness then
        local x = -Y / SpeedUp
        return 1 + x
    else
        return GroundFriction
    end
end

local function StartSlide()  -- Starting slide 
    Debounce = true
    Animation.Enabled = false
    Human.AutoRotate = false
    Controls:Disable()
    SlidesAnim:Play()   

    for _, v in pairs(HumanRootPart.Parent:GetDescendants()) do --Disable all colisions cuz roblox is bad engine 
        if (v:IsA("MeshPart") or v:IsA("Part")) and v ~= HumanRootPart then
            v.CanCollide = false
            v.Massless = true
        end
    end 
    Human:SetStateEnabled(Enum.HumanoidStateType.FallingDown, false) -- fixing stupid roblox inbuild colision detection and what happens after that
    Human:SetStateEnabled(Enum.HumanoidStateType.Ragdoll, false)
    --Human:SetStateEnabled(Enum.HumanoidStateType.Physics, false) 

end
local function EndSlide()  -- stopping slide (Like this should be self explanitory)
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
    while Stop == false do  -- main tick logic (i dont use heartbeat, because of fps change from device to device)
        Human.AutoRotate = false -- test delete after putting into input handler
        if MinSpeed < Speed and RayCastCheck(HumanRootPart.CFrame.LookVector * Vector3.new(1,0,1)) == nil then
            local RayCastResult = RayCastCheck(Vector3.new(0,-4,0))
            if RayCastResult ~= nil then

                local ForwardsVector = RayCastResult.Normal:Cross(HumanRootPart.CFrame.RightVector) -- vector math uuuu scaryyyyy (literaly name does it job)
                LinearVelocity.VectorVelocity = (Speed * ForwardsVector)

                if RayCastCheck(HumanRootPart.CFrame.UpVector * -3) ~= nil then -- when player is in a part be give some vector vel to get out of part (cuz other ways JUST DONT WORK )
                    LinearVelocity.VectorVelocity = LinearVelocity.VectorVelocity + HumanRootPart.CFrame.UpVector*3
                end

                RotationPart.CFrame = CFrame.lookAt(RotationPart.CFrame.Position, RotationPart.CFrame.Position + ForwardsVector) -- cframe math more scarry (we are rotating rotation part because it has aling posision which makes rotation smooooooth)

                if Speed <= MaxSpeed then -- speed limiter
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
    --Character.PrimaryPart.AssemblyLinearVelocity = HumanRootPart.CFrame.lookVector * Speed -- incase my client wants to return velocity to player
    EndSlide() 
end



UserInput.InputBegan:Connect(function(input) -- Getting Input and checking if its LeftControl
    if input.KeyCode == Enum.KeyCode.LeftControl and Debounce == false then
        while UserInput:IsKeyDown(Enum.KeyCode.LeftControl) do
            wait(0.00001)
            if RayCastCheck(Vector3.new(0,-6,0)) ~= nil then --Getting gad dawm vector for slide direction
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
    if input.KeyCode == Enum.KeyCode.LeftControl then -- player stopped holding ctrl
        EndSlide()
        Controls:Disable()
        Controls:Enable()
    end
end)

Human.Died:Connect(function() -- cuz player controls can/will glitch out when player died cuz roblox is garbage engine
    Controls:Disable()
    Controls:Enable()
end) -- should be enough, last time just didnt git push this code