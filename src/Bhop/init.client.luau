-- Wait for the player's character to load
repeat task.wait() until game.Players.LocalPlayer.Character

local MAX_SPEED = 20
local MAX_AIR_SPEED = 5
local MAX_ACCEL = 10 * MAX_SPEED
local GRAVITY = 100
local FRICTION = 2  -- Adjust this value to change friction intensity
local WALL_FRICTION = 8 -- Adjust this to control wall friction

local DEBUG = false

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()
local humanoid = character:WaitForChild("Humanoid")
local humanoidRootPart = character:WaitForChild("HumanoidRootPart")
local camera = workspace.CurrentCamera

--local anim = humanoid.Animator:LoadAnimation(script.Anim)

--local playerGui = player:WaitForChild("PlayerGui")
--local screenGui = playerGui:FindFirstChild("ScreenGui")
--local speedLabel = screenGui:FindFirstChild("TextLabel")

humanoid.JumpPower = 40
humanoid.UseJumpPower = true
humanoid.WalkSpeed = 1
humanoid.AutoRotate = false
humanoid.CameraOffset = Vector3.new(0, 0, 0)
player.CameraMinZoomDistance = 10
player.CameraMaxZoomDistance = 10

workspace.Gravity = GRAVITY

local attachment = Instance.new("Attachment")
attachment.Parent = humanoidRootPart
local alignOrientation = Instance.new("AlignOrientation")
alignOrientation.Mode = Enum.OrientationAlignmentMode.OneAttachment
alignOrientation.Attachment0 = attachment
alignOrientation.MaxTorque = 45e5
alignOrientation.Responsiveness = 150
alignOrientation.Parent = humanoidRootPart

local bodyVelocity = Instance.new("BodyVelocity")
bodyVelocity.MaxForce = Vector3.new(45e5, 0, 45e5)
bodyVelocity.Velocity = Vector3.new(0, 0, 0)
bodyVelocity.Parent = humanoidRootPart

-- Movement variables
local wishDir = Vector3.new(0, 0, 0)
local wallNormal = Vector3.new(0, 0, 0)

local keys = {
    a = 0,
    s = 0,
    d = 0,
    w = 0
}

function updateOrientation(position: Vector3, lookDir: Vector3)
    local targetOrientation = CFrame.lookAt(position, position + lookDir)
    local _, angleY, _ = targetOrientation:ToOrientation()

    alignOrientation.CFrame = CFrame.Angles(0, angleY, 0)
end

-- Function to get the surface friction of the part the player is standing on
local function getSurfaceFriction()
    local raycastParams = RaycastParams.new()
    raycastParams.FilterDescendantsInstances = {character} -- Exclude the character itself
    raycastParams.FilterType = Enum.RaycastFilterType.Exclude

    -- Raycast downwards to detect the part the player is standing on
    local raycastResult = workspace:Raycast(humanoidRootPart.Position, Vector3.new(0, -5, 0), raycastParams)

    if raycastResult and raycastResult.Instance then
        local part = raycastResult.Instance
        if part:IsA("BasePart") then
            return part:GetAttribute("SurfaceFriction") or FRICTION
        end
    end

    return FRICTION
end

-- Update friction application function to use the surface friction
local function applyFriction(velocity, dt)
    local surfaceFriction = getSurfaceFriction()
    local speed = velocity.Magnitude
    if speed > 0 then
        local drop = speed * surfaceFriction * dt
        local newSpeed = math.max(speed - drop, 0)
        return velocity.Unit * newSpeed
    end
    return velocity
end

-- Update velocity on the ground
local function updateVelGround(dt)
    local currentVelocity = bodyVelocity.Velocity
    currentVelocity = applyFriction(currentVelocity, dt)
    local projectedSpeed = currentVelocity:Dot(wishDir)
    local addSpeed = math.clamp(MAX_SPEED - projectedSpeed, 0, MAX_ACCEL * dt)

    return currentVelocity + addSpeed * wishDir
end
local AIR_CONTROL_FACTOR = 0.6  -- Adjust this to change air control responsiveness

