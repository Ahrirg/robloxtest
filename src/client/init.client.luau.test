local FrictonDeltaModifier = 1
local DefaultFriction = 4
local RampsStepnessCriteria = 0.1
local MaxSpeed = 150
local MinSpeed = 15


-- THESE ARE DEBUG VALUES DONT USE THEM IN GAME \/  gg
local FrictionDB
--THESE ARE DEBUG VALUES DONT USE THEM IN GAME /\

local UserInput = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")

local Player = game.Players.LocalPlayer
local Character = Player.Character or Player.CharacterAdded:Wait()
local HumanRootPart = Character:WaitForChild("HumanoidRootPart")  --Self explanitory
local Human = Character:WaitForChild("Humanoid")
local Animation = Character:WaitForChild("Animate")

local animation = Character:WaitForChild("AnimSaves"):FindFirstChild("Slide")
local Slides = Human:LoadAnimation(animation)


local Debounce = false
local Stop = false
local HumanSpeed = 40

--Inital logic
local ListOfExecptions = {}
for _, v in pairs(HumanRootPart.Parent:GetDescendants()) do
    table.insert(ListOfExecptions, v)
end

local params = RaycastParams.new()
params.FilterDescendantsInstances = ListOfExecptions
params.FilterType = Enum.RaycastFilterType.Exclude
--Inital logic

local function SlidingSpeedMath(t, InitialForce, Friction)
    if Friction == nil then
        Friction = DefaultFriction
    end

    local f = math.exp(-FrictonDeltaModifier*Friction*t) * InitialForce

    if f > MaxSpeed then
        return MaxSpeed
    else
        return f
    end
end

local function RayCastCheck()
    local Origin = Vector3.new(HumanRootPart.Position.X, HumanRootPart.Position.Y, HumanRootPart.Position.Z)
    local Direction = Vector3.new(0,-6,0)

    return workspace:Raycast(Origin, Direction, params)
end


local function RampSlideFrictionCalculations(RecentYvectorMovement)
    if RecentYvectorMovement < -0.5 then
        RecentYvectorMovement = -0.5
    end
    --print(RecentYvectorMovement)
    if RecentYvectorMovement > RampsStepnessCriteria then --When you go Up a ramp
        --print("virsu")
        return 10

    elseif RecentYvectorMovement < -1*RampsStepnessCriteria then --When you go Down a ramp
        --print("apacia")
        return RecentYvectorMovement * 8

    else
        return 2  --When you go Don't go on a ramp
    end
end

local function Slide()
    HumanSpeed = Human.WalkSpeed


    Animation.Enabled = false
    Debounce = true
    Slides:Play()
    Slides.Looped = true
    HumanRootPart.Transparency = 0

    -- !!!!FOR SHOWCASE FIXX IS NEEDED!!!!
    for _, v in pairs(HumanRootPart.Parent:GetDescendants()) do
        if (v:IsA("MeshPart") or v:IsA("MeshPart")) and v ~= HumanRootPart then
            v.CanCollide = false
        end
    end 

    local Attachment = Instance.new("Attachment") --Creating attachment
    Attachment.Parent = HumanRootPart
    local VectorForce = Instance.new("VectorForce") --Creating VectorForce
    VectorForce.Parent = HumanRootPart
    VectorForce.Attachment0 = Attachment
    VectorForce.RelativeTo = "World"   
    -- !!!!FOR SHOWCASE FIXX IS NEEDED!!!!

    local LookVector = Workspace.CurrentCamera.CFrame.LookVector      --Make LookVector Camera
    --local LookVector = HumanRootPart.CFrame.LookVector              --Make LookVector Human looking pos
    LookVector = LookVector * Vector3.new(1,0,1)

    local t = 0
    Stop = false

    local InitialSpeedVector = Character.PrimaryPart.AssemblyLinearVelocity * Vector3.new(1,0,1)

    Human.WalkSpeed = 0
    
    local OldPos = HumanRootPart.CFrame.Position
    local MovingDownWords = false
    while Stop == false do
        t = t + 0.005

        local NewPOS = HumanRootPart.CFrame.Position
        local RecentMovementVector = (NewPOS - OldPos)
    
        local CharacterVelocity = LookVector * SlidingSpeedMath(t, InitialSpeedVector.Magnitude, RampSlideFrictionCalculations(RecentMovementVector.Y))

        local OldMovingDownWorlds = MovingDownWords
        if RecentMovementVector.Y < -1 then
            MovingDownWords = true
        else
            MovingDownWords = false
        end

        if OldMovingDownWorlds == true and MovingDownWords == false then
            print("We changed the speed")
            t = 0
            InitialSpeedVector = CharacterVelocity * 100
        end



        if RayCastCheck() ~= nil and CharacterVelocity.Magnitude > MinSpeed then
            VectorForce.Force = Vector3.new(0,-1,0)  * 50000    --Adding vector/force to VectorForce soo player would be stuck on a ramp !!!!FOR SHOWCASE FIXX IS NEEDED!!!!
            FrictionDB = RampSlideFrictionCalculations(RecentMovementVector.Y) -- !!!!FOR SHOWCASE FIXX IS NEEDED!!!!

            if RecentMovementVector.Y < -0.3 then
                Character.PrimaryPart.AssemblyLinearVelocity = CharacterVelocity + Vector3.new(0,RecentMovementVector.Y - 100, 0)
            else
                Character.PrimaryPart.AssemblyLinearVelocity = CharacterVelocity
            end

        else
            --print("Stopped")
            Character.PrimaryPart.AssemblyLinearVelocity = Vector3.new(0,0,0) -- Making Charracter stop after it's speed decreases
            Stop = true
        end
        wait(0.001)
        OldPos = NewPOS
    end

    Slides:Stop()

    -- !!!!FOR SHOWCASE FIXX IS NEEDED!!!!
    VectorForce.Parent = nil --Cleaning up
    Attachment.Parent = nil
    -- !!!!FOR SHOWCASE FIXX IS NEEDED!!!!
end

Animation.Enabled = false

local function EndSlide() 
    --Animation.Enabled = true   -- !!!!FOR SHOWCASE FIXX IS NEEDED!!!!
    Debounce = false
    Stop = true
    Human.WalkSpeed = HumanSpeed
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

while false do
    print("Speed: ", Character.PrimaryPart.AssemblyLinearVelocity.Magnitude, " Friction = ", FrictionDB)
    wait(0.2)
end