local function updateVelAir(dt)
    local currentVelocity = bodyVelocity.Velocity
    local projectedSpeed = currentVelocity:Dot(wishDir)

    -- Adjust air control to give more responsiveness
    local airControlVelocity = wishDir * math.max((MAX_AIR_SPEED - projectedSpeed), 0) * AIR_CONTROL_FACTOR
    
    return currentVelocity + airControlVelocity
end

local t = os.clock()

-- Function to update speed display
local function updateSpeedDisplay()
    if os.clock() - t > 0.1 then
		speedLabel.Text =  math.floor(bodyVelocity.Velocity.Magnitude).."/s"
		speedLabel.TextLabel.Text = speedLabel.Text
		
        t = os.clock()
    end   
end

local function clampVelocity(velocity, maxSpeed)
    if velocity.Magnitude > maxSpeed then
        return velocity.Unit * maxSpeed
    end
    return velocity
end

local fps = false

-- Bind to the render step with a custom priority
RunService.Heartbeat:Connect(function(dt)
    UserInputService.MouseBehavior = Enum.MouseBehavior.LockCenter

    local horizontalInput, verticalInput

    if UserInputService:IsKeyDown(Enum.KeyCode.D) then
        horizontalInput = 1
    elseif UserInputService:IsKeyDown(Enum.KeyCode.A) then
        horizontalInput = -1
    else
        horizontalInput = 0
    end

    if UserInputService:IsKeyDown(Enum.KeyCode.W) then
        verticalInput = 1
    elseif UserInputService:IsKeyDown(Enum.KeyCode.S) then
        verticalInput = -1
    else
        verticalInput = 0
    end

    local x, z = horizontalInput, verticalInput

    local _, theta, _  = game.Workspace.CurrentCamera.CFrame:ToOrientation()

    verticalInput = x * -math.sin(theta) - z * math.cos(theta)
    horizontalInput = x * math.cos(theta) - z * math.sin(theta)

    wishDir = Vector3.new(horizontalInput, 0, verticalInput)

    -- Normalize wishDir, but only if it's not zero
    if wishDir.Magnitude > 0 then
        wishDir = wishDir.Unit
    end
       
    local newVelocity
    if humanoid:GetState() == Enum.HumanoidStateType.Freefall or (UserInputService:IsKeyDown(Enum.KeyCode.Space) and x ~= 0) or UserInputService:IsKeyDown(Enum.KeyCode.Space) then
        newVelocity = updateVelAir(dt)
    else
        newVelocity = updateVelGround(dt)
    end 
    
    if wishDir.Magnitude > 0 and not fps then
        alignOrientation.Enabled = true
        updateOrientation(humanoidRootPart.Position, camera.CFrame.LookVector)
    else
        alignOrientation.Enabled = false
    end
    
    -- if not fps then
    --     player.CameraMaxZoomDistance = 10
    --     player.CameraMinZoomDistance = 10
    -- else
    --     player.CameraMaxZoomDistance = 0
    --     player.CameraMinZoomDistance = 0
    -- end
   
    newVelocity = clampVelocity(newVelocity, 10000)
    bodyVelocity.Velocity = newVelocity

    --updateSpeedDisplay()
end)

UserInputService.InputEnded:Connect(function(input, processing)
    if processing then 
        return 
    end
    
    -- if input.KeyCode == Enum.KeyCode.V then
    --     fps = not fps
    --     humanoid.AutoRotate = fps
    -- end
end)

humanoid.Jumping:Connect(function(active)
    if active then
        --anim:Play()
    end
end)

humanoid.StateChanged:Connect(function(old, new)
    -- if new == Enum.HumanoidStateType.Landed then
    --     local sound = script:WaitForChild("Sound"..math.random(1,4)):Clone()
    --     sound.Parent = humanoidRootPart
    --     sound:Play()
    --     print(sound)
    --     sound.Played:Once(function()
    --         sound:Destroy()
    --     end)
    -- end
end)

workspace.Baseplate.Touched:Connect(function(part)
    -- if part:IsDescendantOf(player.Character) then
    --     player.Character:MoveTo(workspace:WaitForChild("SpawnLocation"..math.random(1, 6)).Position + Vector3.new(0, 3, 0))
    -- end
end)